# Jalon 7 - Sauvegarde - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let an organizer export the entire local database as a single backup file (shareable via storage/Drive/WhatsApp) and re-import it later, restoring all events, beneficiaries, tickets, and presences. Closes cahier des charges section 5.

**Architecture:** A new `lib/features/backup/` feature does raw-file backup/restore of the Drift SQLite database (already the single source of truth for every table). `BackupRepository` is pure `dart:io` file I/O with zero dependency on Riverpod, `path_provider`, `share_plus`, or `file_picker`, so it is fully unit-testable with real temp files. A new `SettingsScreen` (deliberately generic, not `BackupScreen`, for future settings) hosts the export/import actions, reached from a new AppBar icon on the events list.

**Tech Stack:** Flutter 3.44.7 (FVM) + Riverpod + go_router + Drift + `share_plus` (native share sheet, already a dependency since jalon 1, first real use in this codebase) + `file_picker` (already used since jalon 3) + `path_provider` (already used since jalon 1, via `AppDatabase`). No new package for this jalon.

**Spec:** `docs/superpowers/specs/2026-08-30-jalon-7-sauvegarde-design.md`

## Global Constraints

- Every Flutter/Dart command is prefixed `fvm flutter` / `fvm dart`.
- Never hand-edit generated `.g.dart` or generated localization files.
- No em dashes in code, comments, or commit messages.
- No "Generated with Claude" / "Co-Authored-By: Claude" in commits.
- No file starts with a `// path/to/file.dart` first-line comment.
- No new dependency: `share_plus`, `file_picker`, `path_provider` are already available.
- `BackupRepository` never depends on Riverpod, `path_provider`, `share_plus`, or `file_picker`. It receives a `File` in its constructor and works only with `dart:io`, so it is testable with real temporary files with no platform-channel mock needed.
- `getApplicationDocumentsDirectory()` (`path_provider`) is not mockable in `flutter test` (the same reason `AppDatabase.forTesting` exists as a separate constructor from the normal `AppDatabase()`). No task in this plan writes a test that exercises `resolveDatabaseFile()` or `backupRepositoryProvider`'s real body directly; their correctness is covered by the full test suite continuing to pass (regression) plus the fact that `FileBackupRepository`'s own logic, which is what they wire together, is fully tested in isolation.
- `SettingsScreen` (Task 5) is never widget-tested past its initial render. Tapping its Export or Import buttons triggers `share_plus`/`file_picker` platform-channel calls with no mock in `flutter test`, the same reason `CsvImportScreen` (jalon 3) and `CheckInScanScreen` (jalon 6) have no test exercising their own native-triggering buttons. The one test this plan does write for `SettingsScreen` (Task 5) only pumps the widget and checks initial button state, it never taps Export or Import, so it never reaches those calls. The destructive-import confirmation flow is instead made fully testable by extracting it into a standalone function (Task 3), tested directly, independent of `file_picker`.

---

### Task 1: `AppDatabase.withExecutor` and a shared database file path resolver

**Context:** Small prerequisite touching the existing `lib/core/database/app_database.dart` (jalon 1) before the real backup work starts. The backup feature needs two things this file doesn't yet expose: (1) a way to open an `AppDatabase` against an arbitrary file, for validating and migrating an imported backup before it replaces the real one, without naming it `forTesting` from production code, and (2) the exact file path the app's own database lives at, to read/replace directly.

**Files:**
- Modify: `lib/core/database/app_database.dart`

**Interfaces:**
- Produces: `AppDatabase.withExecutor(QueryExecutor executor)`, a named constructor functionally identical to the existing `AppDatabase.forTesting`, and `Future<File> resolveDatabaseFile()`, a top-level function extracted from the existing `_openConnection()`. Task 2 depends on both.

- [ ] **Step 1: Make the change**

In `lib/core/database/app_database.dart`, add a new named constructor to `AppDatabase`, right after the existing `AppDatabase.forTesting(super.executor);` line:

```dart
  // ponytail: same body as forTesting, a separate name documents that this
  // constructor is also used in production (lib/features/backup), not only
  // in tests, so a reader isn't confused by production code calling
  // something named "forTesting".
  AppDatabase.withExecutor(super.executor);
```

