import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/custom_field.dart';
import '../domain/custom_field_type.dart';
import '../domain/event.dart';
import '../domain/presence_mode.dart';
import '../domain/ticket_template.dart';
import 'event_repository.dart';

class DriftEventRepository implements EventRepository {
  DriftEventRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Event>> watchActiveEvents() {
    final query = _db.select(_db.events)
      ..where((tbl) => tbl.archivedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.date)]);
    return query.watch().map((rows) => rows.map(_toEvent).toList());
  }

  @override
  Stream<List<Event>> watchArchivedEvents() {
    final query = _db.select(_db.events)
      ..where((tbl) => tbl.archivedAt.isNotNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.archivedAt)]);
    return query.watch().map((rows) => rows.map(_toEvent).toList());
  }

  @override
  Future<Event> getEvent(int id) async {
    final row = await (_db.select(_db.events)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
    return _toEvent(row);
  }

  @override
  Stream<List<CustomField>> watchCustomFields(int eventId) {
    final query = _db.select(_db.customFields)
      ..where((tbl) => tbl.eventId.equals(eventId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]);
    return query.watch().map((rows) => rows.map(_toCustomField).toList());
  }

  @override
  Future<int> createEvent({
    required String name,
    required DateTime date,
    String? location,
    Uint8List? logo,
    required PresenceMode presenceMode,
    required List<NewCustomField> customFields,
  }) {
    return _db.transaction(() async {
      final id = await _db.into(_db.events).insert(
            EventsCompanion.insert(
              shortCode: '',
              name: name,
              date: date,
              location: Value(location),
              logo: Value(logo),
              presenceMode: presenceMode.name,
            ),
          );

      await (_db.update(_db.events)..where((tbl) => tbl.id.equals(id)))
          .write(EventsCompanion(shortCode: Value('EVT$id')));

      await _insertCustomFields(id, customFields);

      return id;
    });
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
    await (_db.update(_db.events)..where((tbl) => tbl.id.equals(id))).write(
      EventsCompanion(
        name: Value(name),
        date: Value(date),
        location: Value(location),
        logo: Value(logo),
        presenceMode: Value(presenceMode.name),
      ),
    );
  }

  @override
  Future<bool> canEditCustomFields(int eventId) async {
    final anyTicket = await (_db.select(_db.tickets)
          ..where((tbl) => tbl.eventId.equals(eventId))
          ..limit(1))
        .getSingleOrNull();
    return anyTicket == null;
  }

  @override
  Future<void> replaceCustomFields(
    int eventId,
    List<NewCustomField> customFields,
  ) {
    return _db.transaction(() async {
      await (_db.delete(_db.customFields)
            ..where((tbl) => tbl.eventId.equals(eventId)))
          .go();
      await _insertCustomFields(eventId, customFields);
    });
  }

  @override
  Future<bool> canEditPresenceMode(int eventId) async {
    final anyCheckIn = await (_db.select(_db.checkIns)
          ..where((tbl) => tbl.eventId.equals(eventId))
          ..limit(1))
        .getSingleOrNull();
    return anyCheckIn == null;
  }

  @override
  Future<void> updateTicketTemplate(int eventId, TicketTemplate template) async {
    await (_db.update(_db.events)..where((tbl) => tbl.id.equals(eventId)))
        .write(EventsCompanion(ticketTemplate: Value(template.name)));
  }

  @override
  Future<void> archiveEvent(int id) async {
    await (_db.update(_db.events)..where((tbl) => tbl.id.equals(id)))
        .write(EventsCompanion(archivedAt: Value(DateTime.now())));
  }

  @override
  Future<void> restoreEvent(int id) async {
    await (_db.update(_db.events)..where((tbl) => tbl.id.equals(id)))
        .write(const EventsCompanion(archivedAt: Value(null)));
  }

  @override
  Future<void> deleteEventPermanently(int id) async {
    await (_db.delete(_db.events)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> _insertCustomFields(
    int eventId,
    List<NewCustomField> customFields,
  ) async {
    for (final field in customFields) {
      await _db.into(_db.customFields).insert(
            CustomFieldsCompanion.insert(
              eventId: eventId,
              label: field.label,
              fieldType: field.type.name,
              sortOrder: field.sortOrder,
              showOnTicket: Value(field.showOnTicket),
            ),
          );
    }
  }

  Event _toEvent(EventEntity row) {
    return Event(
      id: row.id,
      shortCode: row.shortCode,
      name: row.name,
      date: row.date,
      location: row.location,
      logo: row.logo,
      presenceMode: PresenceMode.values.byName(row.presenceMode),
      ticketTemplate: TicketTemplate.values.byName(row.ticketTemplate),
      archivedAt: row.archivedAt,
      createdAt: row.createdAt,
      syncId: row.syncId,
    );
  }

  CustomField _toCustomField(CustomFieldEntity row) {
    return CustomField(
      id: row.id,
      eventId: row.eventId,
      label: row.label,
      type: CustomFieldType.values.byName(row.fieldType),
      sortOrder: row.sortOrder,
      showOnTicket: row.showOnTicket,
      syncId: row.syncId,
    );
  }
}
