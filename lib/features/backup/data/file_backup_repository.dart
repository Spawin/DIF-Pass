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

  // The six tables AppDatabase actually creates (see the $name constants in
  // lib/core/database/app_database.g.dart). Requiring all of them, not just
  // events, rejects a file where an unrelated or empty table merely happens
  // to be named events.
  static const _requiredTableNames = [
    'events',
    'custom_fields',
    'beneficiaries',
    'beneficiary_values',
    'tickets',
    'check_ins',
  ];

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
      final placeholders = List.filled(
        _requiredTableNames.length,
        '?',
      ).join(', ');
      final foundTableCount = db
          .select(
            "SELECT COUNT(*) AS c FROM sqlite_master WHERE type = 'table' AND name IN ($placeholders)",
            _requiredTableNames,
          )
          .first['c'] as int;
      // Matches AppDatabase.schemaVersion in
      // lib/core/database/app_database.dart. Kept as a literal instead of
      // instantiating AppDatabase() here, which would create and leak a
      // second live database instance (drift warns about this) just to
      // read a constant int.
      const currentSchemaVersion = 4;
      if (foundTableCount != _requiredTableNames.length ||
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
        // db.select(db.events).get() is not enough here: drift emits a
        // plain SELECT * with no column list, so a mismatched schema is
        // only caught in row mapping, which never runs against an empty
        // table. Selecting each table's real column names by name forces
        // SQLite to validate the column shape even with zero rows.
        for (final t in db.allTables) {
          final cols = t.$columns.map((c) => c.name).join(', ');
          await db.customSelect(
            'SELECT $cols FROM ${t.actualTableName} LIMIT 1',
          ).get();
        }
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
