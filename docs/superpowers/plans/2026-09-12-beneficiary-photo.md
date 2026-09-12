# Beneficiary Photo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let an organiser attach an optional photo to a beneficiary, for visual identification on the form, the beneficiaries list, all three ticket templates (screen and PDF), and the check-in scan confirmation.

**Architecture:** One new nullable `Beneficiaries.photo` column (schema v3 -> v4), threaded through the domain/repository layer exactly like `Events.logo` already is, then displayed at four places that already have the beneficiary object in hand - no new provider, no new repository method beyond the existing create/update/import paths.

**Tech Stack:** Flutter/Dart, Drift, `image_picker` (already a dependency), `pdf` package, Riverpod, existing ARB/`AppLocalizations` i18n.

**Spec:** [docs/superpowers/specs/2026-09-12-beneficiary-photo-design.md](../specs/2026-09-12-beneficiary-photo-design.md)

## Global Constraints

- All Flutter/Dart tooling runs through FVM: `fvm flutter ...`, `fvm dart ...`.
- The photo is optional everywhere: creating, editing, or importing a beneficiary never requires one.
- No CSV import/export of photos - imported beneficiaries always have `photo == null`, which already falls out of `NewBeneficiary.photo` defaulting to `null` and CSV-built `NewBeneficiary` values never setting it.
- French ARB copy has no accents.
- Commit messages: no `Co-Authored-By: Claude` trailer, no "Generated with Claude" line, no em dashes anywhere.
- All existing tests must still pass at the end of every task.

---

### Task 1: Schema, domain, and repository layer

**Files:**
- Modify: `lib/core/database/tables/beneficiaries_table.dart`
- Modify: `lib/core/database/app_database.dart`
- Modify: `lib/features/beneficiaries/domain/beneficiary.dart`
- Modify: `lib/features/beneficiaries/domain/new_beneficiary.dart`
- Modify: `lib/features/beneficiaries/data/drift_beneficiary_repository.dart`
- Modify: `test/features/beneficiaries/fake_beneficiary_repository.dart`
- Modify: `ios/Runner/Info.plist`
- Test: `test/features/beneficiaries/data/drift_beneficiary_repository_test.dart`
- Test: `test/core/database/app_database_migration_test.dart`

**Interfaces:**
- Consumes: nothing from other tasks (this is the data-layer task).
- Produces: `Beneficiary.photo` (`Uint8List?`), `NewBeneficiary.photo` (`Uint8List?`, optional, default `null`) - both later tasks read/write these two fields and nothing else from this task.

- [ ] **Step 1: Write the failing repository tests**

Read `test/features/beneficiaries/data/drift_beneficiary_repository_test.dart` in full first. Add:

```dart
  test('createBeneficiary stores and round-trips a photo', () async {
    final photo = Uint8List.fromList([1, 2, 3, 4]);
    final id = await repository.createBeneficiary(
      eventId,
      NewBeneficiary(name: 'Jane Doe', customFieldValues: const {}, photo: photo),
    );

    final beneficiary = await repository.getBeneficiary(id);
    expect(beneficiary.photo, photo);
  });

  test('createBeneficiary leaves photo null when none is given', () async {
    final id = await repository.createBeneficiary(
      eventId,
      const NewBeneficiary(name: 'Jane Doe', customFieldValues: {}),
    );

    final beneficiary = await repository.getBeneficiary(id);
    expect(beneficiary.photo, isNull);
  });

  test('updateBeneficiary replaces the photo', () async {
    final id = await repository.createBeneficiary(
      eventId,
      NewBeneficiary(
        name: 'Jane Doe',
        customFieldValues: const {},
        photo: Uint8List.fromList([1, 2, 3]),
      ),
    );

    final newPhoto = Uint8List.fromList([9, 9, 9]);
    await repository.updateBeneficiary(
      id,
      NewBeneficiary(name: 'Jane Doe', customFieldValues: const {}, photo: newPhoto),
    );

    final beneficiary = await repository.getBeneficiary(id);
    expect(beneficiary.photo, newPhoto);
  });

  test('importBeneficiaries never sets a photo', () async {
    await repository.importBeneficiaries(eventId, const [
      NewBeneficiary(name: 'Jane Doe', customFieldValues: {}),
    ]);

    final beneficiaries = await repository.watchBeneficiaries(eventId).first;
    expect(beneficiaries.single.photo, isNull);
  });
```

Add `import 'dart:typed_data';` at the top of the test file if not already present (check first - `NewBeneficiary`/`Beneficiary` imports are already there).

- [ ] **Step 2: Run the tests to verify they fail**

Run: `fvm flutter test test/features/beneficiaries/data/drift_beneficiary_repository_test.dart`
Expected: FAIL to compile - `NewBeneficiary`/`Beneficiary` have no `photo` parameter yet.

