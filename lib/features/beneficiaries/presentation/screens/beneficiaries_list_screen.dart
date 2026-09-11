import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../tickets/presentation/providers/ticket_providers.dart';
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
    final eventAsync = ref.watch(eventProvider(eventId));
    final customFieldsAsync = ref.watch(customFieldsProvider(eventId));
    final ticketsAsync = ref.watch(ticketsProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: eventAsync.when(
          data: (event) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.beneficiariesListTitle),
              Text(
                event.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          loading: () => Text(l10n.beneficiariesListTitle),
          error: (_, _) => Text(l10n.beneficiariesListTitle),
        ),
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
            return EmptyState(
              icon: Icons.people_outline,
              message: l10n.beneficiariesEmptyState,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: beneficiaries.length,
            itemBuilder: (context, index) {
              final beneficiary = beneficiaries[index];
              return BeneficiaryListTile(
                beneficiary: beneficiary,
                customFields: customFieldsAsync.valueOrNull ?? const [],
                onTap: () => context
                    .push('/events/$eventId/beneficiaries/${beneficiary.id}/edit'),
                onDelete: () => _confirmDelete(
                  context,
                  ref,
                  beneficiary,
                  (ticketsAsync.valueOrNull ?? const [])
                      .any((t) => t.beneficiaryId == beneficiary.id),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorState(
          message: l10n.beneficiariesLoadError,
          onRetry: () => ref.invalidate(beneficiariesProvider(eventId)),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/events/$eventId/beneficiaries/new'),
          icon: const Icon(Icons.person_add_outlined),
          label: Text(l10n.beneficiariesNewAction),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Beneficiary beneficiary,
    bool hasTicket,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(beneficiaryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.beneficiariesDeleteConfirmTitle),
        content: Text(
          hasTicket
              ? l10n.beneficiariesDeleteConfirmBodyWithTicket
              : l10n.eventsDeleteConfirmBody,
        ),
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
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.beneficiariesDeleteError)),
        );
      }
    }
  }
}
