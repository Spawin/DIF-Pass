import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

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

  // Guards against two failure modes that drift's default onCreate would
  // otherwise mask: (1) a genuinely valid but unrelated SQLite file with
  // user_version == 0, which drift would treat as never-initialized and
  // silently populate with an empty DIF Pass schema, and (2) a backup from
  // a newer app schema version than this app currently knows, which would
  // silently stamp the file's version down during onUpgrade. Uses the raw
  // sqlite3 package directly so this check runs before AppDatabase (and its
  // onCreate/onUpgrade migration logic) ever touches the file.
  void _validateBackupSchema(File tempFile) {
    final db = sqlite3.open(tempFile.path, mode: OpenMode.readOnly);
    try {
      final hasEventsTable = db
          .select(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'events'",
          )
          .isNotEmpty;
      // Matches AppDatabase.schemaVersion in
      // lib/core/database/app_database.dart. Kept as a literal instead of
      // instantiating AppDatabase() here, which would create and leak a
      // second live database instance (drift warns about this) just to
      // read a constant int.
      const currentSchemaVersion = 2;
      if (!hasEventsTable ||
          db.userVersion <= 0 ||
          db.userVersion > currentSchemaVersion) {
        throw const FormatException('Not a valid DIF Pass backup file');
      }
    } finally {
      db.close();
    }
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

      _validateBackupSchema(tempFile);

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