- [ ] **Step 3: Add the column to the table**

Edit `lib/core/database/tables/beneficiaries_table.dart`, adding one line right after `createdAt` (before the existing `syncId` block and its comment):

```dart
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BlobColumn get photo => blob().nullable()();
```

Nothing else in this file changes.

- [ ] **Step 4: Bump the schema version and add the migration**

Edit `lib/core/database/app_database.dart`:

```dart
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(events, events.ticketTemplate);
      }
      if (from < 3) {
        await _addSyncIds(m);
      }
      if (from < 4) {
        await m.addColumn(beneficiaries, beneficiaries.photo);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
```

(`_addSyncIds` and everything else in this file is unchanged - only `schemaVersion` and the `onUpgrade` body change.)

- [ ] **Step 5: Update the domain classes**

Edit `lib/features/beneficiaries/domain/beneficiary.dart`:

```dart
import 'dart:typed_data';

class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.eventId,
    required this.name,
    required this.customFieldValues,
    required this.createdAt,
    this.syncId,
    this.photo,
  });

  final int id;
  final int eventId;
  final String name;
  final Map<int, String> customFieldValues;
  final DateTime createdAt;

  // Stable cross-device id, see check_in.dart
  final String? syncId;

  // Optional identification photo, shown on the form, the list, the ticket,
  // and the check-in confirmation. Never required.
  final Uint8List? photo;
}
```

Edit `lib/features/beneficiaries/domain/new_beneficiary.dart`:

```dart
import 'dart:typed_data';

class NewBeneficiary {
  const NewBeneficiary({
    required this.name,
    required this.customFieldValues,
    this.photo,
  });

  final String name;
  final Map<int, String> customFieldValues;
  final Uint8List? photo;
}
```

- [ ] **Step 6: Thread `photo` through the Drift repository**

Edit `lib/features/beneficiaries/data/drift_beneficiary_repository.dart`. In `createBeneficiary`:

```dart
  @override
  Future<int> createBeneficiary(int eventId, NewBeneficiary beneficiary) {
    return _db.transaction(() async {
      final id = await _db.into(_db.beneficiaries).insert(
            BeneficiariesCompanion.insert(
              eventId: eventId,
              name: beneficiary.name,
              photo: Value(beneficiary.photo),
            ),
          );
      await _insertValues(id, beneficiary.customFieldValues);
      return id;
    });
  }
```

In `updateBeneficiary`:

```dart
  @override
  Future<void> updateBeneficiary(int id, NewBeneficiary beneficiary) {
    return _db.transaction(() async {
      await (_db.update(_db.beneficiaries)..where((tbl) => tbl.id.equals(id)))
          .write(BeneficiariesCompanion(
            name: Value(beneficiary.name),
            photo: Value(beneficiary.photo),
          ));
      await (_db.delete(_db.beneficiaryValues)
            ..where((tbl) => tbl.beneficiaryId.equals(id)))
          .go();
      await _insertValues(id, beneficiary.customFieldValues);
    });
  }
```

In `importBeneficiaries`, the loop's insert (no special-casing needed - `beneficiary.photo` is already `null` for every CSV-built `NewBeneficiary`):

```dart
      for (final beneficiary in beneficiaries) {
        final id = await _db.into(_db.beneficiaries).insert(
              BeneficiariesCompanion.insert(
                eventId: eventId,
                name: beneficiary.name,
                photo: Value(beneficiary.photo),
              ),
            );
        await _insertValues(id, beneficiary.customFieldValues);
        count++;
      }
```

In `_groupRows`, add `photo: b.photo,` to the `Beneficiary(...)` construction:

```dart
    final result = beneficiaryRows.values
        .map((b) => Beneficiary(
              id: b.id,
              eventId: b.eventId,
              name: b.name,
              customFieldValues: Map.unmodifiable(values[b.id] ?? const {}),
              createdAt: b.createdAt,
              syncId: b.syncId,
              photo: b.photo,
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
```

- [ ] **Step 7: Regenerate the Drift code**

Run: `fvm dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/core/database/app_database.g.dart` changes to add the `photo` column/companion field. Never hand-edit this file.

- [ ] **Step 8: Run the repository tests to verify they pass**

Run: `fvm flutter test test/features/beneficiaries/data/drift_beneficiary_repository_test.dart`
Expected: PASS.

- [ ] **Step 9: Update `FakeBeneficiaryRepository`**

Read `test/features/beneficiaries/fake_beneficiary_repository.dart` in full first. In `createBeneficiary`, `updateBeneficiary`, and `importBeneficiaries`, add `photo: beneficiary.photo` to each `Beneficiary(...)` construction (three call sites), mirroring exactly how `customFieldValues` is already carried through in each.

