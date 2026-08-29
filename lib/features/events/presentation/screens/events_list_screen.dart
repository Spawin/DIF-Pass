import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/event_providers.dart';
import '../widgets/event_card.dart';

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final eventsAsync = ref.watch(activeEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventsListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: l10n.eventsArchiveAction,
            onPressed: () => context.push('/events/archives'),
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.eventsEmptyState,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(
                event: event,
                onTap: () => context.push('/events/${event.id}/edit'),
                onManageBeneficiaries: () =>
                    context.push('/events/${event.id}/beneficiaries'),
                onManageTickets: () =>
                    context.push('/events/${event.id}/tickets'),
                onArchive: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(eventRepositoryProvider)
                        .archiveEvent(event.id);
                  } catch (e) {
                    if (!context.mounted) return;
                    messenger.showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.eventsLoadError)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/events/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.eventsNewAction),
      ),
    );
  }
}
