import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/drift_ticket_repository.dart';
import '../../data/ticket_repository.dart';
import '../../domain/ticket.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftTicketRepository(db);
});

final ticketsProvider = StreamProvider.family<List<Ticket>, int>((ref, eventId) {
  return ref.watch(ticketRepositoryProvider).watchTicketsForEvent(eventId);
});

final ticketProvider = FutureProvider.autoDispose.family<Ticket, int>((ref, id) {
  return ref.watch(ticketRepositoryProvider).getTicket(id);
});
