import 'dart:typed_data';

import '../domain/custom_field.dart';
import '../domain/event.dart';
import '../domain/presence_mode.dart';

abstract class EventRepository {
  Stream<List<Event>> watchActiveEvents();
  Stream<List<Event>> watchArchivedEvents();
  Future<Event> getEvent(int id);
  Stream<List<CustomField>> watchCustomFields(int eventId);

  Future<int> createEvent({
    required String name,
    required DateTime date,
    String? location,
    Uint8List? logo,
    required PresenceMode presenceMode,
    required List<NewCustomField> customFields,
  });

  Future<void> updateEvent(
    int id, {
    required String name,
    required DateTime date,
    String? location,
    Uint8List? logo,
    required PresenceMode presenceMode,
  });

  Future<bool> canEditCustomFields(int eventId);
  Future<void> replaceCustomFields(int eventId, List<NewCustomField> customFields);

  Future<bool> canEditPresenceMode(int eventId);

  Future<void> archiveEvent(int id);
  Future<void> restoreEvent(int id);
  Future<void> deleteEventPermanently(int id);
}
