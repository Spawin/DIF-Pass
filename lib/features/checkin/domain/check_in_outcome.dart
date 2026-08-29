import 'check_in.dart';

sealed class CheckInOutcome {
  const CheckInOutcome();
}

class CheckInRecorded extends CheckInOutcome {
  const CheckInRecorded(this.checkIn);

  final CheckIn checkIn;
}

class CheckInAlreadyRecorded extends CheckInOutcome {
  const CheckInAlreadyRecorded(this.existing);

  final CheckIn existing;
}
