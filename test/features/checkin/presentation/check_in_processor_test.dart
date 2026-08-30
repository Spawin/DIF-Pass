import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/checkin/presentation/check_in_feedback.dart';
import 'package:dif_pass/features/checkin/presentation/check_in_processor.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../beneficiaries/fake_beneficiary_repository.dart';
import '../../tickets/fake_ticket_repository.dart';
import '../fake_check_in_repository.dart';

void main() {
  final ticket = Ticket(
    id: 1,
    beneficiaryId: 1,
    eventId: 42,
    readableId: '0001',
    randomPart: 'ABCD',
    qrPayload: 'EVT-0001-ABCD',
    createdAt: DateTime(2026, 1, 1),
  );
  final beneficiary = Beneficiary(
    id: 1,
    eventId: 42,
    name: 'Jane Doe',
    customFieldValues: const {},
    createdAt: DateTime(2026, 1, 1),
  );

  test('returns CheckInFeedbackNotFound when no ticket matches', () async {
    final feedback = await processCheckIn(
      ticketRepository: FakeTicketRepository(),
      checkInRepository: FakeCheckInRepository(),
      beneficiaryRepository: FakeBeneficiaryRepository(),
      eventId: 42,
      presenceMode: PresenceMode.simple,
      rawInput: 'nope',
    );

    expect(feedback, isA<CheckInFeedbackNotFound>());
  });

  test(
    'returns CheckInFeedbackRecorded with the beneficiary name on a fresh scan',
    () async {
      final feedback = await processCheckIn(
        ticketRepository: FakeTicketRepository(tickets: [ticket]),
        checkInRepository: FakeCheckInRepository(),
        beneficiaryRepository: FakeBeneficiaryRepository(beneficiaries: [beneficiary]),
        eventId: 42,
        presenceMode: PresenceMode.simple,
        rawInput: ticket.qrPayload,
      );

      expect(feedback, isA<CheckInFeedbackRecorded>());
      expect((feedback as CheckInFeedbackRecorded).beneficiaryName, 'Jane Doe');
    },
  );

  test(
    'returns CheckInFeedbackAlreadyRecorded with the first scan time in simple mode',
    () async {
      final fakeCheckIns = FakeCheckInRepository();
      final ticketRepo = FakeTicketRepository(tickets: [ticket]);
      final beneficiaryRepo =
          FakeBeneficiaryRepository(beneficiaries: [beneficiary]);
      await processCheckIn(
        ticketRepository: ticketRepo,
        checkInRepository: fakeCheckIns,
        beneficiaryRepository: beneficiaryRepo,
        eventId: 42,
        presenceMode: PresenceMode.simple,
        rawInput: ticket.qrPayload,
      );

      final firstScannedAt = fakeCheckIns.checkIns.first.scannedAt;

      final feedback = await processCheckIn(
        ticketRepository: ticketRepo,
        checkInRepository: fakeCheckIns,
        beneficiaryRepository: beneficiaryRepo,
        eventId: 42,
        presenceMode: PresenceMode.simple,
        rawInput: ticket.readableId,
      );

      expect(feedback, isA<CheckInFeedbackAlreadyRecorded>());
      expect((feedback as CheckInFeedbackAlreadyRecorded).beneficiaryName, 'Jane Doe');
      expect(feedback.scannedAt, firstScannedAt);
    },
  );

  test('multiple mode: repeated scans each return CheckInFeedbackRecorded', () async {
    final fakeCheckIns = FakeCheckInRepository();
    final ticketRepo = FakeTicketRepository(tickets: [ticket]);
    final beneficiaryRepo = FakeBeneficiaryRepository(beneficiaries: [beneficiary]);

    final first = await processCheckIn(
      ticketRepository: ticketRepo,
      checkInRepository: fakeCheckIns,
      beneficiaryRepository: beneficiaryRepo,
      eventId: 42,
      presenceMode: PresenceMode.multiple,
      rawInput: ticket.qrPayload,
    );
    final second = await processCheckIn(
      ticketRepository: ticketRepo,
      checkInRepository: fakeCheckIns,
      beneficiaryRepository: beneficiaryRepo,
      eventId: 42,
      presenceMode: PresenceMode.multiple,
      rawInput: ticket.qrPayload,
    );

    expect(first, isA<CheckInFeedbackRecorded>());
    expect(second, isA<CheckInFeedbackRecorded>());
  });
}
