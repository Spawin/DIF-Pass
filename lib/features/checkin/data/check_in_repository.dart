import '../../events/domain/presence_mode.dart';
import '../../tickets/domain/ticket.dart';
import '../domain/check_in.dart';
import '../domain/check_in_outcome.dart';

abstract class CheckInRepository {
  Stream<List<CheckIn>> watchCheckInsForEvent(int eventId);
  Future<CheckInOutcome> recordCheckIn(Ticket ticket, PresenceMode mode);
}
