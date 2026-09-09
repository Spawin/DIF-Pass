import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../beneficiaries/presentation/providers/beneficiary_providers.dart';
import '../../../tickets/presentation/providers/ticket_providers.dart';
import '../providers/check_in_providers.dart';

class CheckInHistoryScreen extends ConsumerWidget {
  const CheckInHistoryScreen({required this.eventId, super.key});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final checkInsAsync = ref.watch(checkInsProvider(eventId));
    final ticketsAsync = ref.watch(ticketsProvider(eventId));
    final beneficiariesAsync = ref.watch(beneficiariesProvider(eventId));

    Widget body;
    if (checkInsAsync.hasError || ticketsAsync.hasError || beneficiariesAsync.hasError) {
      body = ErrorState(
        message: l10n.checkinHistoryLoadError,
        onRetry: () {
          ref.invalidate(checkInsProvider(eventId));
          ref.invalidate(ticketsProvider(eventId));
          ref.invalidate(beneficiariesProvider(eventId));
        },
      );
    } else if (!checkInsAsync.hasValue ||
        !ticketsAsync.hasValue ||
        !beneficiariesAsync.hasValue) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final checkIns = List.of(checkInsAsync.value!)
        ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      if (checkIns.isEmpty) {
        body = EmptyState(
          icon: Icons.history,
          message: l10n.checkinHistoryEmptyState,
        );
      } else {
        final beneficiaryNames = {
          for (final beneficiary in beneficiariesAsync.value!)
            beneficiary.id: beneficiary.name,
        };
        final ticketById = {
          for (final ticket in ticketsAsync.value!) ticket.id: ticket,
        };
        body = ListView.builder(
          itemCount: checkIns.length,
          itemBuilder: (context, index) {
            final checkIn = checkIns[index];
            final ticket = ticketById[checkIn.ticketId];
            final name =
                ticket != null ? (beneficiaryNames[ticket.beneficiaryId] ?? '') : '';
            return ListTile(
              title: Text(name),
              subtitle: Text(DateFormat.Hm(locale).format(checkIn.scannedAt)),
            );
          },
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkinHistoryTitle)),
      body: body,
    );
  }
}
