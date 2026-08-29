class CheckIn {
  const CheckIn({
    required this.id,
    required this.ticketId,
    required this.eventId,
    required this.scannedAt,
  });

  final int id;
  final int ticketId;
  final int eventId;
  final DateTime scannedAt;
}