- [ ] **Step 10: Write the failing migration test**

Read `test/core/database/app_database_migration_test.dart` in full first (it already has a v1 and a v2 fixture, both building all six tables with raw `sqlite3`). Add a third test building a **v3** fixture - the v2 shape plus `sync_id TEXT` on the five sync-tracked tables and their unique indexes, still no `photo` column:

```dart
  test('opening a v3 database adds a photo column that reads null on '
      'existing beneficiaries', () async {
    final dir = await Directory.systemTemp.createTemp('dif_pass_migration_v3');
    final file = File(p.join(dir.path, 'legacy_v3.sqlite'));
    addTearDown(() => dir.delete(recursive: true));

    final legacyDb = sqlite3.sqlite3.open(file.path);
    legacyDb.execute('''
      CREATE TABLE events (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        short_code TEXT NOT NULL,
        name TEXT NOT NULL,
        date INTEGER NOT NULL,
        location TEXT NULL,
        logo BLOB NULL,
        presence_mode TEXT NOT NULL,
        ticket_template TEXT NOT NULL DEFAULT 'standard',
        archived_at INTEGER NULL,
        created_at INTEGER NOT NULL,
        sync_id TEXT NULL
      );
    ''');
    legacyDb.execute('''
      CREATE TABLE custom_fields (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL REFERENCES events (id) ON DELETE CASCADE,
        label TEXT NOT NULL,
        field_type TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        show_on_ticket INTEGER NOT NULL DEFAULT 0,
        sync_id TEXT NULL
      );
    ''');
    legacyDb.execute('''
      CREATE TABLE beneficiaries (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL REFERENCES events (id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        sync_id TEXT NULL
      );
    ''');
    legacyDb.execute('''
      CREATE TABLE beneficiary_values (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        beneficiary_id INTEGER NOT NULL REFERENCES beneficiaries (id) ON DELETE CASCADE,
        custom_field_id INTEGER NOT NULL REFERENCES custom_fields (id) ON DELETE CASCADE,
        value TEXT NOT NULL
      );
    ''');
    legacyDb.execute('''
      CREATE TABLE tickets (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        beneficiary_id INTEGER NOT NULL REFERENCES beneficiaries (id) ON DELETE CASCADE,
        event_id INTEGER NOT NULL REFERENCES events (id) ON DELETE CASCADE,
        readable_id TEXT NOT NULL,
        random_part TEXT NOT NULL,
        qr_payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        sync_id TEXT NULL,
        UNIQUE (event_id, readable_id)
      );
    ''');
    legacyDb.execute('''
      CREATE TABLE check_ins (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        ticket_id INTEGER NOT NULL REFERENCES tickets (id) ON DELETE CASCADE,
        event_id INTEGER NOT NULL REFERENCES events (id) ON DELETE CASCADE,
        scanned_at INTEGER NOT NULL,
        sync_id TEXT NULL
      );
    ''');
    for (final entry in {
      'idx_events_sync_id': 'events',
      'idx_custom_fields_sync_id': 'custom_fields',
      'idx_beneficiaries_sync_id': 'beneficiaries',
      'idx_tickets_sync_id': 'tickets',
      'idx_check_ins_sync_id': 'check_ins',
    }.entries) {
      legacyDb.execute(
        'CREATE UNIQUE INDEX ${entry.key} ON ${entry.value} (sync_id)',
      );
    }
    legacyDb.execute(
      "INSERT INTO events (short_code, name, date, presence_mode, created_at, sync_id) "
      "VALUES ('EVT1', 'A', 0, 'simple', 0, 'e1')",
    );
    legacyDb.execute(
      "INSERT INTO beneficiaries (event_id, name, created_at, sync_id) "
      "VALUES (1, 'Ama', 0, 'b1')",
    );
    legacyDb.userVersion = 3;
    legacyDb.close();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final beneficiaries = await db.select(db.beneficiaries).get();
    expect(beneficiaries, hasLength(1));
    expect(beneficiaries.single.name, 'Ama');
    expect(beneficiaries.single.photo, isNull);
  });
```

- [ ] **Step 11: Run the migration tests to verify they pass**

Run: `fvm flutter test test/core/database/app_database_migration_test.dart`
Expected: PASS (all three cases: v1, v2, v3).

- [ ] **Step 12: Add the iOS camera usage description**

Edit `ios/Runner/Info.plist`. Right after the existing `NSPhotoLibraryUsageDescription` entry, add:

```xml
	<key>NSCameraUsageDescription</key>
	<string>DIF Pass needs access to your camera to let you take a beneficiary photo.</string>
```

