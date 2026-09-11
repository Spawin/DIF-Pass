import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../core/audit/audit_providers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../beneficiaries/domain/beneficiary.dart';
import '../../../beneficiaries/presentation/providers/beneficiary_providers.dart';
import '../../../checkin/presentation/providers/check_in_providers.dart';
import '../../../events/domain/custom_field.dart';
import '../../../events/domain/event.dart';
import '../../../events/domain/presence_mode.dart';
import '../../../events/domain/ticket_template.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../data/ticket_pdf_builder.dart';
import '../../domain/ticket.dart';
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
    final customFieldsAsync = ref.watch(customFieldsProvider(eventId));
    final checkInsAsync = ref.watch(checkInsProvider(eventId));

    final event = eventAsync.valueOrNull;
    final beneficiaries = beneficiariesAsync.valueOrNull ?? const [];
    final tickets = ticketsAsync.valueOrNull ?? const [];
    final canGenerate = beneficiaries.length > tickets.length;
    final customFields = customFieldsAsync.valueOrNull ?? const [];
    final beneficiariesById = {
      for (final beneficiary in beneficiaries) beneficiary.id: beneficiary,
    };
    final canExport = event != null &&
        tickets.isNotEmpty &&
        beneficiariesAsync.hasValue &&
        customFieldsAsync.hasValue;

    return Scaffold(
      appBar: AppBar(
        title: eventAsync.when(
          data: (event) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.ticketsScreenTitle),
              Text(event.name, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          loading: () => Text(l10n.ticketsScreenTitle),
          error: (_, _) => Text(l10n.ticketsScreenTitle),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: l10n.ticketsExportAction,
            onPressed: canExport
                ? () => _exportAllTickets(
                      context,
                      event,
                      tickets,
                      beneficiariesById,
                      customFields,
                    )
                : null,
          ),
        ],
      ),
      body: eventAsync.hasError ||
              beneficiariesAsync.hasError ||
              customFieldsAsync.hasError
          ? ErrorState(
              message: l10n.ticketsLoadError,
              onRetry: () {
                ref.invalidate(eventProvider(eventId));
                ref.invalidate(beneficiariesProvider(eventId));
                ref.invalidate(customFieldsProvider(eventId));
              },
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.ticketsTemplateLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
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
                          ref.invalidate(eventProvider(eventId));
                        } catch (e) {
                          if (!context.mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.ticketsTemplateUpdateError)),
                          );
                        }
                      },
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: canGenerate
                        ? () => _confirmGenerate(context, ref)
                        : null,
                    icon: const Icon(Icons.confirmation_number_outlined),
                    label: Text(l10n.ticketsGenerateAction),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ticketsAsync.when(
                      data: (tickets) {
                        if (tickets.isEmpty) {
                          return EmptyState(
                            icon: Icons.confirmation_number_outlined,
                            message: l10n.ticketsEmptyState,
                          );
                        }
                        final beneficiaryNames = {
                          for (final beneficiary in beneficiaries)
                            beneficiary.id: beneficiary.name,
                        };
                        final passageCountByTicketId = <int, int>{};
                        for (final checkIn in checkInsAsync.valueOrNull ?? const []) {
                          passageCountByTicketId[checkIn.ticketId] =
                              (passageCountByTicketId[checkIn.ticketId] ?? 0) + 1;
                        }
                        return ListView.builder(
                          itemCount: tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  beneficiaryNames[ticket.beneficiaryId] ?? '',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                subtitle: Text(
                                  ticket.readableId,
                                  style: ticketMonoStyle(
                                    Theme.of(context).colorScheme,
                                  ).copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                trailing: () {
                                  final count = passageCountByTicketId[ticket.id] ?? 0;
                                  if (count == 0) return null;
                                  final label = event?.presenceMode == PresenceMode.multiple
                                      ? l10n.ticketsCheckInCount(count)
                                      : l10n.ticketsCheckedInBadge;
                                  return Chip(label: Text(label));
                                }(),
                                onTap: () => context.push(
                                  '/events/$eventId/tickets/${ticket.id}',
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => ErrorState(
                        message: l10n.ticketsLoadError,
                        onRetry: () => ref.invalidate(ticketsProvider(eventId)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _confirmGenerate(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    // Read before the awaits below: ref.read() throws if the widget backing
    // it has since been disposed (e.g. the user navigated away while
    // generation was running), and an audit-log read must never be why the
    // success path reports failure.
    final auditLogger = ref.read(auditLoggerProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.ticketsGenerateConfirmTitle),
        content: Text(l10n.ticketsGenerateConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.ticketsGenerateAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final stopwatch = Stopwatch()..start();
      final created = await ref
          .read(ticketRepositoryProvider)
          .generateMissingTickets(eventId);
      stopwatch.stop();
      auditLogger.logTicketsGenerated(
        count: created,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ticketsGeneratedCount(created))),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.ticketsGenerateError)));
    }
  }

  Future<void> _exportAllTickets(
    BuildContext context,
    Event event,
    List<Ticket> tickets,
    Map<int, Beneficiary> beneficiariesById,
    List<CustomField> customFields,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await buildEventTicketsPdf(
        event: event,
        tickets: tickets,
        beneficiariesById: beneficiariesById,
        customFields: customFields,
      );
      final success = await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'tickets-${event.shortCode}',
      );
      if (!context.mounted || !success) return;
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ticketsExportSuccess)),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.ticketsExportError)));
    }
  }
}
