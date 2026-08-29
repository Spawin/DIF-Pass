import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../beneficiaries/presentation/providers/beneficiary_providers.dart';
import '../../../events/domain/ticket_template.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../providers/ticket_providers.dart';

class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({required this.eventId, super.key});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final eventAsync = ref.watch(eventProvider(eventId));
    final beneficiariesAsync = ref.watch(beneficiariesProvider(eventId));
    final ticketsAsync = ref.watch(ticketsProvider(eventId));

    final event = eventAsync.valueOrNull;
    final beneficiaries = beneficiariesAsync.valueOrNull ?? const [];
    final tickets = ticketsAsync.valueOrNull ?? const [];
    final canGenerate = beneficiaries.length > tickets.length;

    return Scaffold(
      appBar: AppBar(
        title: event == null
            ? Text(l10n.ticketsScreenTitle)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.ticketsScreenTitle),
                  Text(event.name, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.ticketsTemplateLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (event != null)
              SegmentedButton<TicketTemplate>(
                segments: [
                  ButtonSegment(
                    value: TicketTemplate.compact,
                    label: Text(l10n.ticketsTemplateCompact),
                  ),
                  ButtonSegment(
                    value: TicketTemplate.standard,
                    label: Text(l10n.ticketsTemplateStandard),
                  ),
                  ButtonSegment(
                    value: TicketTemplate.elegant,
                    label: Text(l10n.ticketsTemplateElegant),
                  ),
                ],
                selected: {event.ticketTemplate},
                onSelectionChanged: (selection) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(eventRepositoryProvider)
                        .updateTicketTemplate(eventId, selection.first);
                  } catch (e) {
                    if (!context.mounted) return;
                    messenger.showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: canGenerate
                  ? () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref
                            .read(ticketRepositoryProvider)
                            .generateMissingTickets(eventId);
                      } catch (e) {
                        if (!context.mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  : null,
              icon: const Icon(Icons.confirmation_number_outlined),
              label: Text(l10n.ticketsGenerateAction),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ticketsAsync.when(
                data: (tickets) {
                  if (tickets.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.ticketsEmptyState,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }
                  final beneficiaryNames = {
                    for (final beneficiary in beneficiaries) beneficiary.id: beneficiary.name,
                  };
                  return ListView.builder(
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(beneficiaryNames[ticket.beneficiaryId] ?? ''),
                          subtitle: Text(ticket.readableId),
                          onTap: () =>
                              context.push('/events/$eventId/tickets/${ticket.id}'),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text(l10n.ticketsLoadError)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
