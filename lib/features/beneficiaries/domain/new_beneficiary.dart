class NewBeneficiary {
  const NewBeneficiary({
    required this.name,
    required this.customFieldValues,
  });

  final String name;
  final Map<int, String> customFieldValues;
}
