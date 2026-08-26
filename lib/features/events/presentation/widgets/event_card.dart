import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/event.dart';

class EventCard extends StatelessWidget {
  const EventCard({required this.event, required this.onTap, super.key});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
      ),
    );
  }
}
