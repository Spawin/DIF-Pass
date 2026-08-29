import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../beneficiaries/presentation/providers/beneficiary_providers.dart';
import '../../../events/domain/ticket_template.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../providers/ticket_providers.dart';

class TicketPreviewScreen extends ConsumerWidget {
  const TicketPreviewScreen({required this.ticketId, super.key});

  final int ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ticketAsync = ref.watch(ticketProvider(ticketId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ticketPreviewTitle)),
      body: ticketAsync.when(
        data: (ticket) {
          final beneficiaryAsync = ref.watch(
            beneficiaryProvider(ticket.beneficiaryId),
          );
          final eventAsync = ref.watch(eventProvider(ticket.eventId));
          final customFieldsAsync = ref.watch(
            customFieldsProvider(ticket.eventId),
          );

          if (!beneficiaryAsync.hasValue ||
              !eventAsync.hasValue ||
              !customFieldsAsync.hasValue) {
            if (beneficiaryAsync.hasError ||
                eventAsync.hasError ||
                customFieldsAsync.hasError) {
              return Center(child: Text(l10n.ticketsLoadError));
            }
            return const Center(child: CircularProgressIndicator());
          }

          final beneficiary = beneficiaryAsync.value!;
          final event = eventAsync.value!;
          final visibleFields = customFieldsAsync.value!
              .where((f) => f.showOnTicket)
              .toList();

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _TicketCard(
                template: event.ticketTemplate,
                eventName: event.name,
                eventLogo: event.logo,
                beneficiaryName: beneficiary.name,
                readableId: ticket.readableId,
                qrPayload: ticket.qrPayload,
                visibleFieldLines: [
                  for (final field in visibleFields)
                    if (beneficiary.customFieldValues[field.id] != null)
                      '${field.label}: ${beneficiary.customFieldValues[field.id]}',
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.ticketsLoadError)),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.template,
    required this.eventName,
    this.eventLogo,
    required this.beneficiaryName,
    required this.readableId,
    required this.qrPayload,
    required this.visibleFieldLines,
  });

  final TicketTemplate template;
  final String eventName;
  final Uint8List? eventLogo;
  final String beneficiaryName;
  final String readableId;
  final String qrPayload;
  final List<String> visibleFieldLines;

  @override
  Widget build(BuildContext context) {
    final isElegant = template == TicketTemplate.elegant;
    final isCompact = template == TicketTemplate.compact;

    return Card(
      color: isElegant ? AppColors.indigo.withValues(alpha: 0.05) : null,
      shape: isElegant
          ? RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.indigo, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (eventLogo != null) ...[
              Image.memory(eventLogo!, height: isCompact ? 24 : 40),
              SizedBox(height: isCompact ? 4 : 8),
            ],
            Text(eventName, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: isCompact ? 8 : 16),
            QrImageView(data: qrPayload, size: isCompact ? 120 : 180),
            SizedBox(height: isCompact ? 8 : 16),
            Text(
              beneficiaryName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              readableId,
              style: ticketMonoStyle(Theme.of(context).colorScheme),
            ),
            for (final line in visibleFieldLines) ...[
              const SizedBox(height: 4),
              Text(line),
            ],
          ],
        ),
      ),
    );
  }
}
