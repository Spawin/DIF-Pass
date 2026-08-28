import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/beneficiary.dart';

class BeneficiaryListTile extends StatelessWidget {
  const BeneficiaryListTile({
    required this.beneficiary,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Beneficiary beneficiary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        title: Text(beneficiary.name),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: l10n.commonDelete,
          onPressed: onDelete,
        ),
      ),
    );
  }
}
