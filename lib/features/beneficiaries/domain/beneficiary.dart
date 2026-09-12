import 'dart:typed_data';

class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.eventId,
    required this.name,
    required this.customFieldValues,
    required this.createdAt,
    this.syncId,
    this.photo,
  });

  final int id;
  final int eventId;
  final String name;
  final Map<int, String> customFieldValues;
  final DateTime createdAt;

  // Stable cross-device id, see check_in.dart
  final String? syncId;

  // Optional identification photo, shown on the form, the list, the ticket,
  // and the check-in confirmation. Never required.
  final Uint8List? photo;
}