No test covers this (platform config, not exercised by `flutter test`); it only matters when the app actually runs on iOS.

- [ ] **Step 13: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no new analyzer output.

- [ ] **Step 14: Commit**

```bash
git add lib/core/database lib/features/beneficiaries/domain lib/features/beneficiaries/data test/features/beneficiaries test/core/database ios/Runner/Info.plist
git commit -m "Add an optional photo column to beneficiaries"
```

---

### Task 2: Beneficiary form - capture, preview, and save

**Files:**
- Modify: `lib/features/beneficiaries/presentation/screens/beneficiary_form_screen.dart`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/features/beneficiaries/presentation/screens/beneficiary_form_screen_test.dart`

**Interfaces:**
- Consumes from Task 1: `Beneficiary.photo`, `NewBeneficiary.photo`.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add the ARB keys**

Add to `lib/l10n/app_fr.arb` (no accents), near `beneficiaryFormFieldNumberInvalid` or another `beneficiaryForm*` key:

```json
  "beneficiaryFormPhotoAction": "Ajouter une photo",
  "beneficiaryFormPhotoSourceCameraAction": "Prendre une photo",
  "beneficiaryFormPhotoSourceGalleryAction": "Choisir dans la galerie",
```

Add the matching English keys to `lib/l10n/app_en.arb`:

```json
  "beneficiaryFormPhotoAction": "Add a photo",
  "beneficiaryFormPhotoSourceCameraAction": "Take a photo",
  "beneficiaryFormPhotoSourceGalleryAction": "Choose from gallery",
```

- [ ] **Step 2: Regenerate localizations**

Run: `fvm flutter gen-l10n`

- [ ] **Step 3: Write the failing widget test**

Read `test/features/beneficiaries/presentation/screens/beneficiary_form_screen_test.dart` in full first (its `_wrap` helper and how it constructs `FakeBeneficiaryRepository`/`FakeEventRepository`). `ImagePicker`'s platform call is not mockable in `flutter test` (same established convention as `event_form_screen.dart`'s `_pickLogo` - untested at that exact boundary), so this task's test covers the load-and-preserve path instead of the picker itself:

```dart
  testWidgets(
    'editing a beneficiary with a photo shows it and preserves it on save',
    (tester) async {
      final photo = Uint8List.fromList([1, 2, 3, 4]);
      final fakeBeneficiaries = FakeBeneficiaryRepository(
        beneficiaries: [
          Beneficiary(
            id: 1,
            eventId: 1,
            name: 'Jane Doe',
            customFieldValues: const {},
            createdAt: DateTime(2026, 1, 1),
            photo: photo,
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const BeneficiaryFormScreen(eventId: 1, beneficiaryId: 1),
          fakeBeneficiaries,
          _fakeEventsWithOneEvent(), // or whatever this file's existing helper is named - read first
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsOneWidget);

      await tester.tap(find.text('Save')); // match the exact save-button label this file's other tests already use
      await tester.pumpAndSettle();

      expect(fakeBeneficiaries.beneficiaries.single.photo, photo);
    },
  );
```

Match this file's real helper names, imports, and save-button label exactly - the snippet above is illustrative of the assertions, not a literal drop-in. Add `import 'dart:typed_data';` if not already present.

- [ ] **Step 4: Run the test to verify it fails**

Run: `fvm flutter test test/features/beneficiaries/presentation/screens/beneficiary_form_screen_test.dart`
Expected: FAIL - no `CircleAvatar` exists yet on this screen.

- [ ] **Step 5: Implement the photo field**

Edit `lib/features/beneficiaries/presentation/screens/beneficiary_form_screen.dart`. Add imports:

```dart
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
```

Add a field to `_BeneficiaryFormScreenState`:

```dart
  Uint8List? _photo;
```

In `_loadExistingBeneficiary`'s `setState`, add:

```dart
        _photo = beneficiary.photo;
```

Add a new method, placed after `_controllerFor`:

```dart
  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.beneficiaryFormPhotoSourceCameraAction),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.beneficiaryFormPhotoSourceGalleryAction),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _photo = bytes);
  }
```

In `_save`, add `photo: _photo` to the `NewBeneficiary(...)` construction:

```dart
    final newBeneficiary = NewBeneficiary(
      name: _nameController.text.trim(),
      customFieldValues: values,
      photo: _photo,
    );
```

In `build()`, add this block right after the name `TextFormField` and its `SizedBox`, before the custom-fields loop:

```dart
              Row(
                children: [
                  if (_photo != null) ...[
                    CircleAvatar(backgroundImage: MemoryImage(_photo!), radius: 24),
                    const SizedBox(width: 12),
                  ],
                  TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(l10n.beneficiaryFormPhotoAction),
                  ),
                ],
              ),
              const SizedBox(height: 16),
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `fvm flutter test test/features/beneficiaries/presentation/screens/beneficiary_form_screen_test.dart`
Expected: PASS.

