import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../events/domain/custom_field.dart';
import '../../domain/beneficiary.dart';
import '../providers/beneficiary_providers.dart';

class BeneficiaryListTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final preview = customFields
        .map((field) => beneficiary.customFieldValues[field.id])
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' - ');
    final photo =
        ref.watch(beneficiaryPhotoProvider(beneficiary.id)).valueOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
          backgroundImage: photo != null ? MemoryImage(photo) : null,
          child: photo == null
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
