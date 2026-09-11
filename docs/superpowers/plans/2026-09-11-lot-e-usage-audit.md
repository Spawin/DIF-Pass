# Lot E - Local Usage Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an opt-in, off-by-default local usage audit log (`audit.jsonl`) that records check-in scan outcomes/timings and five other business-flow events, with a Settings UI to enable/export/delete it, and zero PII.

**Architecture:** A new `AuditLogger` class (one instance behind a `Provider`) appends JSON lines to a file in app-private storage. A settings section controls the enabled flag (persisted like the existing `checkinFeedbackDelayMs`) and exposes export/delete. Six screens each add one `ref.read(auditLoggerProvider).logX(...)` call after their existing action succeeds - no repository signatures change, no database schema changes.

**Tech Stack:** Flutter/Dart, Riverpod (`Provider`, existing `Notifier`), `path_provider` (`getApplicationSupportDirectory`), `uuid` (already a dependency since lot D), `dart:convert` (`jsonEncode`), `share_plus` (export), existing ARB/`AppLocalizations` i18n.

**Spec:** [docs/superpowers/specs/2026-09-11-lot-e-usage-audit-design.md](../specs/2026-09-11-lot-e-usage-audit-design.md)

## Global Constraints

- All Flutter/Dart tooling runs through FVM: `fvm flutter ...`, `fvm dart ...`.
- No PII in any logged field: no names, no locations, no logos, no readable ticket IDs, no QR payloads, no `syncId`, no local database `id`.
- The log is off by default (`AppSettings.auditEnabled` defaults to `false`). Nothing is written until a user turns it on.
- Audit writes must never throw into caller code - every `AuditLogger` write path is wrapped so a failure is swallowed (`debugPrint` only), documented with a `ponytail:` comment.
- The audit file lives at `getApplicationSupportDirectory()/audit.jsonl` - never the Documents directory, never external/shared storage.
- No network call, no automatic export, no on-device viewer/dashboard for the log. Export is only the existing manual `share_plus` share sheet.
- French ARB copy has no accents. Every ARB key with placeholders needs an `@key` metadata block (none of this lot's new keys take placeholders).
- Commit messages: no `Co-Authored-By: Claude` trailer, no "Generated with Claude" line, no em dashes anywhere.
- All existing tests must still pass at the end of every task.

---

### Task 1: `AuditLogger` engine and `AppSettings.auditEnabled`

**Files:**
- Create: `lib/core/audit/audit_logger.dart`
- Create: `lib/core/audit/audit_providers.dart`
- Modify: `lib/core/settings/app_settings.dart`
- Modify: `lib/core/settings/settings_providers.dart`
- Modify: `lib/main.dart`
- Test: `test/core/audit/audit_logger_test.dart`
- Test: `test/core/settings/app_settings_test.dart`
- Test: `test/core/settings/settings_providers_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks (first task).
- Produces:
  - `Future<File> resolveAuditFile()` in `lib/core/audit/audit_logger.dart` - same shape as `resolveDatabaseFile()` in `lib/core/database/app_database.dart`.
  - `class AuditLogger` with: constructor `AuditLogger({required bool enabled, required Future<File> Function() fileResolver})`; `void setEnabled(bool value)`; `Future<void> init()`; and six log methods: `logCheckinScan`, `logEventCreated`, `logTicketsGenerated`, `logBeneficiariesImported`, `logEventArchiveAction`, `logBackupAction` (exact signatures below). Every later task calls one of these six methods and nothing else on this class.
  - `final auditLoggerProvider = Provider<AuditLogger>(...)` in `lib/core/audit/audit_providers.dart`, overridden in `main.dart` with a real instance (mirrors how `appSettingsProvider` is overridden with a real `AppSettingsNotifier` built from `AppSettings.load()`).
  - `AppSettings.auditEnabled` (bool, default `false`), `AppSettings.saveAuditEnabled(bool)`, `AppSettingsNotifier.setAuditEnabled(bool)` - same three-part shape as `localeOverride` / `saveLocaleOverride` / `setLocaleOverride`, except `setAuditEnabled` also calls `ref.read(auditLoggerProvider).setEnabled(value)` so the live logger instance reflects the toggle immediately.

- [ ] **Step 1: Write the failing `AuditLogger` tests**

Create `test/core/audit/audit_logger_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:dif_pass/core/audit/audit_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late File auditFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dif_pass_audit_test');
    auditFile = File(p.join(tempDir.path, 'audit.jsonl'));
  });

  tearDown(() => tempDir.delete(recursive: true));

  AuditLogger buildLogger({bool enabled = true}) => AuditLogger(
        enabled: enabled,
        fileResolver: () async => auditFile,
      );

  Future<List<Map<String, dynamic>>> readLines() async {
    if (!await auditFile.exists()) return [];
    final lines = await auditFile.readAsLines();
    return lines
        .where((l) => l.trim().isNotEmpty)
        .map((l) => jsonDecode(l) as Map<String, dynamic>)
        .toList();
  }

  test('a disabled logger writes nothing', () async {
    final logger = buildLogger(enabled: false);
    logger.logCheckinScan(
      result: 'new',
      presenceMode: 'simple',
      feedbackDurationMs: 1800,
      dismissedBy: 'auto',
    );
    await Future<void>.delayed(Duration.zero);

    expect(await auditFile.exists(), isFalse);
  });

  test('logCheckinScan appends a well-formed line with the expected keys', () async {
    final logger = buildLogger();
    logger.logCheckinScan(
      result: 'already',
      presenceMode: 'multiple',
      feedbackDurationMs: 2400,
      dismissedBy: 'manual',
    );
    await Future<void>.delayed(Duration.zero);

    final lines = await readLines();
    expect(lines, hasLength(1));
    expect(lines.single['type'], 'checkin_scan');
    expect(lines.single['result'], 'already');
    expect(lines.single['presenceMode'], 'multiple');
    expect(lines.single['feedbackDurationMs'], 2400);
    expect(lines.single['dismissedBy'], 'manual');
    expect(lines.single['ts'], isNotNull);
    expect(lines.single['session'], isNotNull);
  });

  test('each of the six log methods writes its own event type', () async {
    final logger = buildLogger();
    logger.logEventCreated(presenceMode: 'simple', customFieldCount: 2);
    logger.logTicketsGenerated(count: 10, durationMs: 50);
    logger.logBeneficiariesImported(rowCount: 5, errorCount: 1, durationMs: 30);
    logger.logEventArchiveAction(action: 'archive');
    logger.logBackupAction(action: 'export');
    await Future<void>.delayed(Duration.zero);

    final types = (await readLines()).map((l) => l['type']).toList();
    expect(
      types,
      containsAll(<String>[
        'event_created',
        'tickets_generated',
        'beneficiaries_imported',
        'event_archive_action',
        'backup_action',
      ]),
    );
  });

  test('two log calls from the same logger share the same session id', () async {
    final logger = buildLogger();
    logger.logBackupAction(action: 'export');
    logger.logBackupAction(action: 'import');
    await Future<void>.delayed(Duration.zero);

    final lines = await readLines();
    expect(lines, hasLength(2));
    expect(lines[0]['session'], lines[1]['session']);
  });

  test('a fresh logger instance has a different session id', () async {
    final a = buildLogger();
    final b = buildLogger();
    a.logBackupAction(action: 'export');
    b.logBackupAction(action: 'export');
    await Future<void>.delayed(Duration.zero);

    final lines = await readLines();
    expect(lines[0]['session'], isNot(lines[1]['session']));
  });

  test('setEnabled(false) stops future writes without touching the file', () async {
    final logger = buildLogger();
    logger.logBackupAction(action: 'export');
    await Future<void>.delayed(Duration.zero);
    logger.setEnabled(false);
    logger.logBackupAction(action: 'import');
    await Future<void>.delayed(Duration.zero);

    final lines = await readLines();
    expect(lines, hasLength(1));
  });

  test('a write failure does not throw', () async {
    // fileResolver pointing at a path whose parent cannot be created
    // (a file used as a directory segment) simulates a write failure.
    final blocker = File(p.join(tempDir.path, 'blocker'));
    await blocker.writeAsString('x');
    final badFile = File(p.join(blocker.path, 'audit.jsonl'));
    final logger = AuditLogger(enabled: true, fileResolver: () async => badFile);

    expect(
      () => logger.logBackupAction(action: 'export'),
      returnsNormally,
    );
    await Future<void>.delayed(Duration.zero);
  });

  group('init', () {
    test('does nothing when no file exists', () async {
      final logger = buildLogger();
      await logger.init();
      expect(await auditFile.exists(), isFalse);
    });

    test('drops lines older than 12 months and keeps only the most recent 20000', () async {
      final now = DateTime.now();
      final old = now.subtract(const Duration(days: 400));
      final recent = now.subtract(const Duration(days: 1));
      final lines = [
        jsonEncode({'ts': old.toIso8601String(), 'session': 's', 'type': 'backup_action', 'action': 'export'}),
        for (var i = 0; i < 3; i++)
          jsonEncode({'ts': recent.toIso8601String(), 'session': 's', 'type': 'backup_action', 'action': 'export'}),
      ];
      await auditFile.writeAsString('${lines.join('\n')}\n');

      final logger = buildLogger();
      await logger.init();

      final kept = await readLines();
      expect(kept, hasLength(3));
      expect(kept.every((l) => DateTime.parse(l['ts'] as String).isAfter(old)), isTrue);
    });

    test('caps at the most recent 20000 lines even if all are recent', () async {
      final now = DateTime.now();
      final lines = List.generate(
        20005,
        (i) => jsonEncode({'ts': now.toIso8601String(), 'session': 's', 'type': 'backup_action', 'action': 'export'}),
      );
      await auditFile.writeAsString('${lines.join('\n')}\n');

      final logger = buildLogger();
      await logger.init();

      final kept = await auditFile.readAsLines();
      expect(kept.where((l) => l.trim().isNotEmpty), hasLength(AuditLogger.maxLines));
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `fvm flutter test test/core/audit/audit_logger_test.dart`
Expected: FAIL to compile - `lib/core/audit/audit_logger.dart` does not exist yet.

- [ ] **Step 3: Implement `AuditLogger`**

Create `lib/core/audit/audit_logger.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Resolves the on-disk path of the local usage audit log. App-private
/// support storage (not Documents - this is not user content and is never
/// part of a database backup), same reasoning as
/// lib/core/database/app_database.dart's resolveDatabaseFile().
Future<File> resolveAuditFile() async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, 'audit.jsonl'));
}

/// Opt-in, off-by-default local usage log. No PII: every logX method below
/// takes only enum-like strings, counts, and durations. See
/// docs/superpowers/specs/2026-09-11-lot-e-usage-audit-design.md.
class AuditLogger {
  AuditLogger({required bool enabled, required this.fileResolver})
      : _enabled = enabled,
        _sessionId = const Uuid().v4();

  final Future<File> Function() fileResolver;
  final String _sessionId;
  bool _enabled;

  static const maxLines = 20000;
  static const maxAge = Duration(days: 365);

  void setEnabled(bool value) => _enabled = value;

  /// One rotation pass, run once at app startup before any writes: drops
  /// lines older than [maxAge] and keeps only the most recent [maxLines].
  /// ponytail: a single O(n) pass capped at maxLines, once per launch - not
  /// a per-write cost.
  Future<void> init() async {
    try {
      final file = await fileResolver();
      if (!await file.exists()) return;
      final lines = await file.readAsLines();
      final cutoff = DateTime.now().subtract(maxAge);
      final kept = <String>[];
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final ts = DateTime.parse(
            (jsonDecode(line) as Map<String, dynamic>)['ts'] as String,
          );
          if (ts.isAfter(cutoff)) kept.add(line);
        } catch (_) {
          // Malformed line (partial write, corruption) - drop it.
        }
      }
      final trimmed =
          kept.length > maxLines ? kept.sublist(kept.length - maxLines) : kept;
      if (trimmed.length != lines.length) {
        await file.writeAsString(
          trimmed.isEmpty ? '' : '${trimmed.join('\n')}\n',
        );
      }
    } catch (e) {
      // ponytail: audit rotation must never block app startup.
      debugPrint('AuditLogger.init failed: $e');
    }
  }

  void logCheckinScan({
    required String result,
    required String presenceMode,
    required int feedbackDurationMs,
    required String dismissedBy,
  }) {
    unawaited(_append({
      'type': 'checkin_scan',
      'result': result,
      'presenceMode': presenceMode,
      'feedbackDurationMs': feedbackDurationMs,
      'dismissedBy': dismissedBy,
    }));
  }

  void logEventCreated({required String presenceMode, required int customFieldCount}) {
    unawaited(_append({
      'type': 'event_created',
      'presenceMode': presenceMode,
      'customFieldCount': customFieldCount,
    }));
  }

  void logTicketsGenerated({required int count, required int durationMs}) {
    unawaited(_append({
      'type': 'tickets_generated',
      'count': count,
      'durationMs': durationMs,
    }));
  }

  void logBeneficiariesImported({
    required int rowCount,
    required int errorCount,
    required int durationMs,
  }) {
    unawaited(_append({
      'type': 'beneficiaries_imported',
      'rowCount': rowCount,
      'errorCount': errorCount,
      'durationMs': durationMs,
    }));
  }

  void logEventArchiveAction({required String action}) {
    unawaited(_append({'type': 'event_archive_action', 'action': action}));
  }

  void logBackupAction({required String action}) {
    unawaited(_append({'type': 'backup_action', 'action': action}));
  }

  /// ponytail: swallow-and-log is deliberate here, the one place in the app
  /// where that is correct - an audit write must never break the real
  /// feature it instruments.
  Future<void> _append(Map<String, dynamic> event) async {
    if (!_enabled) return;
    try {
      final file = await fileResolver();
      await file.parent.create(recursive: true);
      final line = jsonEncode({
        'ts': DateTime.now().toIso8601String(),
        'session': _sessionId,
        ...event,
      });
      await file.writeAsString('$line\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('AuditLogger append failed: $e');
    }
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `fvm flutter test test/core/audit/audit_logger_test.dart`
Expected: PASS (all cases green).

- [ ] **Step 5: Add the provider**

Create `lib/core/audit/audit_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audit_logger.dart';

/// Always overridden in main.dart with a real instance built from
/// AppSettings.auditEnabled and resolveAuditFile(), the same pattern
/// appSettingsProvider uses for AppSettings.load().
final auditLoggerProvider = Provider<AuditLogger>(
  (ref) => throw UnimplementedError('auditLoggerProvider must be overridden'),
);
```

- [ ] **Step 6: Add `AppSettings.auditEnabled`**

Edit `lib/core/settings/app_settings.dart`. Add the field, the storage key, and the save method, mirroring `localeOverride` exactly:

```dart
class AppSettings {
  const AppSettings({
    required this.checkinFeedbackDelayMs,
    this.localeOverride,
    this.auditEnabled = false,
  });

  final int checkinFeedbackDelayMs;
  final String? localeOverride;
  final bool auditEnabled;

  static const defaultDelayMs = 1800;
  static const _delayKey = 'checkin_feedback_delay_ms';
  static const _localeKey = 'locale_override';
  static const _auditEnabledKey = 'audit_enabled';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      checkinFeedbackDelayMs: prefs.getInt(_delayKey) ?? defaultDelayMs,
      localeOverride: prefs.getString(_localeKey),
      auditEnabled: prefs.getBool(_auditEnabledKey) ?? false,
    );
  }

  static Future<void> saveCheckinFeedbackDelayMs(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_delayKey, value);
  }

  static Future<void> saveLocaleOverride(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, value);
    }
  }

  static Future<void> saveAuditEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_auditEnabledKey, value);
  }
}
```

- [ ] **Step 7: Add the failing settings tests**

Append to `test/core/settings/app_settings_test.dart` (inside the existing `main()`, following the existing `group` style):

```dart
  group('AppSettings.auditEnabled', () {
    test('defaults to false when nothing is stored', () async {
      final settings = await AppSettings.load();
      expect(settings.auditEnabled, isFalse);
    });

    test('saveAuditEnabled persists the value for a later load', () async {
      await AppSettings.saveAuditEnabled(true);
      final settings = await AppSettings.load();
      expect(settings.auditEnabled, isTrue);
    });
  });
