import 'dart:typed_data';

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

final beneficiaryProvider = FutureProvider.autoDispose.family<Beneficiary, int>((ref, id) {
  return ref.watch(beneficiaryRepositoryProvider).getBeneficiary(id);
});

/// Loaded lazily per row by the beneficiaries list, which never gets a
/// photo from [beneficiariesProvider]'s stream (see watchBeneficiaries).
final beneficiaryPhotoProvider =
    FutureProvider.autoDispose.family<Uint8List?, int>((ref, id) {
  return ref.watch(beneficiaryRepositoryProvider).getBeneficiaryPhoto(id);
});
