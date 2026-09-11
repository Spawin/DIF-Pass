import 'package:dif_pass/features/checkin/presentation/check_in_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('checkInFeedbackAutoDismisses', () {
    test('true for a recorded check-in', () {
      const feedback = CheckInFeedbackRecorded(beneficiaryName: 'Jane Doe');

      expect(checkInFeedbackAutoDismisses(feedback), isTrue);
    });

    test('false for an already-recorded check-in', () {
      final feedback = CheckInFeedbackAlreadyRecorded(
        beneficiaryName: 'Jane Doe',
        scannedAt: DateTime(2026, 1, 1),
      );

      expect(checkInFeedbackAutoDismisses(feedback), isFalse);
    });

    test('false when the ticket is not found', () {
      const feedback = CheckInFeedbackNotFound();

      expect(checkInFeedbackAutoDismisses(feedback), isFalse);
    });
  });

  group('checkInFeedbackResultLabel', () {
    test('maps each feedback variant to its audit result label', () {
      expect(
        checkInFeedbackResultLabel(
          const CheckInFeedbackRecorded(beneficiaryName: 'Jane Doe'),
        ),
        'new',
      );
      expect(
        checkInFeedbackResultLabel(
          CheckInFeedbackAlreadyRecorded(
            beneficiaryName: 'Jane Doe',
            scannedAt: DateTime(2026, 1, 1),
          ),
        ),
        'already',
      );
      expect(
        checkInFeedbackResultLabel(const CheckInFeedbackNotFound()),
        'not_found',
      );
    });
  });
}
