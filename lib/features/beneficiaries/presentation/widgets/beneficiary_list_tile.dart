import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../events/domain/custom_field.dart';
import '../../domain/beneficiary.dart';

class BeneficiaryListTile extends StatelessWidget {
  const BeneficiaryListTile({
    required this.beneficiary,
    required this.customFields,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Beneficiary beneficiary;
  final List<CustomField> customFields;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preview = customFields
        .map((field) => beneficiary.customFieldValues[field.id])
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' - ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
          backgroundImage:
              beneficiary.photo != null ? MemoryImage(beneficiary.photo!) : null,
          child: beneficiary.photo == null
              ? const Icon(Icons.person_outline, color: AppColors.indigo)
              : null,
        ),
        title: Text(
          beneficiary.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: preview.isEmpty ? null : Text(preview),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: l10n.commonDelete,
          onPressed: onDelete,
        ),
      ),
    );
  }
}
