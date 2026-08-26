import 'dart:async';
import 'dart:typed_data';

import 'package:dif_pass/features/events/data/event_repository.dart';
import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';

/// In-memory EventRepository for widget/provider tests. Not shipped in the
/// app, lives under test/ only.
class FakeEventRepository implements EventRepository {
  FakeEventRepository({List<Event>? events})
      : _events = List.of(events ?? const []);

  final List<Event> _events;
  final Map<int, List<CustomField>> _customFields = {};
  final _activeController = StreamController<List<Event>>.broadcast();
  final _archivedController = StreamController<List<Event>>.broadcast();
  int _nextId = 1000;

  List<Event> get events => List.unmodifiable(_events);

  void _emit() {
    _activeController.add(_events.where((e) => !e.isArchived).toList());
    _archivedController.add(_events.where((e) => e.isArchived).toList());
  }

  @override
  Stream<List<Event>> watchActiveEvents() {
    Future.microtask(_emit);
    return _activeController.stream;
  }

  @override
  Stream<List<Event>> watchArchivedEvents() {
    Future.microtask(_emit);
    return _archivedController.stream;
  }

  @override
  Future<Event> getEvent(int id) async =>
      _events.firstWhere((e) => e.id == id);

  @override
  Stream<List<CustomField>> watchCustomFields(int eventId) async* {
    yield _customFields[eventId] ?? const [];
  }

  @override
  Future<int> createEvent({
    required String name,
    required DateTime date,
    String? location,
    Uint8List? logo,
    required PresenceMode presenceMode,
    required List<NewCustomField> customFields,
  }) async {
    final id = _nextId++;
    _events.add(Event(
      id: id,
      shortCode: 'EVT$id',
      name: name,
      date: date,
      location: location,
      logo: logo,
      presenceMode: presenceMode,
      createdAt: DateTime.now(),
    ));
    _customFields[id] = [
      for (final field in customFields)
        CustomField(
          id: _nextId++,
          eventId: id,
          label: field.label,
          type: field.type,
          sortOrder: field.sortOrder,
          showOnTicket: field.showOnTicket,
        ),
    ];
    _emit();
    return id;
  }

  @override
  Future<void> updateEvent(
    int id, {
    required String name,
    required DateTime date,
    String? location,
    Uint8List? logo,
    required PresenceMode presenceMode,
  }) async {
    final index = _events.indexWhere((e) => e.id == id);
    final existing = _events[index];
    _events[index] = Event(
      id: existing.id,
      shortCode: existing.shortCode,
      name: name,
      date: date,
      location: location,
      logo: logo,
      presenceMode: presenceMode,
      archivedAt: existing.archivedAt,
      createdAt: existing.createdAt,
    );
    _emit();
  }

  @override
  Future<bool> canEditCustomFields(int eventId) async => true;

  @override
  Future<void> replaceCustomFields(
    int eventId,
    List<NewCustomField> customFields,
  ) async {
    _customFields[eventId] = [
      for (final field in customFields)
        CustomField(
          id: _nextId++,
          eventId: eventId,
          label: field.label,
          type: field.type,
          sortOrder: field.sortOrder,
          showOnTicket: field.showOnTicket,
        ),
    ];
  }

  @override
  Future<bool> canEditPresenceMode(int eventId) async => true;

  @override
  Future<void> archiveEvent(int id) async {
    final index = _events.indexWhere((e) => e.id == id);
    final existing = _events[index];
    _events[index] = Event(
      id: existing.id,
      shortCode: existing.shortCode,
      name: existing.name,
      date: existing.date,
      location: existing.location,
      logo: existing.logo,
      presenceMode: existing.presenceMode,
      archivedAt: DateTime.now(),
      createdAt: existing.createdAt,
    );
    _emit();
  }

  @override
  Future<void> restoreEvent(int id) async {
    final index = _events.indexWhere((e) => e.id == id);
    final existing = _events[index];
    _events[index] = Event(
      id: existing.id,
      shortCode: existing.shortCode,
      name: existing.name,
      date: existing.date,
      location: existing.location,
      logo: existing.logo,
      presenceMode: existing.presenceMode,
      createdAt: existing.createdAt,
    );
    _emit();
  }

  @override
  Future<void> deleteEventPermanently(int id) async {
    _events.removeWhere((e) => e.id == id);
    _customFields.remove(id);
    _emit();
  }
}
