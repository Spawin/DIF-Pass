import '../domain/beneficiary.dart';
import '../domain/new_beneficiary.dart';

abstract class BeneficiaryRepository {
  Stream<List<Beneficiary>> watchBeneficiaries(int eventId);
  Future<Beneficiary> getBeneficiary(int id);
  Future<int> createBeneficiary(int eventId, NewBeneficiary beneficiary);
  Future<void> updateBeneficiary(int id, NewBeneficiary beneficiary);
  Future<void> deleteBeneficiary(int id);
  Future<int> importBeneficiaries(int eventId, List<NewBeneficiary> beneficiaries);
}
