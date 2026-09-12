import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Resolves the on-disk path of the local usage audit log. App-private
/// support storage (not Documents - this is not user content and is never
/// part of a database backup), same reasoning as
/// lib/core/database/app_database.dart's resolveDatabaseFile().
Future<File> resolveAuditFile() async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, 'audit.jsonl'));
}

/// Opt-in, off-by-default local usage log. No PII: every logX method below
/// takes only enum-like strings, counts, and durations. See
/// docs/superpowers/specs/2026-09-11-lot-e-usage-audit-design.md.
class AuditLogger {
  AuditLogger({required bool enabled, required this.fileResolver})
      : _enabled = enabled,
        _sessionId = const Uuid().v4();

  final Future<File> Function() fileResolver;
  final String _sessionId;
  bool _enabled;

  // ponytail: fire-and-forget log calls can be issued back-to-back (e.g. the
  // six log methods called in immediate succession, or two AuditLogger
  // instances that happen to resolve to the same file); each write
  // independently opens/writes/closes the audit file, and unserialized
  // concurrent appends can race and clobber each other. Chaining every
  // append onto a queue keyed by the resolved file path keeps the public API
  // non-blocking while making actual disk I/O for a given file strictly
  // sequential, regardless of which AuditLogger instance issued it.
  static final Map<String, Future<void>> _writeQueues = {};

  static const maxLines = 20000;
  static const maxAge = Duration(days: 365);

  void setEnabled(bool value) => _enabled = value;

  /// One rotation pass, run once at app startup before any writes: drops
  /// lines older than [maxAge] and keeps only the most recent [maxLines].
  /// ponytail: a single O(n) pass capped at maxLines, once per launch - not
  /// a per-write cost.
  Future<void> init() async {
    try {
      final file = await fileResolver();
      if (!await file.exists()) return;
      final lines = await file.readAsLines();
      final cutoff = DateTime.now().subtract(maxAge);
      final kept = <String>[];
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final ts = DateTime.parse(
            (jsonDecode(line) as Map<String, dynamic>)['ts'] as String,
          );
          if (ts.isAfter(cutoff)) kept.add(line);
        } catch (_) {
          // Malformed line (partial write, corruption) - drop it.
        }
      }
      final trimmed =
          kept.length > maxLines ? kept.sublist(kept.length - maxLines) : kept;
      if (trimmed.length != lines.length) {
        await file.writeAsString(
          trimmed.isEmpty ? '' : '${trimmed.join('\n')}\n',
        );
      }
    } catch (e) {
      // ponytail: audit rotation must never block app startup.
      debugPrint('AuditLogger.init failed: $e');
    }
  }

  void logCheckinScan({
    required String result,
    required String presenceMode,
    required int feedbackDurationMs,
    required String dismissedBy,
  }) {
    unawaited(_append({
      'type': 'checkin_scan',
      'result': result,
      'presenceMode': presenceMode,
      'feedbackDurationMs': feedbackDurationMs,
      'dismissedBy': dismissedBy,
    }));
  }

  void logEventCreated({required String presenceMode, required int customFieldCount}) {
    unawaited(_append({
      'type': 'event_created',
      'presenceMode': presenceMode,
      'customFieldCount': customFieldCount,
    }));
  }

  void logTicketsGenerated({
    required int count,
    required int durationMs,
    bool generic = false,
  }) {
    unawaited(_append({
      'type': 'tickets_generated',
      'count': count,
      'durationMs': durationMs,
      'generic': generic,
    }));
  }

  void logBeneficiariesImported({
    required int rowCount,
    required int errorCount,
    required int durationMs,
  }) {
    unawaited(_append({
      'type': 'beneficiaries_imported',
      'rowCount': rowCount,
      'errorCount': errorCount,
      'durationMs': durationMs,
    }));
  }

  void logEventArchiveAction({required String action}) {
    unawaited(_append({'type': 'event_archive_action', 'action': action}));
  }

  void logBackupAction({required String action}) {
    unawaited(_append({'type': 'backup_action', 'action': action}));
  }

  /// ponytail: swallow-and-log is deliberate here, the one place in the app
  /// where that is correct - an audit write must never break the real
  /// feature it instruments. This covers fileResolver() itself (e.g.
  /// path_provider failing to resolve a directory), not just the write in
  /// _writeOne, since both are equally "an audit write failed".
  Future<void> _append(Map<String, dynamic> event) async {
    if (!_enabled) return;
    try {
      final file = await fileResolver();
      final key = file.path;
      // Chain onto the per-path queue rather than awaiting immediately, so
      // concurrent calls still serialize even if an earlier write is still
      // in flight.
      final previous = _writeQueues[key] ?? Future<void>.value();
      final next = previous.then((_) => _writeOne(file, event));
      _writeQueues[key] = next;
      await next;
    } catch (e) {
      debugPrint('AuditLogger append failed: $e');
    }
  }

  Future<void> _writeOne(File file, Map<String, dynamic> event) async {
    try {
      await file.parent.create(recursive: true);
      final line = jsonEncode({
        'ts': DateTime.now().toIso8601String(),
        'session': _sessionId,
        ...event,
      });
      await file.writeAsString('$line\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('AuditLogger append failed: $e');
    }
  }
}
