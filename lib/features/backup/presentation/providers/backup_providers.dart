import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/backup_repository.dart';
import '../../data/file_backup_repository.dart';

final backupRepositoryProvider = FutureProvider<BackupRepository>((ref) async {
  final file = await resolveDatabaseFile();
  return FileBackupRepository(file);
});
