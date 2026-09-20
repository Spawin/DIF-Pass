import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../beneficiaries/presentation/providers/beneficiary_providers.dart';
import '../../../events/domain/ticket_template.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../data/ticket_pdf_builder.dart';
import '../../domain/ticket.dart';
import '../providers/ticket_providers.dart';

class TicketPreviewScreen extends ConsumerWidget {
  const TicketPreviewScreen({required this.ticketId, super.key});

  final int ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ticketAsync = ref.watch(ticketProvider(ticketId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ticketPreviewTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: l10n.ticketPreviewShareAction,
            onPressed: ticketAsync.hasValue
                ? () => _shareTicket(context, ref, ticketAsync.value!)
                : null,
          ),
        ],
      ),
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
              return ErrorState(
                message: l10n.ticketsLoadError,
                onRetry: () {
                  ref.invalidate(beneficiaryProvider(ticket.beneficiaryId));
                  ref.invalidate(eventProvider(ticket.eventId));
                  ref.invalidate(customFieldsProvider(ticket.eventId));
                },
              );
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
                beneficiaryPhoto: beneficiary.photo,
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
        error: (error, stack) => ErrorState(
          message: l10n.ticketsLoadError,
          onRetry: () => ref.invalidate(ticketProvider(ticketId)),
        ),
      ),
    );
  }

  Future<void> _shareTicket(
    BuildContext context,
    WidgetRef ref,
    Ticket ticket,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final beneficiary = await ref.read(
        beneficiaryProvider(ticket.beneficiaryId).future,
      );
      final event = await ref.read(eventProvider(ticket.eventId).future);
      final customFields = await ref.read(
        customFieldsProvider(ticket.eventId).future,
      );
      final bytes = await buildSingleTicketPdf(
        event: event,
        ticket: ticket,
        beneficiary: beneficiary,
        customFields: customFields,
        generatedByLabel: l10n.ticketPreviewGeneratedByLabel,
        appName: l10n.appTitle,
      );
      final shared = await Printing.sharePdf(
        bytes: bytes,
        filename: '${ticket.readableId}.pdf',
      );
      if (!context.mounted || !shared) return;
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ticketPreviewShareSuccess)),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ticketPreviewShareError)),
      );
    }
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.template,
    required this.eventName,
    this.eventLogo,
    required this.beneficiaryName,
    this.beneficiaryPhoto,
    required this.readableId,
    required this.qrPayload,
    required this.visibleFieldLines,
  });

  final TicketTemplate template;
  final String eventName;
  final Uint8List? eventLogo;
  final String beneficiaryName;
  final Uint8List? beneficiaryPhoto;
  final String readableId;
  final String qrPayload;
  final List<String> visibleFieldLines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isElegant = template == TicketTemplate.elegant;
    final isCompact = template == TicketTemplate.compact;
    final qrSize = isCompact ? 120.0 : 180.0;
    final frameBorderWidth = isCompact ? 2.0 : 3.0;
    final frameRadius = isCompact ? 12.0 : 16.0;
    final badgeSize = isCompact ? 24.0 : 32.0;
    final badgeOffset = isCompact ? -8.0 : -12.0;

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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 6 : 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.indigo,
                      width: frameBorderWidth,
                    ),
                    borderRadius: BorderRadius.circular(frameRadius),
                  ),
                  child: QrImageView(data: qrPayload, size: qrSize),
                ),
                Positioned(
                  top: badgeOffset,
                  right: badgeOffset,
                  child: Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isCompact ? 7 : 9),
                      image: const DecorationImage(
                        image: AssetImage('assets/brand/icone_seule.png'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 8 : 16),
            if (beneficiaryPhoto != null) ...[
              CircleAvatar(
                backgroundImage: MemoryImage(beneficiaryPhoto!),
                radius: isCompact ? 16 : 24,
              ),
              SizedBox(height: isCompact ? 4 : 8),
            ],
            Text(
              beneficiaryName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              readableId,
              style: ticketMonoStyle(Theme.of(context).colorScheme),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.ink.withValues(alpha: 0.45),
                  ),
                  children: [
                    TextSpan(text: '${l10n.ticketPreviewGeneratedByLabel} '),
                    TextSpan(
                      text: l10n.appTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
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
