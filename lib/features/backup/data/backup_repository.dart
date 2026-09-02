import 'dart:typed_data';

abstract class BackupRepository {
  Future<Uint8List> exportBackup();
  Future<void> importBackup(Uint8List bytes);
}