- [ ] **Step 7: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no new analyzer output.

- [ ] **Step 8: Commit**

```bash
git add lib/features/beneficiaries/presentation/screens/beneficiary_form_screen.dart lib/l10n test/features/beneficiaries/presentation/screens/beneficiary_form_screen_test.dart
git commit -m "Add photo capture to the beneficiary form"
```

---

### Task 3: Beneficiaries list thumbnail

**Files:**
- Modify: `lib/features/beneficiaries/presentation/widgets/beneficiary_list_tile.dart`
- Test: `test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart`

**Interfaces:**
- Consumes from Task 1: `Beneficiary.photo`.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write the failing tests**

Read `test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart` in full first. Add:

```dart
  testWidgets('shows the beneficiary photo when set', (tester) async {
    final fake = FakeBeneficiaryRepository(
      beneficiaries: [
        Beneficiary(
          id: 1,
          eventId: 1,
          name: 'Jane Doe',
          customFieldValues: const {},
          createdAt: DateTime(2026, 1, 1),
          photo: Uint8List.fromList([1, 2, 3, 4]),
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        const BeneficiariesListScreen(eventId: 1),
        fake,
        _fakeEventsWithOneEvent(),
      ),
    );
    await tester.pumpAndSettle();

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundImage, isNotNull);
  });

  testWidgets('shows a placeholder icon when no photo is set', (tester) async {
    final fake = FakeBeneficiaryRepository(
      beneficiaries: [
        Beneficiary(
          id: 1,
          eventId: 1,
          name: 'Jane Doe',
          customFieldValues: const {},
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        const BeneficiariesListScreen(eventId: 1),
        fake,
        _fakeEventsWithOneEvent(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });
```

Match this file's real `_wrap`/helper argument order and imports exactly (read first). Add `import 'dart:typed_data';` if not already present.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `fvm flutter test test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart`
Expected: FAIL - no `CircleAvatar`/`Icons.person_outline` on this screen yet.

- [ ] **Step 3: Add the leading avatar**

Edit `lib/features/beneficiaries/presentation/widgets/beneficiary_list_tile.dart`. Add the import:

```dart
import '../../../../core/theme/app_colors.dart';
```

Add `leading:` to the `ListTile`:

```dart
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
          backgroundImage:
              beneficiary.photo != null ? MemoryImage(beneficiary.photo!) : null,
          child: beneficiary.photo == null
              ? const Icon(Icons.person_outline, color: AppColors.indigo)
              : null,
        ),
        title: Text(
          beneficiary.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: preview.isEmpty ? null : Text(preview),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: l10n.commonDelete,
          onPressed: onDelete,
        ),
      ),
    );
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `fvm flutter test test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no new analyzer output.

- [ ] **Step 6: Commit**

```bash
git add lib/features/beneficiaries/presentation/widgets/beneficiary_list_tile.dart test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart
git commit -m "Show the beneficiary photo (or a placeholder) in the beneficiaries list"
```

---

### Task 4: Ticket rendering - screen and PDF

**Files:**
- Modify: `lib/features/tickets/presentation/screens/ticket_preview_screen.dart`
- Modify: `lib/features/tickets/data/ticket_pdf_builder.dart`
- Test: `test/features/tickets/presentation/screens/ticket_preview_screen_test.dart`
- Test: `test/features/tickets/data/ticket_pdf_builder_test.dart`

**Interfaces:**
- Consumes from Task 1: `Beneficiary.photo`.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write the failing screen test**

Read `test/features/tickets/presentation/screens/ticket_preview_screen_test.dart` in full first - it already defines `_testLogoBytes`, a valid 1x1 PNG, for exactly this reason (`Image.memory`/`MemoryImage` need decodable bytes in a widget test). Reuse `_testLogoBytes` for the beneficiary's photo too - the test only needs *a* valid image, not a specific one. Add:

