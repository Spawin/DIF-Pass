import 'dart:typed_data';

import '../domain/beneficiary.dart';
import '../domain/new_beneficiary.dart';

abstract class BeneficiaryRepository {
  /// Beneficiaries for [eventId], with `photo` always null: the list view
  /// only needs a per-row thumbnail, so it fetches that lazily via
  /// [getBeneficiaryPhoto] instead of loading every photo BLOB on each
  /// emission.
  Stream<List<Beneficiary>> watchBeneficiaries(int eventId);
  Future<Beneficiary> getBeneficiary(int id);
  Future<Uint8List?> getBeneficiaryPhoto(int id);
  Future<int> createBeneficiary(int eventId, NewBeneficiary beneficiary);
  Future<void> updateBeneficiary(int id, NewBeneficiary beneficiary);
  Future<void> deleteBeneficiary(int id);
  Future<int> importBeneficiaries(int eventId, List<NewBeneficiary> beneficiaries);
}
