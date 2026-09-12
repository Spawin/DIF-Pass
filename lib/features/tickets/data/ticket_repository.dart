import '../domain/ticket.dart';

abstract class TicketRepository {
  Stream<List<Ticket>> watchTicketsForEvent(int eventId);
  Future<Ticket> getTicket(int id);
  Future<int> generateMissingTickets(int eventId);
  Future<int> generateGenericTickets(int eventId, int count);
  Future<Ticket?> findTicketForCheckIn(int eventId, String rawInput);
}
