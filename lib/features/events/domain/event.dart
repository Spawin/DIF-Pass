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

  bool get isArchived => archivedAt != null;
}
