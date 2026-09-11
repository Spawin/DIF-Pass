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
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SettingsScreen's audit export/delete flow calls the real top-level
// resolveAuditFile() (getApplicationSupportDirectory() + 'audit.jsonl'),
// not the auditLoggerProvider override's fileResolver - that override only
// matters for AuditLogger.setEnabled() calls made from setAuditEnabled().
// To make the audit file the widget resolves the same one these tests write
// to, point path_provider's application-support path at tempDir.
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

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
    late Directory tempDir;
    late File auditFile;
    late AuditLogger logger;
    late PathProviderPlatform originalPathProvider;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dif_pass_settings_audit_test');
      auditFile = File('${tempDir.path}/audit.jsonl');
      logger = AuditLogger(enabled: false, fileResolver: () async => auditFile);
      originalPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    });

    tearDown(() async {
      PathProviderPlatform.instance = originalPathProvider;
      await tempDir.delete(recursive: true);
    });

    Future<void> pumpAuditSettings(WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const SettingsScreen(),
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
      await pumpAuditSettings(tester);

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
      await auditFile.writeAsString(
        '{"ts":"2026-01-01T00:00:00.000","session":"s","type":"backup_action","action":"export"}\n',
      );
      await pumpAuditSettings(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Supprimer les donnees d\'audit'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer les donnees d\'audit ?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
      await tester.pumpAndSettle();
      expect(await auditFile.exists(), isTrue);

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
}
