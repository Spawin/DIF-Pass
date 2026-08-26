import 'custom_field_type.dart';

class CustomField {
  const CustomField({
    required this.id,
    required this.eventId,
    required this.label,
    required this.type,
    required this.sortOrder,
    required this.showOnTicket,
  });

  final int id;
  final int eventId;
  final String label;
  final CustomFieldType type;
  final int sortOrder;
  final bool showOnTicket;
}

class NewCustomField {
  const NewCustomField({
    required this.label,
    required this.type,
    required this.sortOrder,
    this.showOnTicket = false,
  });

  final String label;
  final CustomFieldType type;
  final int sortOrder;
  final bool showOnTicket;

  @override
  bool operator ==(Object other) {
    return other is NewCustomField &&
        other.label == label &&
        other.type == type &&
        other.sortOrder == sortOrder &&
        other.showOnTicket == showOnTicket;
  }

  @override
  int get hashCode => Object.hash(label, type, sortOrder, showOnTicket);
}
