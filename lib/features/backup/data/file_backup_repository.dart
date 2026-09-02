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