```dart
  testWidgets('shows a photo medallion when the beneficiary has one', (tester) async {
    final fakeEvents = FakeEventRepository(
      events: [
        Event(
          id: 1,
          shortCode: 'EVT1',
          name: 'Gala DIF 2026',
          date: DateTime(2026, 12, 1),
          presenceMode: PresenceMode.simple,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    final fakeBeneficiaries = FakeBeneficiaryRepository(
      beneficiaries: [
        Beneficiary(
          id: 1,
          eventId: 1,
          name: 'Jane Doe',
          customFieldValues: const {},
          createdAt: DateTime(2026, 1, 1),
          photo: _testLogoBytes,
        ),
      ],
    );
    final fakeTickets = FakeTicketRepository(
      tickets: [
        Ticket(
          id: 1,
          beneficiaryId: 1,
          eventId: 1,
          readableId: '0001',
          randomPart: 'ABCD',
          qrPayload: 'EVT1-0001-ABCD',
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        const TicketPreviewScreen(ticketId: 1),
        fakeEvents,
        fakeBeneficiaries,
        fakeTickets,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircleAvatar), findsOneWidget);
  });

  testWidgets('shows no medallion when the beneficiary has no photo', (tester) async {
    final fakeEvents = FakeEventRepository(
      events: [
        Event(
          id: 1,
          shortCode: 'EVT1',
          name: 'Gala DIF 2026',
          date: DateTime(2026, 12, 1),
          presenceMode: PresenceMode.simple,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    final fakeBeneficiaries = FakeBeneficiaryRepository(
      beneficiaries: [
        Beneficiary(
          id: 1,
          eventId: 1,
          name: 'Jane Doe',
          customFieldValues: const {},
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    final fakeTickets = FakeTicketRepository(
      tickets: [
        Ticket(
          id: 1,
          beneficiaryId: 1,
          eventId: 1,
          readableId: '0001',
          randomPart: 'ABCD',
          qrPayload: 'EVT1-0001-ABCD',
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        const TicketPreviewScreen(ticketId: 1),
        fakeEvents,
        fakeBeneficiaries,
        fakeTickets,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircleAvatar), findsNothing);
  });
```

Match this file's real `_wrap` argument order exactly (read first - it takes `fakeEvents, fakeBeneficiaries, fakeTickets` per the file already read during planning, but confirm before pasting).

- [ ] **Step 2: Run the tests to verify they fail**

Run: `fvm flutter test test/features/tickets/presentation/screens/ticket_preview_screen_test.dart`
Expected: FAIL - no `CircleAvatar` on this screen yet.

- [ ] **Step 3: Add the medallion to `_TicketCard`**

Edit `lib/features/tickets/presentation/screens/ticket_preview_screen.dart`. Add a field to `_TicketCard`:

```dart
class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.template,
    required this.eventName,
    this.eventLogo,
    required this.beneficiaryName,
    this.beneficiaryPhoto,
    required this.readableId,
    required this.qrPayload,
    required this.visibleFieldLines,
  });

  final TicketTemplate template;
  final String eventName;
  final Uint8List? eventLogo;
  final String beneficiaryName;
  final Uint8List? beneficiaryPhoto;
  final String readableId;
  final String qrPayload;
  final List<String> visibleFieldLines;
```

In `build()`, add the medallion right before the beneficiary name `Text`:

```dart
            if (beneficiaryPhoto != null) ...[
              CircleAvatar(
                backgroundImage: MemoryImage(beneficiaryPhoto!),
                radius: isCompact ? 16 : 24,
              ),
              SizedBox(height: isCompact ? 4 : 8),
            ],
            Text(
              beneficiaryName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
```

In `TicketPreviewScreen.build`, pass the new field to `_TicketCard`:

```dart
              child: _TicketCard(
                template: event.ticketTemplate,
                eventName: event.name,
                eventLogo: event.logo,
                beneficiaryName: beneficiary.name,
                beneficiaryPhoto: beneficiary.photo,
                readableId: ticket.readableId,
                qrPayload: ticket.qrPayload,
```

- [ ] **Step 4: Run the screen tests to verify they pass**

Run: `fvm flutter test test/features/tickets/presentation/screens/ticket_preview_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Write the failing PDF builder test**

Read `test/features/tickets/data/ticket_pdf_builder_test.dart` in full first (it already has `_isPdf`, `_event`, `_beneficiary`, `_ticket` helpers). Add:

```dart
  test('buildSingleTicketPdf includes a beneficiary photo without error', () async {
    final photo = Uint8List.fromList(List.generate(64, (i) => i));
    final bytes = await buildSingleTicketPdf(
      event: _event(),
      ticket: _ticket(),
      beneficiary: Beneficiary(
        id: 1,
        eventId: 1,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
        photo: photo,
      ),
      customFields: const [],
    );

    expect(_isPdf(bytes), isTrue);
  });
