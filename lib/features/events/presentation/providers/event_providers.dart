import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/drift_event_repository.dart';
import '../../data/event_repository.dart';
import '../../domain/custom_field.dart';
import '../../domain/event.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftEventRepository(db);
});

final activeEventsProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchActiveEvents();
});

final archivedEventsProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchArchivedEvents();
});

final eventProvider = FutureProvider.family<Event, int>((ref, id) {
  return ref.watch(eventRepositoryProvider).getEvent(id);
});

final customFieldsProvider =
    StreamProvider.family<List<CustomField>, int>((ref, eventId) {
  return ref.watch(eventRepositoryProvider).watchCustomFields(eventId);
});
