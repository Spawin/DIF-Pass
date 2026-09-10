import 'dart:typed_data';

import 'presence_mode.dart';
import 'ticket_template.dart';

class Event {
  const Event({
    required this.id,
    required this.shortCode,
    required this.name,
    required this.date,
    this.location,
    this.logo,
    required this.presenceMode,
    this.ticketTemplate = TicketTemplate.standard,
    this.archivedAt,
    required this.createdAt,
    this.syncId,
  });

  final int id;
  final String shortCode;
  final String name;
  final DateTime date;
  final String? location;
  final Uint8List? logo;
  final PresenceMode presenceMode;
  final TicketTemplate ticketTemplate;
  final DateTime? archivedAt;
  final DateTime createdAt;

  /// Stable cross-device identifier. Null only for domain objects built
  /// outside a repository (tests); rows read from the database always carry
  /// one. A future merge asserts non-null at its point of use.
  final String? syncId;

  bool get isArchived => archivedAt != null;
}
