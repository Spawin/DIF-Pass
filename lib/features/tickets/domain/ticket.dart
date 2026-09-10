class Ticket {
  const Ticket({
    required this.id,
    required this.beneficiaryId,
    required this.eventId,
    required this.readableId,
    required this.randomPart,
    required this.qrPayload,
    required this.createdAt,
    this.syncId,
  });

  final int id;
  final int beneficiaryId;
  final int eventId;
  final String readableId;
  final String randomPart;
  final String qrPayload;
  final DateTime createdAt;

  // Stable cross-device id, see check_in.dart
  final String? syncId;
}