```

Append to `test/core/settings/settings_providers_test.dart`:

```dart
  test('setAuditEnabled updates state, persists, and updates the live AuditLogger', () async {
    final logger = AuditLogger(
      enabled: false,
      fileResolver: () async => File('${Directory.systemTemp.path}/unused_audit.jsonl'),
    );
    final container = ProviderContainer(
      overrides: [auditLoggerProvider.overrideWithValue(logger)],
    );
    addTearDown(container.dispose);

    await container.read(appSettingsProvider.notifier).setAuditEnabled(true);

    expect(container.read(appSettingsProvider).auditEnabled, isTrue);
    final settings = await AppSettings.load();
    expect(settings.auditEnabled, isTrue);
  });
```

Add the two needed imports at the top of `settings_providers_test.dart`: `import 'dart:io';` and `import 'package:dif_pass/core/audit/audit_logger.dart';` and `import 'package:dif_pass/core/audit/audit_providers.dart';`.

(There is no direct assertion that `AuditLogger.setEnabled` was called without a spy; a `_SpyAuditLogger extends AuditLogger` overriding `setEnabled` to record the call is worth adding here if straightforward - if `AuditLogger`'s fields make subclassing awkward, asserting the persisted+state values is sufficient and the live-instance wiring is exercised end-to-end by Task 2's widget test instead.)

- [ ] **Step 8: Implement `setAuditEnabled`**

Edit `lib/core/settings/settings_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audit/audit_providers.dart';
import 'app_settings.dart';