Replace the existing `_openConnection()` function (and everything below it) with:

```dart
/// Resolves the on-disk path of the app's database file. Shared by the
/// normal app startup connection below and by the backup feature
/// (lib/features/backup), which needs the same path to export/import the
/// file directly.
Future<File> resolveDatabaseFile() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  return File(p.join(dbFolder.path, 'dif_pass.sqlite'));
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await resolveDatabaseFile();
    return NativeDatabase.createInBackground(file);
  });
}
```

No other file in `lib/core/database/app_database.dart` changes; this only extracts the existing path-resolution logic into a reusable function and adds one new constructor. No import changes needed, everything used (`File`, `getApplicationDocumentsDirectory`, `p.join`) is already imported in this file.

- [ ] **Step 2: Run the full suite as a regression check**

```bash
fvm flutter test
```

Expected: all existing tests still pass (this confirms the refactor changed no observable behavior: `AppDatabase()` still opens the same file the same way, `AppDatabase.forTesting` is untouched).

- [ ] **Step 3: Commit**

```bash
git add lib/core/database/app_database.dart
git commit -m "Add AppDatabase.withExecutor and extract the database file path resolver"
```

---

### Task 2: BackupRepository, FileBackupRepository, and its provider

**Files:**
- Create: `lib/features/backup/data/backup_repository.dart`
- Create: `lib/features/backup/data/file_backup_repository.dart`
- Create: `lib/features/backup/presentation/providers/backup_providers.dart`
- Test: `test/features/backup/data/file_backup_repository_test.dart`

