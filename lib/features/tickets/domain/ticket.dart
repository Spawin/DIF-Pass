class Ticket {
  const Ticket({
    required this.id,
    required this.beneficiaryId,
    required this.eventId,
    required this.readableId,
    required this.randomPart,
    required this.qrPayload,
    required this.createdAt,
  });

  final int id;
  final int beneficiaryId;
  final int eventId;
  final String readableId;
  final String randomPart;
  final String qrPayload;
  final DateTime createdAt;
}
