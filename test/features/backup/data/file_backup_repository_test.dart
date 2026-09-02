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

  test(
    'importBackup replaces the target file when the backup is valid',
    () async {
      final sourceFile = File(p.join(tempDir.path, 'source.sqlite'));
      final sourceDb = AppDatabase.withExecutor(NativeDatabase(sourceFile));
      await sourceDb
          .into(sourceDb.events)
          .insert(
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
    },
  );

  test(
    'importBackup rejects an invalid file and leaves the target untouched',
    () async {
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
    },
  );
}
