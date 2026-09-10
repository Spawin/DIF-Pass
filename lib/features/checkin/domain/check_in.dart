class CheckIn {
  const CheckIn({
    required this.id,
    required this.ticketId,
    required this.eventId,
    required this.scannedAt,
    this.syncId,
  });

  final int id;
  final int ticketId;
  final int eventId;
  final DateTime scannedAt;

  /// Stable cross-device identifier. Null only for domain objects built
  /// outside a repository (tests); rows read from the database always carry
  /// one. A future merge asserts non-null at its point of use.
  final String? syncId;
}
