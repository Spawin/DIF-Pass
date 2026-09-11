import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dif_pass/core/audit/audit_logger.dart';
import 'package:dif_pass/core/audit/audit_providers.dart';
import 'package:dif_pass/core/settings/app_settings.dart';
import 'package:dif_pass/features/backup/data/backup_repository.dart';
import 'package:dif_pass/features/backup/presentation/providers/backup_providers.dart';
import 'package:dif_pass/features/backup/presentation/screens/settings_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBackupRepository implements BackupRepository {
  bool importCalled = false;

  @override
  Future<Uint8List> exportBackup() async => Uint8List(0);

  @override
  Future<void> importBackup(Uint8List bytes) async {
    importCalled = true;
  }
}

base class _FakePlatformFile extends PlatformFile {
  _FakePlatformFile(this._bytes);

  final Uint8List _bytes;

  @override
  String get name => 'backup.sqlite';

  @override
  Uri get uri => Uri.file(name);

  @override
  // Never called by SettingsScreen's import flow (only readAsBytes is).
  get xFile => throw UnimplementedError();

  @override
  Future<int> length() async => _bytes.length;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(_bytes);
}

Widget _wrap(
  Widget child, {
  BackupRepository? repository,
  List<Override> extraOverrides = const [],
  Locale? locale,
}) {
  return ProviderScope(
    overrides: [
      // Every SettingsScreen action path reads auditLoggerProvider before
      // its first await now (never mid-flight after a dispose could have
      // happened), so it must always be overridden here, disabled by
      // default. Tests that care about audit behavior pass their own
      // logger via extraOverrides, which - listed after - wins.
      auditLoggerProvider.overrideWithValue(
        AuditLogger(enabled: false, fileResolver: () async => throw UnimplementedError('not used')),
      ),
      if (repository != null)
        backupRepositoryProvider.overrideWith((ref) => repository),
      ...extraOverrides,
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('shows the export and import actions, both enabled', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Import backup'), findsOneWidget);
    final exportButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(exportButton.onPressed, isNotNull);
    final importButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Import backup'),
    );
    expect(importButton.onPressed, isNotNull);
  });

  testWidgets('disables both buttons while an import is in progress', (
    tester,
  ) async {
    final completer = Completer<PlatformFile?>();
    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          pickFile: ({FileType type = FileType.any, allowedExtensions}) =>
              completer.future,
        ),
      ),
    );

    await tester.tap(find.text('Import backup'));
    await tester.pump();

    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Import backup'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    completer.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('recovers both buttons when the file picker itself throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          pickFile: ({FileType type = FileType.any, allowedExtensions}) =>
              throw Exception('picker failed'),
        ),
      ),
    );

    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Import backup'),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('cancelling the confirm dialog does not call importBackup', (
    tester,
  ) async {
    final fake = _FakeBackupRepository();
    final bytes = Uint8List.fromList([1, 2, 3]);

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          pickFile: ({FileType type = FileType.any, allowedExtensions}) async =>
              _FakePlatformFile(bytes),
        ),
        repository: fake,
      ),
    );

    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fake.importCalled, isFalse);
  });

  testWidgets('moving the check-in delay slider persists the new value', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 1800);

    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pumpAndSettle();

    final updated = tester.widget<Slider>(find.byType(Slider));
    expect(updated.value, isNot(1800));
  });

  testWidgets('selecting a language updates the segmented button selection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('French'));
    await tester.pumpAndSettle();

    final segmentedButton = tester.widget<SegmentedButton<String?>>(
      find.byType(SegmentedButton<String?>),
    );
    expect(segmentedButton.selected, {'fr'});
  });

  group('audit section', () {
    // SettingsScreen's audit export/delete flow otherwise calls the real
    // getApplicationSupportDirectory() + File.exists()/File.delete(). Those
    // real dart:io calls proved unreliable (observed to hang indefinitely)
    // from inside testWidgets in this project's sandboxed test environment
    // whenever the audit file exists on disk at pump time. SettingsScreen
    // exposes resolveExistingAuditFile and deleteAuditFile precisely so
    // these tests can fake both and never touch the real filesystem - same
    // reasoning as the pre-existing pickFile injection above.
    final fakeAuditFile = File('Z:/fake/audit.jsonl');
    late AuditLogger logger;

    setUp(() {
      logger = AuditLogger(
        enabled: false,
        fileResolver: () async => fakeAuditFile,
      );
    });

    Future<void> pumpAuditSettings(
      WidgetTester tester, {
      Future<File?> Function()? resolveExistingAuditFile,
      Future<void> Function(File file)? deleteAuditFile,
    }) async {
      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            resolveExistingAuditFile: resolveExistingAuditFile ?? () async => null,
            deleteAuditFile: deleteAuditFile ?? (file) async {},
          ),
          extraOverrides: [auditLoggerProvider.overrideWithValue(logger)],
          locale: const Locale('fr'),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
    }

    testWidgets('toggling the switch persists the preference', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAuditSettings(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final settings = await AppSettings.load();
      expect(settings.auditEnabled, isTrue);
    });

    testWidgets('export and delete buttons are disabled when no audit file exists', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAuditSettings(tester, resolveExistingAuditFile: () async => null);

      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Exporter les donnees d\'audit'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Supprimer les donnees d\'audit'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('delete asks for confirmation and only deletes on confirm', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      // Fake both the existence check and the actual delete call rather
      // than exercising real dart:io - see the group-level comment above.
      // This test verifies the screen's own logic (dialog gating, calling
      // the injected deleter with the right file, re-checking existence
      // afterward), not that File.exists()/File.delete() themselves work.
      var fileExists = true;
      final deletedPaths = <String>[];
      await pumpAuditSettings(
        tester,
        resolveExistingAuditFile: () async => fileExists ? fakeAuditFile : null,
        deleteAuditFile: (file) async {
          deletedPaths.add(file.path);
          fileExists = false;
        },
      );

      // The button sits below the fold on a typical test viewport, inside
      // the settings body's SingleChildScrollView - scroll it into view
      // before tapping, or the tap misses (offset outside the render tree).
      final deleteTrigger = find.widgetWithText(TextButton, 'Supprimer les donnees d\'audit');
      await tester.ensureVisible(deleteTrigger);
      await tester.tap(deleteTrigger);
      await tester.pumpAndSettle();
      expect(find.text('Supprimer les donnees d\'audit ?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
      await tester.pumpAndSettle();
      expect(deletedPaths, isEmpty);

      await tester.ensureVisible(deleteTrigger);
      await tester.tap(deleteTrigger);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Supprimer'),
      ));
      await tester.pumpAndSettle();
      expect(deletedPaths, [fakeAuditFile.path]);
    });
  });
}
