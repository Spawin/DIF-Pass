import 'dart:async';
import 'dart:typed_data';

import 'package:dif_pass/features/beneficiaries/data/beneficiary_repository.dart';
import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/domain/new_beneficiary.dart';

/// In-memory BeneficiaryRepository for widget/provider tests. Not shipped
/// in the app, lives under test/ only.
class FakeBeneficiaryRepository implements BeneficiaryRepository {
  FakeBeneficiaryRepository({List<Beneficiary>? beneficiaries})
      : _beneficiaries = List.of(beneficiaries ?? const []);

  final List<Beneficiary> _beneficiaries;
  final Map<int, StreamController<List<Beneficiary>>> _controllers = {};
  int _nextId = 1000;

  List<Beneficiary> get beneficiaries => List.unmodifiable(_beneficiaries);

  StreamController<List<Beneficiary>> _controllerFor(int eventId) {
    return _controllers.putIfAbsent(
      eventId,
      () => StreamController<List<Beneficiary>>.broadcast(),
    );
  }

  void _emit(int eventId) {
    // Mirrors DriftBeneficiaryRepository: the list stream never carries a
    // photo, callers fetch it lazily via getBeneficiaryPhoto.
    final list = _beneficiaries
        .where((b) => b.eventId == eventId)
        .map((b) => b.photo == null ? b : _withoutPhoto(b))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    _controllerFor(eventId).add(list);
  }

  Beneficiary _withoutPhoto(Beneficiary b) => Beneficiary(
        id: b.id,
        eventId: b.eventId,
        name: b.name,
        customFieldValues: b.customFieldValues,
        createdAt: b.createdAt,
        syncId: b.syncId,
      );

  @override
  Stream<List<Beneficiary>> watchBeneficiaries(int eventId) {
    Future.microtask(() => _emit(eventId));
    return _controllerFor(eventId).stream;
  }

  @override
  Future<Beneficiary> getBeneficiary(int id) async =>
      _beneficiaries.firstWhere((b) => b.id == id);

  @override
  Future<Uint8List?> getBeneficiaryPhoto(int id) async =>
      _beneficiaries.firstWhere((b) => b.id == id).photo;

  @override
  Future<int> createBeneficiary(int eventId, NewBeneficiary beneficiary) async {
    final id = _nextId++;
    _beneficiaries.add(Beneficiary(
      id: id,
      eventId: eventId,
      name: beneficiary.name,
      customFieldValues: Map.of(beneficiary.customFieldValues),
      createdAt: DateTime.now(),
      photo: beneficiary.photo,
    ));
    _emit(eventId);
    return id;
  }

  @override
  Future<void> updateBeneficiary(int id, NewBeneficiary beneficiary) async {
    final index = _beneficiaries.indexWhere((b) => b.id == id);
    final existing = _beneficiaries[index];
    _beneficiaries[index] = Beneficiary(
      id: existing.id,
      eventId: existing.eventId,
      name: beneficiary.name,
      customFieldValues: Map.of(beneficiary.customFieldValues),
      createdAt: existing.createdAt,
      photo: beneficiary.photo,
    );
    _emit(existing.eventId);
  }

  @override
  Future<void> deleteBeneficiary(int id) async {
    final index = _beneficiaries.indexWhere((b) => b.id == id);
    final eventId = _beneficiaries[index].eventId;
    _beneficiaries.removeAt(index);
    _emit(eventId);
  }

  @override
  Future<int> importBeneficiaries(
    int eventId,
    List<NewBeneficiary> beneficiaries,
  ) async {
    for (final beneficiary in beneficiaries) {
      final id = _nextId++;
      _beneficiaries.add(Beneficiary(
        id: id,
        eventId: eventId,
        name: beneficiary.name,
        customFieldValues: Map.of(beneficiary.customFieldValues),
        createdAt: DateTime.now(),
        photo: beneficiary.photo,
      ));
    }
    _emit(eventId);
    return beneficiaries.length;
  }
}
