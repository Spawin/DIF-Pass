import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';

import '../../../core/database/app_database.dart';
import 'backup_repository.dart';

class FileBackupRepository implements BackupRepository {
  FileBackupRepository(this._databaseFile);

  final File _databaseFile;

  static final _sqliteHeaderBytes = 'SQLite format 3\x00'.codeUnits;

  bool _looksLikeSqliteFile(Uint8List bytes) {
    if (bytes.length < _sqliteHeaderBytes.length) return false;
    for (var i = 0; i < _sqliteHeaderBytes.length; i++) {
      if (bytes[i] != _sqliteHeaderBytes[i]) return false;
    }
    return true;
  }

  @override
  Future<Uint8List> exportBackup() => _databaseFile.readAsBytes();

  @override
  Future<void> importBackup(Uint8List bytes) async {
    if (!_looksLikeSqliteFile(bytes)) {
      throw const FormatException('Not a valid DIF Pass backup file');
    }

    final tempFile = File('${_databaseFile.path}.import-tmp');
    try {
      await tempFile.writeAsBytes(bytes, flush: true);

      final db = AppDatabase.withExecutor(NativeDatabase(tempFile));
      try {
        await db.select(db.events).get();
      } finally {
        await db.close();
      }
    } catch (e) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      throw FormatException('Not a valid DIF Pass backup file: $e');
    }

    await tempFile.rename(_databaseFile.path);
  }
}
