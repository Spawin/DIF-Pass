import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/audit/audit_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/event.dart';
import '../providers/event_providers.dart';

class EventArchiveScreen extends ConsumerWidget {
  const EventArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final eventsAsync = ref.watch(archivedEventsProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.eventsArchiveTitle)),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return EmptyState(
              icon: Icons.archive_outlined,
              message: l10n.eventsArchiveEmptyState,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    event.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(DateFormat.yMMMMd(locale).format(event.date)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore),
                        tooltip: l10n.eventsRestoreAction,
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final repository = ref.read(eventRepositoryProvider);
                          // Read before the await: see tickets_screen.dart's
                          // _confirmGenerate for why.
                          final auditLogger = ref.read(auditLoggerProvider);
                          try {
                            await repository.restoreEvent(event.id);
                            auditLogger.logEventArchiveAction(action: 'restore');
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(l10n.eventsRestoredMessage),
                                action: SnackBarAction(
                                  label: l10n.commonUndo,
                                  onPressed: () =>
                                      repository.archiveEvent(event.id),
                                ),
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.eventsRestoreError)),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever_outlined),
                        tooltip: l10n.eventsDeletePermanentlyAction,
                        onPressed: () => _confirmDelete(context, ref, event),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorState(
          message: l10n.eventsLoadError,
          onRetry: () => ref.invalidate(archivedEventsProvider),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Event event) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(eventRepositoryProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.eventsDeleteConfirmTitle),
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
        await repository.deleteEventPermanently(event.id);
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.eventsDeletePermanentlyError)),
        );
      }
    }
  }
}
