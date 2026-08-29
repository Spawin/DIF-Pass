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
