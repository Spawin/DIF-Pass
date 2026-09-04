import 'dart:async';
import 'dart:typed_data';

import 'package:dif_pass/features/backup/data/backup_repository.dart';
import 'package:dif_pass/features/backup/presentation/providers/backup_providers.dart';
import 'package:dif_pass/features/backup/presentation/screens/settings_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

Widget _wrap(Widget child, {BackupRepository? repository}) {
  return ProviderScope(
    overrides: [
      if (repository != null)
        backupRepositoryProvider.overrideWith((ref) => repository),
    ],
    child: MaterialApp(
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
    final importButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
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
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    completer.complete(null);
    await tester.pumpAndSettle();
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
}
