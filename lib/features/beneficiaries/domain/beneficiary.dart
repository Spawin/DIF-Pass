class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.eventId,
    required this.name,
    required this.customFieldValues,
    required this.createdAt,
    this.syncId,
  });

  final int id;
  final int eventId;
  final String name;
  final Map<int, String> customFieldValues;
  final DateTime createdAt;

  // Stable cross-device id, see check_in.dart
  final String? syncId;
}
