sealed class CheckInFeedback {
  const CheckInFeedback();
}

class CheckInFeedbackRecorded extends CheckInFeedback {
  const CheckInFeedbackRecorded({required this.beneficiaryName});

  final String beneficiaryName;
}

class CheckInFeedbackAlreadyRecorded extends CheckInFeedback {
  const CheckInFeedbackAlreadyRecorded({
    required this.beneficiaryName,
    required this.scannedAt,
  });

  final String beneficiaryName;
  final DateTime scannedAt;
}

class CheckInFeedbackNotFound extends CheckInFeedback {
  const CheckInFeedbackNotFound();
}

// Whether this feedback should close itself automatically after a delay
// (the success case, to keep an entrance queue moving) or wait for an
// explicit tap (the two exception cases, which need the agent's attention).
bool checkInFeedbackAutoDismisses(CheckInFeedback feedback) =>
    feedback is CheckInFeedbackRecorded;
