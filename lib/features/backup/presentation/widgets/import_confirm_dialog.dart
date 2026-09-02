import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

Future<bool> showImportConfirmDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.settingsImportConfirmTitle),
      content: Text(l10n.settingsImportConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.settingsImportAction),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
