import 'dart:async';

import 'package:dif_pass/features/tickets/data/ticket_repository.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';

/// In-memory TicketRepository for widget/provider tests. Not shipped in
/// the app, lives under test/ only.
///
/// [beneficiaryIdsForEvent] lets a test say which beneficiary ids exist for
/// a given event, without this fake depending on FakeBeneficiaryRepository's
/// type. Wire it to whatever fake beneficiary repository the same test
/// already constructed, e.g.
/// `(eventId) => fakeBeneficiaries.beneficiaries.where((b) => b.eventId == eventId).map((b) => b.id).toList()`.
///
/// [createBeneficiary], if given, is called once per generic ticket with the
/// name this fake assigns it (`'Ticket <readableId>'`) and must return the
/// new beneficiary's id - wire it directly to a
/// `FakeBeneficiaryRepository`'s own `createBeneficiary`, e.g.
/// `(eventId, name) => fakeBeneficiaries.createBeneficiary(eventId, NewBeneficiary(name: name, customFieldValues: const {}))`.
/// If omitted, generic tickets get a synthetic beneficiary id with no
/// corresponding beneficiary row - fine for tests that only care about the
/// ticket side.
class FakeTicketRepository implements TicketRepository {
  FakeTicketRepository({
    List<Ticket>? tickets,
    List<int> Function(int eventId)? beneficiaryIdsForEvent,
    this._createBeneficiary,
  })  : _tickets = List.of(tickets ?? const []),
        _beneficiaryIdsForEvent = beneficiaryIdsForEvent ?? ((_) => const []);

  final List<Ticket> _tickets;
  final List<int> Function(int eventId) _beneficiaryIdsForEvent;
  final Future<int> Function(int eventId, String name)? _createBeneficiary;
  final Map<int, StreamController<List<Ticket>>> _controllers = {};
  int _nextId = 1000;

  List<Ticket> get tickets => List.unmodifiable(_tickets);

  StreamController<List<Ticket>> _controllerFor(int eventId) {
    return _controllers.putIfAbsent(
      eventId,
      () => StreamController<List<Ticket>>.broadcast(),
    );
  }

  void _emit(int eventId) {
    final list = _tickets.where((t) => t.eventId == eventId).toList()
      ..sort((a, b) => a.readableId.compareTo(b.readableId));
    _controllerFor(eventId).add(list);
  }

  @override
  Stream<List<Ticket>> watchTicketsForEvent(int eventId) {
    Future.microtask(() => _emit(eventId));
    return _controllerFor(eventId).stream;
  }

  @override
  Future<Ticket> getTicket(int id) async =>
      _tickets.firstWhere((t) => t.id == id);

  @override
  Future<int> generateMissingTickets(int eventId) async {
    final beneficiaryIds = _beneficiaryIdsForEvent(eventId);
    final withTickets = _tickets
        .where((t) => t.eventId == eventId)
        .map((t) => t.beneficiaryId)
        .toSet();

    var sequence = _tickets
            .where((t) => t.eventId == eventId)
            .map((t) => int.tryParse(t.readableId) ?? 0)
            .fold<int>(0, (highest, value) => value > highest ? value : highest) +
        1;

    var created = 0;
    for (final beneficiaryId in beneficiaryIds) {
      if (withTickets.contains(beneficiaryId)) continue;
      final readableId = sequence.toString().padLeft(4, '0');
      _tickets.add(Ticket(
        id: _nextId++,
        beneficiaryId: beneficiaryId,
        eventId: eventId,
        readableId: readableId,
        randomPart: 'TEST',
        qrPayload: 'EVT-$readableId-TEST',
        createdAt: DateTime.now(),
      ));
      sequence++;
      created++;
    }
    _emit(eventId);
    return created;
  }

  @override
  Future<int> generateGenericTickets(int eventId, int count) async {
    var sequence = _tickets
            .where((t) => t.eventId == eventId)
            .map((t) => int.tryParse(t.readableId) ?? 0)
            .fold<int>(0, (highest, value) => value > highest ? value : highest) +
        1;

    for (var i = 0; i < count; i++) {
      final readableId = sequence.toString().padLeft(4, '0');
      final beneficiaryId = _createBeneficiary != null
          ? await _createBeneficiary(eventId, 'Ticket $readableId')
          : _nextId;
      _tickets.add(Ticket(
        id: _nextId++,
        beneficiaryId: beneficiaryId,
        eventId: eventId,
        readableId: readableId,
        randomPart: 'TEST',
        qrPayload: 'EVT-$readableId-TEST',
        createdAt: DateTime.now(),
      ));
      sequence++;
    }
    _emit(eventId);
    return count;
  }

  @override
  Future<Ticket?> findTicketForCheckIn(int eventId, String rawInput) async {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return null;

    for (final ticket in _tickets) {
      if (ticket.eventId == eventId && ticket.qrPayload == trimmed) {
        return ticket;
      }
    }
    for (final ticket in _tickets) {
      if (ticket.eventId == eventId &&
          ticket.readableId.toUpperCase() == trimmed.toUpperCase()) {
        return ticket;
      }
    }
    return null;
  }
}