**Interfaces:**
- Consumes: `AppDatabase.withExecutor`, `resolveDatabaseFile` (Task 1).
- Produces: `BackupRepository` (abstract) with `exportBackup() -> Future<Uint8List>` and `importBackup(Uint8List bytes) -> Future<void>`. `FileBackupRepository(File databaseFile) implements BackupRepository`. `backupRepositoryProvider` (`FutureProvider<BackupRepository>`). Tasks 5 depends on `backupRepositoryProvider`; Task 3 does not depend on this task.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/backup/data/file_backup_repository_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dif_pass/core/database/app_database.dart';
import 'package:dif_pass/features/backup/data/file_backup_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_test');
  });

  tearDown(() => tempDir.delete(recursive: true));

  test('exportBackup returns the exact bytes of the database file', () async {
    final sourceFile = File(p.join(tempDir.path, 'source.sqlite'));
    final content = utf8.encode('fake database content for this test');
    await sourceFile.writeAsBytes(content);
    final repository = FileBackupRepository(sourceFile);

    final bytes = await repository.exportBackup();

    expect(bytes, content);
  });

  test('importBackup replaces the target file when the backup is valid', () async {
    final sourceFile = File(p.join(tempDir.path, 'source.sqlite'));
    final sourceDb = AppDatabase.withExecutor(NativeDatabase(sourceFile));
    await sourceDb.into(sourceDb.events).insert(
          EventsCompanion.insert(
            shortCode: 'EVT1',
            name: 'Gala DIF 2026',
            date: DateTime(2026, 12, 1),
            presenceMode: 'simple',
          ),
        );
    await sourceDb.close();
    final backupBytes = await sourceFile.readAsBytes();

    final targetFile = File(p.join(tempDir.path, 'target.sqlite'));
    await targetFile.writeAsBytes(utf8.encode('not a real database'));
    final repository = FileBackupRepository(targetFile);

    await repository.importBackup(backupBytes);

    final importedDb = AppDatabase.withExecutor(NativeDatabase(targetFile));
    final events = await importedDb.select(importedDb.events).get();
    await importedDb.close();
    expect(events, hasLength(1));
    expect(events.single.name, 'Gala DIF 2026');
  });

  test('importBackup rejects an invalid file and leaves the target untouched', () async {
    final targetFile = File(p.join(tempDir.path, 'target.sqlite'));
    final originalBytes = utf8.encode('original database content');
    await targetFile.writeAsBytes(originalBytes);
    final repository = FileBackupRepository(targetFile);

    await expectLater(
      () => repository.importBackup(
        Uint8List.fromList(utf8.encode('not sqlite at all')),
      ),
      throwsA(isA<FormatException>()),
    );

    expect(await targetFile.readAsBytes(), originalBytes);
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/backup/data/file_backup_repository_test.dart
```

Expected: FAIL (`file_backup_repository.dart` does not exist).

- [ ] **Step 3: Implement the repository and its provider**

```dart
// lib/features/backup/data/backup_repository.dart
import 'dart:typed_data';

abstract class BackupRepository {
  Future<Uint8List> exportBackup();
  Future<void> importBackup(Uint8List bytes);
}
```

```dart
// lib/features/backup/data/file_backup_repository.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';

import '../../../core/database/app_database.dart';
import 'backup_repository.dart';

class FileBackupRepository implements BackupRepository {
  FileBackupRepository(this._databaseFile);

  final File _databaseFile;

  @override
  Future<Uint8List> exportBackup() => _databaseFile.readAsBytes();

  @override
  Future<void> importBackup(Uint8List bytes) async {
    final tempFile = File('${_databaseFile.path}.import-tmp');
    await tempFile.writeAsBytes(bytes, flush: true);

    final db = AppDatabase.withExecutor(NativeDatabase(tempFile));
    try {
      await db.select(db.events).get();
    } catch (e) {
      await db.close();
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      throw const FormatException('Not a valid DIF Pass backup file');
    }
    await db.close();

    await tempFile.rename(_databaseFile.path);
  }
}
```

```dart
// lib/features/backup/presentation/providers/backup_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/backup_repository.dart';
import '../../data/file_backup_repository.dart';

final backupRepositoryProvider = FutureProvider<BackupRepository>((ref) async {
  final file = await resolveDatabaseFile();
  return FileBackupRepository(file);
});
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/backup/data/file_backup_repository_test.dart
```

Expected: PASS (all 3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/backup/data lib/features/backup/presentation/providers test/features/backup/data
git commit -m "Add BackupRepository, its file implementation, and provider"
```

---

### Task 3: Import confirmation dialog

**Context:** The destructive-import confirmation is extracted into a standalone function so it is testable independent of `file_picker` (which the real Import button will call before ever showing this dialog, and which has no mock in `flutter test`). This mirrors the same "extract the testable piece away from the untestable trigger" pattern used for `CheckInManualEntryField` in jalon 6.

**Files:**
- Create: `lib/features/backup/presentation/widgets/import_confirm_dialog.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/backup/presentation/widgets/import_confirm_dialog_test.dart`

**Interfaces:**
- Produces: `Future<bool> showImportConfirmDialog(BuildContext context)`. Task 5 depends on this.

- [ ] **Step 1: Add the ARB keys this dialog needs**

```json
// lib/l10n/app_en.arb (add these keys, keep the existing ones)
{
  "settingsImportAction": "Import backup",
  "settingsImportConfirmTitle": "Import this backup?",
  "settingsImportConfirmBody": "This will replace all current data. This action cannot be undone."
}
```

```json
// lib/l10n/app_fr.arb (add these keys, keep the existing ones)
{
  "settingsImportAction": "Importer une sauvegarde",
  "settingsImportConfirmTitle": "Importer cette sauvegarde ?",
  "settingsImportConfirmBody": "Cette action remplacera toutes les donnees actuelles. Cette action est irreversible."
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

```dart
// test/features/backup/presentation/widgets/import_confirm_dialog_test.dart
import 'package:dif_pass/features/backup/presentation/widgets/import_confirm_dialog.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(bool? Function() readResult, Future<void> Function(BuildContext) onPressed) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => FilledButton(
          onPressed: () => onPressed(context),
          child: const Text('trigger'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('returns false and dismisses the dialog when cancelled', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _wrap(() => result, (context) async {
        result = await showImportConfirmDialog(context);
      }),
    );

    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('returns true when confirmed', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _wrap(() => result, (context) async {
        result = await showImportConfirmDialog(context);
      }),
    );

    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/backup/presentation/widgets/import_confirm_dialog_test.dart
```

Expected: FAIL (`import_confirm_dialog.dart` does not exist).

- [ ] **Step 4: Implement the dialog**

```dart
// lib/features/backup/presentation/widgets/import_confirm_dialog.dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

Future<bool> showImportConfirmDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.settingsImportConfirmTitle),
      content: Text(l10n.settingsImportConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.settingsImportAction),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
```

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/backup/presentation/widgets/import_confirm_dialog_test.dart
```

Expected: PASS (both tests).

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/backup/presentation/widgets test/features/backup/presentation/widgets
git commit -m "Add the import confirmation dialog"
```

---

### Task 4: Settings entry point on the events list

**Files:**
- Modify: `lib/features/events/presentation/screens/events_list_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/events/presentation/screens/events_list_screen_test.dart`

**Interfaces:**
- Produces: `EventsListScreen`'s AppBar gains a Settings `IconButton`, pushing `/settings` (the route itself doesn't exist yet, that's Task 6, this task just adds the navigation call).

- [ ] **Step 1: Add the ARB key this change needs**

```json
// lib/l10n/app_en.arb (add this key, keep the existing ones)
{
  "settingsAction": "Settings"
}
```

```json
// lib/l10n/app_fr.arb (add this key, keep the existing ones)
{
  "settingsAction": "Reglages"
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

Append to the existing test file, inside `main()`:

```dart
// test/features/events/presentation/screens/events_list_screen_test.dart (append inside main())
testWidgets('shows a settings action', (tester) async {
  await tester.pumpWidget(
    _wrap(const EventsListScreen(), FakeEventRepository()),
  );
  await tester.pumpAndSettle();

  expect(find.byTooltip('Settings'), findsOneWidget);
});
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/events/presentation/screens/events_list_screen_test.dart
```

Expected: FAIL (no widget with tooltip "Settings" exists yet).

- [ ] **Step 4: Add the button**

In `lib/features/events/presentation/screens/events_list_screen.dart`, change the `AppBar`'s `actions` list to:

```dart
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: l10n.eventsArchiveAction,
            onPressed: () => context.push('/events/archives'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsAction,
            onPressed: () => context.push('/settings'),
          ),
        ],
```

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/events/presentation/screens/events_list_screen_test.dart
```

Expected: PASS (all tests in the file).

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/events/presentation/screens/events_list_screen.dart test/features/events/presentation/screens/events_list_screen_test.dart
git commit -m "Add a settings entry point to the events list"
```

---

### Task 5: SettingsScreen

**Context:** Composes everything from Tasks 2-3 into the actual export/import screen. Per the Global Constraints, only the initial render is tested; tapping Export or Import triggers `share_plus`/`file_picker` platform calls this project's convention deliberately does not exercise in `flutter test`.

**Files:**
- Create: `lib/features/backup/presentation/screens/settings_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/backup/presentation/screens/settings_screen_test.dart`

**Interfaces:**
- Consumes: `backupRepositoryProvider` (Task 2); `showImportConfirmDialog` (Task 3); `appDatabaseProvider` (jalon 1, `lib/core/database/database_provider.dart`).
- Produces: `SettingsScreen`, the widget Task 6 wires to route `/settings`.

- [ ] **Step 1: Add the ARB keys this screen needs**

```json
// lib/l10n/app_en.arb (add these keys, keep the existing ones)
{
  "settingsScreenTitle": "Settings",
  "settingsExportAction": "Export backup",
  "settingsExportError": "Could not export the backup.",
  "settingsImportError": "Could not import this file. Make sure it is a valid DIF Pass backup."
}
```

```json
// lib/l10n/app_fr.arb (add these keys, keep the existing ones)
{
  "settingsScreenTitle": "Reglages",
  "settingsExportAction": "Exporter la sauvegarde",
  "settingsExportError": "Impossible d'exporter la sauvegarde.",
  "settingsImportError": "Impossible d'importer ce fichier. Verifiez qu'il s'agit bien d'une sauvegarde DIF Pass valide."
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

```dart
// test/features/backup/presentation/screens/settings_screen_test.dart
import 'package:dif_pass/features/backup/presentation/screens/settings_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the export and import actions, both enabled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Import backup'), findsOneWidget);
    final exportButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(exportButton.onPressed, isNotNull);
    final importButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(importButton.onPressed, isNotNull);
  });
}
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/backup/presentation/screens/settings_screen_test.dart
```

Expected: FAIL (`settings_screen.dart` does not exist).

- [ ] **Step 4: Implement the screen**

```dart
// lib/features/backup/presentation/screens/settings_screen.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/backup_providers.dart';
import '../widgets/import_confirm_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final repository = await ref.read(backupRepositoryProvider.future);
      final bytes = await repository.exportBackup();
      final tempDir = await getTemporaryDirectory();
      final dateLabel = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final exportFile = File(
        p.join(tempDir.path, 'dif-pass-sauvegarde-$dateLabel.sqlite'),
      );
      await exportFile.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(exportFile.path)]),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsExportError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['sqlite', 'db'],
    );
    if (file == null) return;
    if (!mounted) return;

    final confirmed = await showImportConfirmDialog(context);
    if (!confirmed) return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await file.readAsBytes();
      final repository = await ref.read(backupRepositoryProvider.future);
      await ref.read(appDatabaseProvider).close();
      await repository.importBackup(bytes);
      ref.invalidate(appDatabaseProvider);
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsImportError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.upload_outlined),
              label: Text(l10n.settingsExportAction),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.download_outlined),
              label: Text(l10n.settingsImportAction),
            ),
          ],
        ),
      ),
    );
  }
}
```

Note on the close/import/invalidate sequence in `_import`: `ref.read(appDatabaseProvider).close()` closes the live Drift connection before `repository.importBackup(bytes)` replaces the file on disk (required so the file can be safely replaced), then `ref.invalidate(appDatabaseProvider)` makes the next read of that provider open a fresh connection against the now-replaced file, and `context.go('/')` clears the navigation stack so no screen is left showing an event, beneficiary, or ticket id that may no longer exist in the restored data.

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/backup/presentation/screens/settings_screen_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/backup/presentation/screens test/features/backup/presentation/screens
git commit -m "Add the settings screen with backup export and import"
```

