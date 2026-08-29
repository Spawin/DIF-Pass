import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../tickets/presentation/providers/ticket_providers.dart';
import '../../data/check_in_repository.dart';
import '../../data/drift_check_in_repository.dart';
import '../../domain/check_in.dart';

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftCheckInRepository(db);
});

final checkInsProvider =
    StreamProvider.family<List<CheckIn>, int>((ref, eventId) {
  return ref.watch(checkInRepositoryProvider).watchCheckInsForEvent(eventId);
});

final checkInCounterProvider = Provider.family<(int, int), int>((ref, eventId) {
  final tickets = ref.watch(ticketsProvider(eventId)).valueOrNull ?? const [];
  final checkIns = ref.watch(checkInsProvider(eventId)).valueOrNull ?? const [];
  final distinctCheckedIn = checkIns.map((c) => c.ticketId).toSet().length;
  return (distinctCheckedIn, tickets.length);
});