```

Add `import 'dart:typed_data';` if not already present (the file already imports `Beneficiary`).

- [ ] **Step 6: Run the PDF test now to confirm it compiles and passes trivially**

Run: `fvm flutter test test/features/tickets/data/ticket_pdf_builder_test.dart`
Expected: PASS - `Beneficiary.photo` already exists (Task 1), so passing one compiles fine even though `_ticketCardPdf` does not read it yet. There is no red step here (the only observable assertion is "valid PDF bytes", true before and after); Step 7 is what actually makes the photo render, verified visually rather than by a stricter assertion this suite can express.

- [ ] **Step 7: Add the medallion to the PDF card**

Edit `lib/features/tickets/data/ticket_pdf_builder.dart`. Add a parameter to `_ticketCardPdf`:

```dart
pw.Widget _ticketCardPdf({
  required TicketTemplate template,
  required String eventName,
  Uint8List? eventLogo,
  required String beneficiaryName,
  Uint8List? beneficiaryPhoto,
  required String readableId,
  required String qrPayload,
  required List<String> visibleFieldLines,
  required pw.Font monoFont,
}) {
```

In its body, add the medallion right before the beneficiary name `pw.Text`:

```dart
        if (beneficiaryPhoto != null) ...[
          pw.Container(
            width: (isCompact ? 12 : 16) * PdfPageFormat.mm,
            height: (isCompact ? 12 : 16) * PdfPageFormat.mm,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              image: pw.DecorationImage(
                image: pw.MemoryImage(beneficiaryPhoto),
                fit: pw.BoxFit.cover,
              ),
            ),
          ),
          pw.SizedBox(height: 1 * PdfPageFormat.mm),
        ],
        pw.Text(
          beneficiaryName,
          style: pw.TextStyle(fontSize: isCompact ? 8 : 10),
          textAlign: pw.TextAlign.center,
        ),
```

Pass the photo through from both call sites. In `buildSingleTicketDocument`:

```dart
        child: _ticketCardPdf(
          template: event.ticketTemplate,
          eventName: event.name,
          eventLogo: event.logo,
          beneficiaryName: beneficiary.name,
          beneficiaryPhoto: beneficiary.photo,
          readableId: ticket.readableId,
          qrPayload: ticket.qrPayload,
          visibleFieldLines: _visibleFieldLines(beneficiary, customFields),
          monoFont: monoFont,
        ),
```

In `buildEventTicketsDocument`:

```dart
              if (beneficiariesById[ticket.beneficiaryId] != null)
                _ticketCardPdf(
                  template: event.ticketTemplate,
                  eventName: event.name,
                  eventLogo: event.logo,
                  beneficiaryName:
                      beneficiariesById[ticket.beneficiaryId]!.name,
                  beneficiaryPhoto: beneficiariesById[ticket.beneficiaryId]!.photo,
                  readableId: ticket.readableId,
                  qrPayload: ticket.qrPayload,
                  visibleFieldLines: _visibleFieldLines(
                    beneficiariesById[ticket.beneficiaryId]!,
                    customFields,
                  ),
                  monoFont: monoFont,
                ),
```

- [ ] **Step 8: Run the PDF test to verify it passes**

Run: `fvm flutter test test/features/tickets/data/ticket_pdf_builder_test.dart`
Expected: PASS.

- [ ] **Step 9: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no new analyzer output.

- [ ] **Step 10: Commit**

```bash
git add lib/features/tickets/presentation/screens/ticket_preview_screen.dart lib/features/tickets/data/ticket_pdf_builder.dart test/features/tickets/presentation/screens/ticket_preview_screen_test.dart test/features/tickets/data/ticket_pdf_builder_test.dart
git commit -m "Show the beneficiary photo on the ticket, on screen and in the PDF"
```

---

### Task 5: Check-in scan confirmation

**Files:**
- Modify: `lib/features/checkin/presentation/check_in_feedback.dart`
- Modify: `lib/features/checkin/presentation/check_in_processor.dart`
- Modify: `lib/features/checkin/presentation/screens/check_in_scan_screen.dart`
- Test: `test/features/checkin/presentation/check_in_feedback_test.dart`
- Test: `test/features/checkin/presentation/check_in_processor_test.dart`

**Interfaces:**
- Consumes from Task 1: `Beneficiary.photo`.
- Produces: nothing - this is the last task.

- [ ] **Step 1: Update `CheckInFeedback`**

Edit `lib/features/checkin/presentation/check_in_feedback.dart`:

```dart
import 'dart:typed_data';

sealed class CheckInFeedback {
  const CheckInFeedback();
}

class CheckInFeedbackRecorded extends CheckInFeedback {
  const CheckInFeedbackRecorded({
    required this.beneficiaryName,
    this.beneficiaryPhoto,
  });

  final String beneficiaryName;
  final Uint8List? beneficiaryPhoto;
}

class CheckInFeedbackAlreadyRecorded extends CheckInFeedback {
  const CheckInFeedbackAlreadyRecorded({
    required this.beneficiaryName,
    required this.scannedAt,
    this.beneficiaryPhoto,
  });

  final String beneficiaryName;
  final DateTime scannedAt;
  final Uint8List? beneficiaryPhoto;
}

