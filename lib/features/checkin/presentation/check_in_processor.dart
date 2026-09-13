import '../../beneficiaries/data/beneficiary_repository.dart';
import '../../events/domain/presence_mode.dart';
import '../../tickets/data/ticket_repository.dart';
import '../data/check_in_repository.dart';
import '../domain/check_in_outcome.dart';
import 'check_in_feedback.dart';

Future<CheckInFeedback> processCheckIn({
  required TicketRepository ticketRepository,
  required CheckInRepository checkInRepository,
  required BeneficiaryRepository beneficiaryRepository,
  required int eventId,
  required PresenceMode presenceMode,
  required String rawInput,
}) async {
  final ticket = await ticketRepository.findTicketForCheckIn(eventId, rawInput);
  if (ticket == null) {
    return const CheckInFeedbackNotFound();
  }

  final beneficiary =
      await beneficiaryRepository.getBeneficiary(ticket.beneficiaryId);
  final outcome = await checkInRepository.recordCheckIn(ticket, presenceMode);

  return switch (outcome) {
    CheckInRecorded() => CheckInFeedbackRecorded(
        beneficiaryName: beneficiary.name,
        beneficiaryPhoto: beneficiary.photo,
      ),
    CheckInAlreadyRecorded(:final existing) => CheckInFeedbackAlreadyRecorded(
        beneficiaryName: beneficiary.name,
        scannedAt: existing.scannedAt,
        beneficiaryPhoto: beneficiary.photo,
      ),
  };
}
