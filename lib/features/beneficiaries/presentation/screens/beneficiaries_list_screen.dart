import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/beneficiary.dart';
import '../providers/beneficiary_providers.dart';
import '../widgets/beneficiary_list_tile.dart';

class BeneficiariesListScreen extends ConsumerWidget {
  const BeneficiariesListScreen({required this.eventId, super.key});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final beneficiariesAsync = ref.watch(beneficiariesProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.beneficiariesListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: l10n.beneficiariesImportAction,
            onPressed: () => context.push('/events/$eventId/beneficiaries/import'),
          ),
        ],
      ),
      body: beneficiariesAsync.when(
        data: (beneficiaries) {
          if (beneficiaries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.beneficiariesEmptyState,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: beneficiaries.length,
            itemBuilder: (context, index) {
              final beneficiary = beneficiaries[index];
              return BeneficiaryListTile(
                beneficiary: beneficiary,
                onTap: () => context
                    .push('/events/$eventId/beneficiaries/${beneficiary.id}/edit'),
                onDelete: () => _confirmDelete(context, ref, beneficiary),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.beneficiariesLoadError)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/events/$eventId/beneficiaries/new'),
        icon: const Icon(Icons.person_add_outlined),
        label: Text(l10n.beneficiariesNewAction),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Beneficiary beneficiary,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(beneficiaryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.beneficiariesDeleteConfirmTitle),
        content: Text(l10n.eventsDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await repository.deleteBeneficiary(beneficiary.id);
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