---

### Task 6: Wire the settings route, full milestone check

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Test: `test/core/router/app_router_test.dart`

**Interfaces:**
- Consumes: `SettingsScreen` (Task 5).
- Produces: `appRouter` gains 1 route. This is the last task of the milestone.

- [ ] **Step 1: Write the failing test**

Append to the existing test file, inside `main()`:

```dart
// test/core/router/app_router_test.dart (append inside main())
testWidgets('app router shows the settings screen at /settings', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [eventRepositoryProvider.overrideWithValue(FakeEventRepository())],
      child: MaterialApp.router(
        routerConfig: appRouter,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();

  appRouter.go('/settings');
  await tester.pumpAndSettle();

  expect(find.text('Export backup'), findsOneWidget);
  expect(find.text('Import backup'), findsOneWidget);
});
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/core/router/app_router_test.dart
```

Expected: FAIL (route `/settings` does not exist).

- [ ] **Step 3: Wire the route**

```dart
// lib/core/router/app_router.dart
// Add this import alongside the existing feature imports:
import '../../features/backup/presentation/screens/settings_screen.dart';
```

```dart
// lib/core/router/app_router.dart
// Add this route to the `routes:` list, alongside the existing routes:
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/core/router/app_router_test.dart
```

Expected: PASS (all tests in the file).

- [ ] **Step 5: Run the full suite and analyzer as a milestone-wide check**

```bash
fvm flutter test
fvm flutter analyze
```

Expected: all tests pass, analyzer reports no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/core/router test/core/router
git commit -m "Wire the settings route"
```

---

## Milestone acceptance

Jalon 7 (Sauvegarde) is done when, from a clean checkout on this branch:

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test
fvm flutter analyze
```

all succeed, and from the events list an organizer can open Settings, export the entire local database as a single file through the native share sheet, and later pick that file back through Import (behind an explicit "this replaces everything" confirmation) to restore every event, beneficiary, ticket, and presence exactly as they were, with a corrupted or unrelated file being rejected without touching the current data.
