import 'dart:typed_data';

sealed class CheckInFeedback {
  const CheckInFeedback();
}

class CheckInFeedbackRecorded extends CheckInFeedback {
  const CheckInFeedbackRecorded({
    required this.beneficiaryName,
    this.beneficiaryPhoto,
  });

  final String beneficiaryName;
  final Uint8List? beneficiaryPhoto;
}

class CheckInFeedbackAlreadyRecorded extends CheckInFeedback {
  const CheckInFeedbackAlreadyRecorded({
    required this.beneficiaryName,
    required this.scannedAt,
    this.beneficiaryPhoto,
  });

  final String beneficiaryName;
  final DateTime scannedAt;
  final Uint8List? beneficiaryPhoto;
}

class CheckInFeedbackNotFound extends CheckInFeedback {
  const CheckInFeedbackNotFound();
}

// Whether this feedback should close itself automatically after a delay
// (the success case, to keep an entrance queue moving) or wait for an
// explicit tap (the two exception cases, which need the agent's attention).
bool checkInFeedbackAutoDismisses(CheckInFeedback feedback) =>
    feedback is CheckInFeedbackRecorded;

/// Maps a feedback outcome to the audit log's `result` field. Pure and
/// side-effect free so it is unit-testable without any screen or camera.
String checkInFeedbackResultLabel(CheckInFeedback feedback) {
  return switch (feedback) {
    CheckInFeedbackRecorded() => 'new',
    CheckInFeedbackAlreadyRecorded() => 'already',
    CheckInFeedbackNotFound() => 'not_found',
  };
}