class CheckInFeedbackNotFound extends CheckInFeedback {
  const CheckInFeedbackNotFound();
}
```

(`checkInFeedbackAutoDismisses` and `checkInFeedbackResultLabel` below are unchanged - leave them exactly as they are.)

- [ ] **Step 2: Run the feedback test to confirm no regression**

Run: `fvm flutter test test/features/checkin/presentation/check_in_feedback_test.dart`
Expected: PASS unchanged - the existing `const CheckInFeedbackRecorded(beneficiaryName: 'Jane Doe')` calls stay valid since `beneficiaryPhoto` is optional and defaults to `null`.

- [ ] **Step 3: Write the failing processor test**

Read `test/features/checkin/presentation/check_in_processor_test.dart` in full first. Add:

```dart
  test('carries the beneficiary photo through to CheckInFeedbackRecorded', () async {
    final photo = Uint8List.fromList([1, 2, 3]);
    final feedback = await processCheckIn(
      ticketRepository: FakeTicketRepository(tickets: [ticket]),
      checkInRepository: FakeCheckInRepository(),
      beneficiaryRepository: FakeBeneficiaryRepository(
        beneficiaries: [
          Beneficiary(
            id: 1,
            eventId: 42,
            name: 'Jane Doe',
            customFieldValues: const {},
            createdAt: DateTime(2026, 1, 1),
            photo: photo,
          ),
        ],
      ),
      eventId: 42,
      presenceMode: PresenceMode.simple,
      rawInput: ticket.qrPayload,
    );

    expect((feedback as CheckInFeedbackRecorded).beneficiaryPhoto, photo);
  });
```

Add `import 'dart:typed_data';` if not already present.

- [ ] **Step 4: Run the test to verify it fails**

Run: `fvm flutter test test/features/checkin/presentation/check_in_processor_test.dart`
Expected: FAIL - `processCheckIn` does not set `beneficiaryPhoto` yet.

- [ ] **Step 5: Thread the photo through `processCheckIn`**

Edit `lib/features/checkin/presentation/check_in_processor.dart`:

```dart
  return switch (outcome) {
    CheckInRecorded() => CheckInFeedbackRecorded(
        beneficiaryName: beneficiary.name,
        beneficiaryPhoto: beneficiary.photo,
      ),
    CheckInAlreadyRecorded(:final existing) => CheckInFeedbackAlreadyRecorded(
        beneficiaryName: beneficiary.name,
        scannedAt: existing.scannedAt,
        beneficiaryPhoto: beneficiary.photo,
      ),
  };
```

- [ ] **Step 6: Run the processor test to verify it passes**

Run: `fvm flutter test test/features/checkin/presentation/check_in_processor_test.dart`
Expected: PASS.

- [ ] **Step 7: Show the photo on the overlay**

Edit `lib/features/checkin/presentation/screens/check_in_scan_screen.dart`. In `_CheckInFeedbackOverlay.build`, extend the `switch` to also capture the photo:

```dart
    String? name;
    Uint8List? photo;
    String? message;
    switch (feedback) {
      case CheckInFeedbackRecorded(:final beneficiaryName, :final beneficiaryPhoto):
        name = beneficiaryName;
        photo = beneficiaryPhoto;
      case CheckInFeedbackAlreadyRecorded(
          :final beneficiaryName,
          :final scannedAt,
          :final beneficiaryPhoto,
        ):
        name = beneficiaryName;
        photo = beneficiaryPhoto;
        message = l10n.checkinAlreadyRecordedMessage(
          DateFormat.Hm(locale).format(scannedAt),
        );
      case CheckInFeedbackNotFound():
        message = l10n.checkinNotFoundMessage;
    }
```

Add `import 'dart:typed_data';` at the top of the file if not already present. In the `Column` inside the overlay, add the photo between the icon and the name:

```dart
                Icon(icon, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                if (photo != null) ...[
                  CircleAvatar(backgroundImage: MemoryImage(photo), radius: 40),
                  const SizedBox(height: 16),
                ],
                if (name != null)
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: Colors.white),
                  ),
```

This screen has no widget test (native `MobileScannerController` dependency, established convention documented in this file already) - no test to add here; the processor test in Step 3 is the coverage for this data flowing correctly.

- [ ] **Step 8: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no new analyzer output.

- [ ] **Step 9: Commit**

```bash
git add lib/features/checkin/presentation/check_in_feedback.dart lib/features/checkin/presentation/check_in_processor.dart lib/features/checkin/presentation/screens/check_in_scan_screen.dart test/features/checkin/presentation/check_in_feedback_test.dart test/features/checkin/presentation/check_in_processor_test.dart
git commit -m "Show the beneficiary photo on the check-in confirmation overlay"
```
