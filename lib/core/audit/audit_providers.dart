import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audit_logger.dart';

/// Always overridden in main.dart with a real instance built from
/// AppSettings.auditEnabled and resolveAuditFile(), the same pattern
/// appSettingsProvider uses for AppSettings.load().
final auditLoggerProvider = Provider<AuditLogger>(
  (ref) => throw UnimplementedError('auditLoggerProvider must be overridden'),
);
