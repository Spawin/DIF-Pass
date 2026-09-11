import 'dart:convert';
import 'dart:io';

import 'package:dif_pass/core/audit/audit_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// ponytail: AuditLogger's log methods are deliberately fire-and-forget
// (void, not Future<void>) so instrumented call sites never await disk I/O.
// A single `Future<void>.delayed(Duration.zero)` is not always enough to let
// that write land on slower/antivirus-scanned disks (observed ~100ms here on
// Windows), so tests wait a short real delay instead of one event-loop turn.
const _writeSettleDelay = Duration(milliseconds: 800);

void main() {
  late Directory tempDir;
  late File auditFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dif_pass_audit_test');
    auditFile = File(p.join(tempDir.path, 'audit.jsonl'));
  });

  tearDown(() => tempDir.delete(recursive: true));

  AuditLogger buildLogger({bool enabled = true}) => AuditLogger(
        enabled: enabled,
        fileResolver: () async => auditFile,
      );

  Future<List<Map<String, dynamic>>> readLines() async {
    if (!await auditFile.exists()) return [];
    final lines = await auditFile.readAsLines();
    return lines
        .where((l) => l.trim().isNotEmpty)
        .map((l) => jsonDecode(l) as Map<String, dynamic>)
        .toList();
  }

  test('a disabled logger writes nothing', () async {
    final logger = buildLogger(enabled: false);
    logger.logCheckinScan(
      result: 'new',
      presenceMode: 'simple',
      feedbackDurationMs: 1800,
      dismissedBy: 'auto',
    );
    await Future<void>.delayed(_writeSettleDelay);

    expect(await auditFile.exists(), isFalse);
  });

  test('logCheckinScan appends a well-formed line with the expected keys', () async {
    final logger = buildLogger();
    logger.logCheckinScan(
      result: 'already',
      presenceMode: 'multiple',
      feedbackDurationMs: 2400,
      dismissedBy: 'manual',
    );
    await Future<void>.delayed(_writeSettleDelay);

    final lines = await readLines();
    expect(lines, hasLength(1));
    expect(lines.single['type'], 'checkin_scan');
    expect(lines.single['result'], 'already');
    expect(lines.single['presenceMode'], 'multiple');
    expect(lines.single['feedbackDurationMs'], 2400);
    expect(lines.single['dismissedBy'], 'manual');
    expect(lines.single['ts'], isNotNull);
    expect(lines.single['session'], isNotNull);
  });

  test('each of the six log methods writes its own event type', () async {
    final logger = buildLogger();
    logger.logEventCreated(presenceMode: 'simple', customFieldCount: 2);
    logger.logTicketsGenerated(count: 10, durationMs: 50);
    logger.logBeneficiariesImported(rowCount: 5, errorCount: 1, durationMs: 30);
    logger.logEventArchiveAction(action: 'archive');
    logger.logBackupAction(action: 'export');
    await Future<void>.delayed(_writeSettleDelay);

    final types = (await readLines()).map((l) => l['type']).toList();
    expect(
      types,
      containsAll(<String>[
        'event_created',
        'tickets_generated',
        'beneficiaries_imported',
        'event_archive_action',
        'backup_action',
      ]),
    );
  });

  test('two log calls from the same logger share the same session id', () async {
    final logger = buildLogger();
    logger.logBackupAction(action: 'export');
    logger.logBackupAction(action: 'import');
    await Future<void>.delayed(_writeSettleDelay);

    final lines = await readLines();
    expect(lines, hasLength(2));
    expect(lines[0]['session'], lines[1]['session']);
  });

  test('a fresh logger instance has a different session id', () async {
    final a = buildLogger();
    final b = buildLogger();
    a.logBackupAction(action: 'export');
    b.logBackupAction(action: 'export');
    await Future<void>.delayed(_writeSettleDelay);

    final lines = await readLines();
    expect(lines[0]['session'], isNot(lines[1]['session']));
  });

  test('setEnabled(false) stops future writes without touching the file', () async {
    final logger = buildLogger();
    logger.logBackupAction(action: 'export');
    await Future<void>.delayed(_writeSettleDelay);
    logger.setEnabled(false);
    logger.logBackupAction(action: 'import');
    await Future<void>.delayed(_writeSettleDelay);

    final lines = await readLines();
    expect(lines, hasLength(1));
  });

  test('a write failure does not throw', () async {
    // fileResolver pointing at a path whose parent cannot be created
    // (a file used as a directory segment) simulates a write failure.
    final blocker = File(p.join(tempDir.path, 'blocker'));
    await blocker.writeAsString('x');
    final badFile = File(p.join(blocker.path, 'audit.jsonl'));
    final logger = AuditLogger(enabled: true, fileResolver: () async => badFile);

    expect(
      () => logger.logBackupAction(action: 'export'),
      returnsNormally,
    );
    await Future<void>.delayed(_writeSettleDelay);
  });

  group('init', () {
    test('does nothing when no file exists', () async {
      final logger = buildLogger();
      await logger.init();
      expect(await auditFile.exists(), isFalse);
    });

    test('drops lines older than 12 months and keeps only the most recent 20000', () async {
      final now = DateTime.now();
      final old = now.subtract(const Duration(days: 400));
      final recent = now.subtract(const Duration(days: 1));
      final lines = [
        jsonEncode({'ts': old.toIso8601String(), 'session': 's', 'type': 'backup_action', 'action': 'export'}),
        for (var i = 0; i < 3; i++)
          jsonEncode({'ts': recent.toIso8601String(), 'session': 's', 'type': 'backup_action', 'action': 'export'}),
      ];
      await auditFile.writeAsString('${lines.join('\n')}\n');

      final logger = buildLogger();
      await logger.init();

      final kept = await readLines();
      expect(kept, hasLength(3));
      expect(kept.every((l) => DateTime.parse(l['ts'] as String).isAfter(old)), isTrue);
    });

    test('caps at the most recent 20000 lines even if all are recent', () async {
      final now = DateTime.now();
      final lines = List.generate(
        20005,
        (i) => jsonEncode({'ts': now.toIso8601String(), 'session': 's', 'type': 'backup_action', 'action': 'export'}),
      );
      await auditFile.writeAsString('${lines.join('\n')}\n');

      final logger = buildLogger();
      await logger.init();

      final kept = await auditFile.readAsLines();
      expect(kept.where((l) => l.trim().isNotEmpty), hasLength(AuditLogger.maxLines));
    });
  });
}
