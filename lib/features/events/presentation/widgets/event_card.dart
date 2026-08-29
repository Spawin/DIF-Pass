import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/event.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    required this.event,
    required this.onTap,
    required this.onManageBeneficiaries,
    required this.onManageTickets,
    required this.onArchive,
    super.key,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback onManageBeneficiaries;
  final VoidCallback onManageTickets;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final dateLabel = DateFormat.yMMMMd(locale).format(event.date);
    final subtitleParts = [
      dateLabel,
      if (event.location != null && event.location!.trim().isNotEmpty)
        event.location!,
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        title: Text(event.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitleParts.join(' - ')),
        leading: CircleAvatar(
          backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
          backgroundImage: event.logo != null ? MemoryImage(event.logo!) : null,
          child: event.logo == null
              ? const Icon(Icons.event, color: AppColors.indigo)
              : null,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.group_outlined),
              tooltip: l10n.eventsBeneficiariesAction,
              onPressed: onManageBeneficiaries,
            ),
            IconButton(
              icon: const Icon(Icons.confirmation_number_outlined),
              tooltip: l10n.eventsTicketsAction,
              onPressed: onManageTickets,
            ),
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: l10n.eventsArchiveEventAction,
              onPressed: onArchive,
            ),
          ],
        ),
      ),
    );
  }
}
