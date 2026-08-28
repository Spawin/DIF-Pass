import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/beneficiary_repository.dart';
import '../../data/drift_beneficiary_repository.dart';
import '../../domain/beneficiary.dart';

final beneficiaryRepositoryProvider = Provider<BeneficiaryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftBeneficiaryRepository(db);
});

final beneficiariesProvider =
    StreamProvider.family<List<Beneficiary>, int>((ref, eventId) {
  return ref.watch(beneficiaryRepositoryProvider).watchBeneficiaries(eventId);
});