class AppSettingsNotifier extends Notifier<AppSettings> {
  AppSettingsNotifier([this._initial]);

  final AppSettings? _initial;

  @override
  AppSettings build() =>
      _initial ?? const AppSettings(checkinFeedbackDelayMs: AppSettings.defaultDelayMs);

  Future<void> setCheckinFeedbackDelayMs(int value) async {
    await AppSettings.saveCheckinFeedbackDelayMs(value);
    state = AppSettings(
      checkinFeedbackDelayMs: value,
      localeOverride: state.localeOverride,
      auditEnabled: state.auditEnabled,
    );
  }

  Future<void> setLocaleOverride(String? value) async {
    await AppSettings.saveLocaleOverride(value);
    state = AppSettings(
      checkinFeedbackDelayMs: state.checkinFeedbackDelayMs,
      localeOverride: value,
      auditEnabled: state.auditEnabled,
    );
  }

  Future<void> setAuditEnabled(bool value) async {
    await AppSettings.saveAuditEnabled(value);
    ref.read(auditLoggerProvider).setEnabled(value);
    state = AppSettings(
      checkinFeedbackDelayMs: state.checkinFeedbackDelayMs,
      localeOverride: state.localeOverride,
      auditEnabled: value,
    );
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
```

- [ ] **Step 9: Wire into `main.dart`**

Edit `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/audit/audit_logger.dart';
import 'core/audit/audit_providers.dart';
import 'core/router/app_router.dart';
import 'core/settings/app_settings.dart';
import 'core/settings/settings_providers.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialSettings = await AppSettings.load();
  final auditLogger = AuditLogger(
    enabled: initialSettings.auditEnabled,
    fileResolver: resolveAuditFile,
  );
  await auditLogger.init();
  runApp(
    ProviderScope(
      overrides: [
        appSettingsProvider.overrideWith(() => AppSettingsNotifier(initialSettings)),
        auditLoggerProvider.overrideWithValue(auditLogger),
      ],
      child: const DifPassApp(),
    ),
  );
}
```

(the rest of `main.dart` - the `DifPassApp` widget - is unchanged)

- [ ] **Step 10: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no new analyzer output. `test/widget_test.dart` boots `DifPassApp` - check whether it constructs its own `ProviderScope` overrides independent of `main()`; if it does not go through `main()` at all, no change is needed there since `auditLoggerProvider` is only read once `setAuditEnabled` or an instrumentation call site reaches it, and none do yet in this task.

- [ ] **Step 11: Commit**

```bash
git add lib/core/audit lib/core/settings lib/main.dart test/core/audit test/core/settings
git commit -m "Add the opt-in local audit logger"
```

---

### Task 2: Settings screen - consent UI, export, delete, backup instrumentation

**Files:**
- Modify: `lib/features/backup/presentation/screens/settings_screen.dart`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/features/backup/presentation/screens/settings_screen_test.dart`

**Interfaces:**
- Consumes from Task 1: `auditLoggerProvider`, `AuditLogger.logBackupAction({required String action})`, `appSettingsProvider` / `AppSettingsNotifier.setAuditEnabled(bool)`, `AppSettings.auditEnabled`, `resolveAuditFile()`.
- Produces: nothing consumed by later tasks (Tasks 3-4 touch different screens).

- [ ] **Step 1: Add the ARB keys**

Add to `lib/l10n/app_fr.arb` (no accents), near the existing `settingsLanguageLabel` key:

```json
  "settingsAuditSectionTitle": "Statistiques d'utilisation",
  "settingsAuditExplanation": "Enregistre localement les scans et les principales actions (creation d'evenement, generation de tickets, import, sauvegarde) pour ameliorer l'application plus tard. Aucun nom, aucune donnee personnelle. Reste sur cet appareil sauf si vous exportez le fichier vous-meme. Desactivable et supprimable a tout moment.",
  "settingsAuditToggleLabel": "Activer les statistiques d'utilisation",
  "settingsAuditExportAction": "Exporter les donnees d'audit",
  "settingsAuditDeleteAction": "Supprimer les donnees d'audit",
  "settingsAuditDeleteConfirmTitle": "Supprimer les donnees d'audit ?",
  "settingsAuditDeleteConfirmBody": "Cette action supprime definitivement le journal d'utilisation enregistre sur cet appareil.",
  "settingsAuditDeleteSuccess": "Donnees d'audit supprimees",
  "settingsAuditDeleteError": "Echec de la suppression des donnees d'audit",
  "settingsAuditExportError": "Echec de l'export des donnees d'audit",
```

Add the matching English keys to `lib/l10n/app_en.arb` at the same relative position:

```json
  "settingsAuditSectionTitle": "Usage statistics",
  "settingsAuditExplanation": "Locally records scans and the main actions (event creation, ticket generation, import, backup) to improve the app later. No names, no personal data. Stays on this device unless you export the file yourself. Can be turned off and deleted at any time.",
  "settingsAuditToggleLabel": "Enable usage statistics",
  "settingsAuditExportAction": "Export audit data",
  "settingsAuditDeleteAction": "Delete audit data",
  "settingsAuditDeleteConfirmTitle": "Delete audit data?",
  "settingsAuditDeleteConfirmBody": "This permanently deletes the usage log recorded on this device.",
  "settingsAuditDeleteSuccess": "Audit data deleted",
  "settingsAuditDeleteError": "Failed to delete audit data",
  "settingsAuditExportError": "Failed to export audit data",
```

None of these keys take placeholders, so no `@key` metadata blocks are needed.

- [ ] **Step 2: Regenerate localizations**

Run: `fvm flutter gen-l10n`
Expected: `AppLocalizations` gains the ten new getters, no errors.

- [ ] **Step 3: Write the failing widget tests**

Add to `test/features/backup/presentation/screens/settings_screen_test.dart`. First add these imports at the top:

```dart
import 'dart:io';

import 'package:dif_pass/core/audit/audit_logger.dart';
import 'package:dif_pass/core/audit/audit_providers.dart';
```

Then add a helper near the top of `main()` (or as a top-level function) that builds a real `AuditLogger` pointed at a temp file, and use it in a new `overrides` entry alongside whatever the existing tests already override (`backupRepositoryProvider`, etc.) - read the existing test's `_buildApp`/`pumpWidget` helper first and extend its override list rather than duplicating it. Add these cases:

```dart
  group('audit section', () {
    late Directory tempDir;
    late File auditFile;
    late AuditLogger logger;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dif_pass_settings_audit_test');
      auditFile = File('${tempDir.path}/audit.jsonl');
      logger = AuditLogger(enabled: false, fileResolver: () async => auditFile);
    });

    tearDown(() => tempDir.delete(recursive: true));

    testWidgets('toggling the switch persists the preference', (tester) async {
      SharedPreferences.setMockInitialValues({});
      // pump the settings screen with auditLoggerProvider overridden to `logger`
      // (extend the existing pumpWidget helper's overrides list with
      // auditLoggerProvider.overrideWithValue(logger)).

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final settings = await AppSettings.load();
      expect(settings.auditEnabled, isTrue);
    });

    testWidgets('export and delete buttons are disabled when no audit file exists', (tester) async {
      // same pump as above, auditFile does not exist yet.
      expect(
        tester
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Exporter les donnees d\'audit'))
            .onPressed,
        isNull,
      );
    });

    testWidgets('delete asks for confirmation and only deletes on confirm', (tester) async {
      await auditFile.writeAsString('{"ts":"2026-01-01T00:00:00.000","session":"s","type":"backup_action","action":"export"}\n');
      // same pump as above

      // Open the dialog (button label includes "d'audit"; dialog title adds
      // a "?" so the two never collide).
      await tester.tap(find.widgetWithText(TextButton, 'Supprimer les donnees d\'audit'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer les donnees d\'audit ?'), findsOneWidget);

      // Cancel: file survives.
      await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
      await tester.pumpAndSettle();
      expect(await auditFile.exists(), isTrue);

      // Reopen and confirm this time. The dialog's confirm button uses the
      // generic l10n.commonDelete ("Supprimer"), distinct from the
      // triggering button's longer label, found by locating it inside the
      // AlertDialog rather than by ambiguous global text.
      await tester.tap(find.widgetWithText(TextButton, 'Supprimer les donnees d\'audit'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Supprimer'),
      ));
      await tester.pumpAndSettle();
      expect(await auditFile.exists(), isFalse);
    });
  });
```

Adjust the exact `find` calls once the real localized French strings are visible after Step 2 - the strings above must match `app_fr.arb` exactly since the test app defaults to French unless a test overrides the locale (check the existing tests in this file for how they assert on text, and follow the same convention rather than introducing a new one).

- [ ] **Step 4: Run to verify failure**

Run: `fvm flutter test test/features/backup/presentation/screens/settings_screen_test.dart`
Expected: FAIL - the widgets/strings referenced do not exist in `SettingsScreen` yet.

- [ ] **Step 5: Implement the settings screen changes**

Edit `lib/features/backup/presentation/screens/settings_screen.dart`. Add imports:

```dart
import '../../../../core/audit/audit_logger.dart';
import '../../../../core/audit/audit_providers.dart';
```

In `_export()`, after the existing successful share and before the snackbar (or right after, order does not matter as long as it is inside the try block's success path):

```dart
      ref.read(auditLoggerProvider).logBackupAction(action: 'export');
```

In `_import()`, after `await repository.importBackup(bytes);` succeeds and before `container.invalidate(appDatabaseProvider);`:

```dart
      ref.read(auditLoggerProvider).logBackupAction(action: 'import');
```

Add a new `_AuditSection` (or inline) stateful piece to the screen. Since `_SettingsScreenState` is already a `ConsumerState`, add these methods to it:

```dart
  Future<File?> _auditFileIfExists() async {
    final file = await resolveAuditFile();
    return await file.exists() ? file : null;
  }

  Future<void> _exportAudit() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await resolveAuditFile();
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsAuditExportError)));
    }
  }

  Future<void> _deleteAudit() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsAuditDeleteConfirmTitle),
        content: Text(l10n.settingsAuditDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final file = await resolveAuditFile();
      if (await file.exists()) await file.delete();
      if (!mounted) return;
      setState(() {});
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsAuditDeleteSuccess)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsAuditDeleteError)));
    }
  }
```

In `build()`, use a `FutureBuilder<File?>` (or a small local `StatefulWidget`) driven by `_auditFileIfExists()` to know whether to enable the export/delete buttons; simplest is a `FutureBuilder` rebuilt via the `setState(() {})` call above after delete. Append this block at the end of the `Column`'s `children`, after the language `SegmentedButton`:

```dart
            const SizedBox(height: 32),
            Text(l10n.settingsAuditSectionTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(l10n.settingsAuditExplanation, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsAuditToggleLabel),
              value: settings.auditEnabled,
              onChanged: (value) =>
                  ref.read(appSettingsProvider.notifier).setAuditEnabled(value),
            ),
            const SizedBox(height: 8),
            FutureBuilder<File?>(
              future: _auditFileIfExists(),
              builder: (context, snapshot) {
                final hasFile = snapshot.data != null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: hasFile ? _exportAudit : null,
                      icon: const Icon(Icons.upload_outlined),
                      label: Text(l10n.settingsAuditExportAction),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: hasFile ? _deleteAudit : null,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.settingsAuditDeleteAction),
                      style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    ),
                  ],
                );
              },
            ),
```

Add `import 'dart:io';` if not already present (it already is, for the export/import backup flow).

- [ ] **Step 6: Run the widget tests to verify they pass**

Run: `fvm flutter test test/features/backup/presentation/screens/settings_screen_test.dart`
Expected: PASS. Fix any `find` mismatches against the exact French strings from Step 1.

- [ ] **Step 7: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no new analyzer output.

- [ ] **Step 8: Commit**

```bash
git add lib/features/backup lib/l10n test/features/backup
git commit -m "Add the audit consent, export and delete controls to Settings"
```

---

### Task 3: Instrument the check-in scan screen

**Files:**
- Modify: `lib/features/checkin/presentation/screens/check_in_scan_screen.dart`
- Test: `test/features/checkin/presentation/screens/check_in_scan_screen_test.dart` (if it exists) or a new focused test

**Interfaces:**
- Consumes from Task 1: `auditLoggerProvider`, `AuditLogger.logCheckinScan({required String result, required String presenceMode, required int feedbackDurationMs, required String dismissedBy})`.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Check for an existing widget test file**

Run: `ls test/features/checkin/presentation/screens/ 2>/dev/null || echo none`

This screen depends on `MobileScannerController` (native camera) - per this project's established convention (documented in the codebase for this exact screen), it may have no widget test. If none exists, skip Steps 2 and 5-6 below and instead extract the result-labelling logic into one pure, unit-testable function (Step 3 does this either way) and write a plain `test/features/checkin/presentation/screens/check_in_result_label_test.dart` unit test for it (Step 4). If a widget test file does exist, read it fully before writing Step 2's assertions so they match its existing pump/override conventions.

- [ ] **Step 2 (only if a widget test file exists): write a failing assertion**

Using whatever fake `TicketRepository`/`CheckInRepository`/`BeneficiaryRepository` the existing test already builds, override `auditLoggerProvider` with a real `AuditLogger` pointed at a temp file (same pattern as Task 1's tests), drive one successful scan through to dismissal, then assert one `checkin_scan` line was written with the expected `result`/`dismissedBy`. If the existing test harness cannot drive a scan without the native scanner (e.g. it only tests the manual-entry field), use that path (`CheckInManualEntryField.onSubmit` already calls `_process` directly, no camera needed).

- [ ] **Step 3: Extract a pure result-label function**

In `lib/features/checkin/check_in_feedback.dart` (the file that already defines `CheckInFeedback`, `checkInFeedbackAutoDismisses`, etc. - read it first to match its exact style), add:

```dart
/// Maps a feedback outcome to the audit log's `result` field. Pure and
/// side-effect free so it is unit-testable without any screen or camera.
String checkInFeedbackResultLabel(CheckInFeedback feedback) {
  return switch (feedback) {
    CheckInFeedbackRecorded() => 'new',
    CheckInFeedbackAlreadyRecorded() => 'already',
    CheckInFeedbackNotFound() => 'not_found',
  };
}
```

- [ ] **Step 4: Write and run the pure-function unit test**

Create `test/features/checkin/check_in_feedback_result_label_test.dart` (colocate next to the existing test for `checkInFeedbackAutoDismisses` if one exists at `test/features/checkin/check_in_feedback_test.dart` - add these cases there instead of a new file if so):

```dart
import 'package:dif_pass/features/checkin/check_in_feedback.dart';
import 'package:dif_pass/features/checkin/domain/check_in.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps each feedback variant to its audit result label', () {
    expect(
      checkInFeedbackResultLabel(CheckInFeedbackRecorded(beneficiaryName: 'A')),
      'new',
    );
    expect(
      checkInFeedbackResultLabel(
        CheckInFeedbackAlreadyRecorded(beneficiaryName: 'A', scannedAt: DateTime(2026)),
      ),
      'already',
    );
    expect(checkInFeedbackResultLabel(const CheckInFeedbackNotFound()), 'not_found');
  });
}
```

Adjust the constructor calls above to match `CheckInFeedback`'s actual field names and constness (read `lib/features/checkin/check_in_feedback.dart` first - do not guess).

Run: `fvm flutter test test/features/checkin/check_in_feedback_result_label_test.dart` (or wherever Step 4 placed it)
Expected: FAIL first (function does not exist) after Step 3 is skipped, or PASS once Step 3 is done - do Step 3 before running this.

- [ ] **Step 5: Instrument `CheckInScanScreen`**

Edit `lib/features/checkin/presentation/screens/check_in_scan_screen.dart`. Add imports:

```dart
import '../../../../core/audit/audit_providers.dart';
import '../check_in_feedback.dart';
```

(`check_in_feedback.dart` is likely already imported for `checkInFeedbackAutoDismisses` and the `CheckInFeedback*` types - do not duplicate the import, just confirm `checkInFeedbackResultLabel` is reachable.)

Add two fields to `_CheckInScanScreenState`:

```dart
  DateTime? _feedbackShownAt;
  String? _feedbackPresenceMode;
```

In `_process`, where feedback is set (`setState(() => _feedback = feedback);`), capture the timestamp and presence mode right after:

```dart
        if (mounted) {
          setState(() => _feedback = feedback);
          _feedbackShownAt = DateTime.now();
          _feedbackPresenceMode = event.presenceMode.name;
          if (feedback is CheckInFeedbackRecorded) {
```

Change `_dismissFeedback` to accept and use the dismiss origin:

```dart
  void _dismissFeedback({bool auto = false}) {
    if (!mounted) return;
    final feedback = _feedback;
    final shownAt = _feedbackShownAt;
    if (feedback != null && shownAt != null) {
      ref.read(auditLoggerProvider).logCheckinScan(
            result: checkInFeedbackResultLabel(feedback),
            presenceMode: _feedbackPresenceMode ?? 'simple',
            feedbackDurationMs: DateTime.now().difference(shownAt).inMilliseconds,
            dismissedBy: auto ? 'auto' : 'manual',
          );
    }
    _feedbackShownAt = null;
    _scanGeneration++;
    setState(() {
      _feedback = null;
      _busy = false;
    });
    if (!_manualEntry) {
      _controller.start();
    }
  }
```

Change the auto-dismiss call site inside `_process` (the one after the `Future<void>.delayed`) from `_dismissFeedback();` to `_dismissFeedback(auto: true);`. Leave the error-path call (`_dismissFeedback();` in the `catch (_)` block) and the overlay's `onDismiss: _dismissFeedback` unchanged - both correctly default to `auto: false`, and the error-path call logs nothing because `_feedback` is still null at that point (no `checkin_scan` outcome to record).

- [ ] **Step 6: Run the tests**

Run: `fvm flutter test test/features/checkin/` and then `fvm flutter test` (full suite)
Expected: all pass. If Step 2's widget test was written, confirm it passes; otherwise confirm nothing in `test/features/checkin/presentation/screens/` broke (there should be no file there per Step 1's finding).

- [ ] **Step 7: Analyze**

Run: `fvm flutter analyze`
Expected: no new issues.

- [ ] **Step 8: Commit**

```bash
git add lib/features/checkin test/features/checkin
git commit -m "Log check-in scan outcomes and feedback duration to the audit log"
```

---

### Task 4: Instrument event creation, ticket generation, CSV import, and archive/restore

**Files:**
- Modify: `lib/features/events/presentation/screens/event_form_screen.dart`
- Modify: `lib/features/tickets/presentation/screens/tickets_screen.dart`
- Modify: `lib/features/beneficiaries/presentation/screens/csv_import_screen.dart`
- Modify: `lib/features/events/presentation/screens/events_list_screen.dart`
- Modify: `lib/features/events/presentation/screens/event_archive_screen.dart`
- Test: existing test files for the five screens above, extended only where doing so is a small, additive change to an existing success-path test (see Step-by-step below)

**Interfaces:**
- Consumes from Task 1: `auditLoggerProvider`, `AuditLogger.logEventCreated`, `AuditLogger.logTicketsGenerated`, `AuditLogger.logBeneficiariesImported`, `AuditLogger.logEventArchiveAction`.
- Produces: nothing - this is the last task.

- [ ] **Step 1: `event_form_screen.dart` - log `event_created`**

Read the full `_save` method first (around line 140-199) to confirm variable names. Add the import `import '../../../../core/audit/audit_providers.dart';`. In the `else` branch that calls `createEvent` (the non-editing branch, around line 175-182), immediately after the `await repository.createEvent(...)` call succeeds and before `if (!mounted) return;`:

```dart
        ref.read(auditLoggerProvider).logEventCreated(
              presenceMode: _presenceMode.name,
              customFieldCount: _customFields.length,
            );
```

Do NOT add this to the `if (_isEditing)` branch - only creation is logged, per the design's `event_created` type.

- [ ] **Step 2: `tickets_screen.dart` - log `tickets_generated`**

Read the method containing the `generateMissingTickets` call (around line 230-243) in full first. Add the import. Wrap the call with timing and log on success:

```dart
    try {
      final stopwatch = Stopwatch()..start();
      final created = await ref
          .read(ticketRepositoryProvider)
          .generateMissingTickets(eventId);
      stopwatch.stop();
      ref.read(auditLoggerProvider).logTicketsGenerated(
            count: created,
            durationMs: stopwatch.elapsedMilliseconds,
          );
      HapticFeedback.lightImpact();
```

- [ ] **Step 3: `csv_import_screen.dart` - log `beneficiaries_imported`**

Read `_handleImport` in full first (around line 55-72). Add the import. Wrap with timing:

```dart
  Future<void> _handleImport(List<NewBeneficiary> beneficiaries, int skipped) async {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(beneficiaryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final stopwatch = Stopwatch()..start();
      final imported =
          await repository.importBeneficiaries(widget.eventId, beneficiaries);
      stopwatch.stop();
      ref.read(auditLoggerProvider).logBeneficiariesImported(
            rowCount: imported,
            errorCount: skipped,
            durationMs: stopwatch.elapsedMilliseconds,
          );
      if (!mounted) return;
```

- [ ] **Step 4: `events_list_screen.dart` - log `event_archive_action` (archive)**

Read the `onArchive` callback in full first (around line 60-82). Add the import. After `await repository.archiveEvent(event.id);` succeeds and before `HapticFeedback.lightImpact();`:

```dart
                    ref.read(auditLoggerProvider).logEventArchiveAction(action: 'archive');
```

Do not log the snackbar's `Undo` action (`onPressed: () => repository.restoreEvent(event.id)`) - it is a secondary shortcut, not the primary restore flow (which lives in `event_archive_screen.dart` and is covered by Step 5).

- [ ] **Step 5: `event_archive_screen.dart` - log `event_archive_action` (restore)**

Read the restore `IconButton`'s `onPressed` in full first (around line 48-68). Add the import. After `await repository.restoreEvent(event.id);` succeeds and before the `messenger.showSnackBar(...)` call:

```dart
                          ref.read(auditLoggerProvider).logEventArchiveAction(action: 'restore');
```

- [ ] **Step 6: Extend tests where cheap**

For each of the five screens, open its existing test file and find the test that already exercises the successful path touched above (event creation succeeds and pops; ticket generation succeeds and shows the count snackbar; CSV import succeeds and shows the summary; archive succeeds and shows the undo snackbar; restore succeeds and shows its snackbar). For each one where the existing test already overrides providers via a `ProviderScope`/`overrides` list in a reusable pump helper:

- Add `auditLoggerProvider.overrideWithValue(<a real AuditLogger pointed at a per-test temp file, same pattern as Task 1/2/3>)` to that helper's overrides.
- Add one assertion after the existing successful-path assertions that the audit file now contains exactly one line whose `type` matches (`event_created` / `tickets_generated` / `beneficiaries_imported` / `event_archive_action`).

If a given screen's test file does not already have a reusable override list (e.g. it constructs a fresh `ProviderScope` inline in every test with no shared helper), skip adding the assertion for that screen rather than restructuring its test suite - note which screens were skipped and why in the task report. This is a deliberate YAGNI call from the design: instrumentation correctness for these five is low-risk (one line each, mirrored five times) and not worth disproportionate test-harness rework.

- [ ] **Step 7: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no new analyzer output.

- [ ] **Step 8: Commit**

```bash
git add lib/features/events lib/features/tickets lib/features/beneficiaries test/features/events test/features/tickets test/features/beneficiaries
git commit -m "Log event creation, ticket generation, CSV import, and archive actions"
```
