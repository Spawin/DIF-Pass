import 'dart:async';

import 'package:dif_pass/features/checkin/data/check_in_repository.dart';
import 'package:dif_pass/features/checkin/domain/check_in.dart';
import 'package:dif_pass/features/checkin/domain/check_in_outcome.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';

/// In-memory CheckInRepository for widget/provider tests. Not shipped in
/// the app, lives under test/ only.
class FakeCheckInRepository implements CheckInRepository {
  FakeCheckInRepository({List<CheckIn>? checkIns})
      : _checkIns = List.of(checkIns ?? const []);

  final List<CheckIn> _checkIns;
  final Map<int, StreamController<List<CheckIn>>> _controllers = {};
  int _nextId = 1000;

  List<CheckIn> get checkIns => List.unmodifiable(_checkIns);

  StreamController<List<CheckIn>> _controllerFor(int eventId) {
    return _controllers.putIfAbsent(
      eventId,
      () => StreamController<List<CheckIn>>.broadcast(),
    );
  }

  void _emit(int eventId) {
    final list = _checkIns.where((c) => c.eventId == eventId).toList();
    _controllerFor(eventId).add(list);
  }

  @override
  Stream<List<CheckIn>> watchCheckInsForEvent(int eventId) {
    Future.microtask(() => _emit(eventId));
    return _controllerFor(eventId).stream;
  }

  @override
  Future<CheckInOutcome> recordCheckIn(Ticket ticket, PresenceMode mode) async {
    if (mode == PresenceMode.simple) {
      final existing = _checkIns.where((c) => c.ticketId == ticket.id).toList()
        ..sort((a, b) => a.scannedAt.compareTo(b.scannedAt));
      if (existing.isNotEmpty) {
        return CheckInAlreadyRecorded(existing.first);
      }
    }
    final checkIn = CheckIn(
      id: _nextId++,
      ticketId: ticket.id,
      eventId: ticket.eventId,
      scannedAt: DateTime.now(),
    );
    _checkIns.add(checkIn);
    _emit(ticket.eventId);
    return CheckInRecorded(checkIn);
  }
}
