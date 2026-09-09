import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
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
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsAction,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return EmptyState(
              icon: Icons.event_outlined,
              message: l10n.eventsEmptyState,
              actionLabel: l10n.eventsNewAction,
              onAction: () => context.push('/events/new'),
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
                onCheckIn: () => context.push('/events/${event.id}/checkin'),
                onViewHistory: () =>
                    context.push('/events/${event.id}/checkin/history'),
                onArchive: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final repository = ref.read(eventRepositoryProvider);
                  try {
                    await repository.archiveEvent(event.id);
                    HapticFeedback.lightImpact();
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.eventsArchivedMessage),
                        action: SnackBarAction(
                          label: l10n.commonUndo,
                          onPressed: () => repository.restoreEvent(event.id),
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.eventsArchiveError)),
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorState(
          message: l10n.eventsLoadError,
          onRetry: () => ref.invalidate(activeEventsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/events/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.eventsNewAction),
      ),
    );
  }
}
