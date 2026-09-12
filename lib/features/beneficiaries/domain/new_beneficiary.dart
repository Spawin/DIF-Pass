import 'dart:typed_data';

class NewBeneficiary {
  const NewBeneficiary({
    required this.name,
    required this.customFieldValues,
    this.photo,
  });

  final String name;
  final Map<int, String> customFieldValues;
  final Uint8List? photo;
}
