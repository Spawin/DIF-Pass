import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/beneficiary.dart';
import '../domain/new_beneficiary.dart';
import 'beneficiary_repository.dart';

class DriftBeneficiaryRepository implements BeneficiaryRepository {
  DriftBeneficiaryRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Beneficiary>> watchBeneficiaries(int eventId) {
    final query = _db.selectOnly(_db.beneficiaries).join([
      leftOuterJoin(
        _db.beneficiaryValues,
        _db.beneficiaryValues.beneficiaryId.equalsExp(_db.beneficiaries.id),
      ),
    ])
      ..addColumns([
        _db.beneficiaries.id,
        _db.beneficiaries.eventId,
        _db.beneficiaries.name,
        _db.beneficiaries.createdAt,
        _db.beneficiaries.syncId,
        _db.beneficiaryValues.customFieldId,
        _db.beneficiaryValues.value,
      ])
      ..where(_db.beneficiaries.eventId.equals(eventId));
    return query.watch().map(_groupListRows);
  }

  @override
  Future<Beneficiary> getBeneficiary(int id) async {
    final query = _db.select(_db.beneficiaries).join([
      leftOuterJoin(
        _db.beneficiaryValues,
        _db.beneficiaryValues.beneficiaryId.equalsExp(_db.beneficiaries.id),
      ),
    ])
      ..where(_db.beneficiaries.id.equals(id));
    final rows = await query.get();
    return _groupRows(rows).single;
  }

  @override
  Future<Uint8List?> getBeneficiaryPhoto(int id) async {
    final row = await (_db.selectOnly(_db.beneficiaries)
          ..addColumns([_db.beneficiaries.photo])
          ..where(_db.beneficiaries.id.equals(id)))
        .getSingle();
    return row.read(_db.beneficiaries.photo);
  }

  @override
  Future<int> createBeneficiary(int eventId, NewBeneficiary beneficiary) {
    return _db.transaction(() async {
      final id = await _db.into(_db.beneficiaries).insert(
            BeneficiariesCompanion.insert(
              eventId: eventId,
              name: beneficiary.name,
              photo: Value(beneficiary.photo),
            ),
          );
      await _insertValues(id, beneficiary.customFieldValues);
      return id;
    });
  }

  @override
  Future<void> updateBeneficiary(int id, NewBeneficiary beneficiary) {
    return _db.transaction(() async {
      await (_db.update(_db.beneficiaries)..where((tbl) => tbl.id.equals(id)))
          .write(BeneficiariesCompanion(
            name: Value(beneficiary.name),
            photo: Value(beneficiary.photo),
          ));
      await (_db.delete(_db.beneficiaryValues)
            ..where((tbl) => tbl.beneficiaryId.equals(id)))
          .go();
      await _insertValues(id, beneficiary.customFieldValues);
    });
  }

  @override
  Future<void> deleteBeneficiary(int id) async {
    await (_db.delete(_db.beneficiaries)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<int> importBeneficiaries(int eventId, List<NewBeneficiary> beneficiaries) {
    return _db.transaction(() async {
      var count = 0;
      for (final beneficiary in beneficiaries) {
        final id = await _db.into(_db.beneficiaries).insert(
              BeneficiariesCompanion.insert(
                eventId: eventId,
                name: beneficiary.name,
                photo: Value(beneficiary.photo),
              ),
            );
        await _insertValues(id, beneficiary.customFieldValues);
        count++;
      }
      return count;
    });
  }

  Future<void> _insertValues(int beneficiaryId, Map<int, String> values) async {
    for (final entry in values.entries) {
      if (entry.value.trim().isEmpty) continue;
      await _db.into(_db.beneficiaryValues).insert(
            BeneficiaryValuesCompanion.insert(
              beneficiaryId: beneficiaryId,
              customFieldId: entry.key,
              value: entry.value,
            ),
          );
    }
  }

  /// Groups rows from [watchBeneficiaries]'s photo-less, `selectOnly` join,
  /// where `readTable` isn't available (only the addColumns subset was
  /// selected) so each column is read individually instead.
  List<Beneficiary> _groupListRows(List<TypedResult> rows) {
    final beneficiaryRows = <int, ({int id, int eventId, String name, DateTime createdAt, String? syncId})>{};
    final values = <int, Map<int, String>>{};
    for (final row in rows) {
      final id = row.read(_db.beneficiaries.id)!;
      beneficiaryRows[id] = (
        id: id,
        eventId: row.read(_db.beneficiaries.eventId)!,
        name: row.read(_db.beneficiaries.name)!,
        createdAt: row.read(_db.beneficiaries.createdAt)!,
        syncId: row.read(_db.beneficiaries.syncId),
      );
      final customFieldId = row.read(_db.beneficiaryValues.customFieldId);
      final value = row.read(_db.beneficiaryValues.value);
      final valueMap = values.putIfAbsent(id, () => {});
      if (customFieldId != null && value != null) {
        valueMap[customFieldId] = value;
      }
    }
    final result = beneficiaryRows.values
        .map((b) => Beneficiary(
              id: b.id,
              eventId: b.eventId,
              name: b.name,
              customFieldValues: Map.unmodifiable(values[b.id] ?? const {}),
              createdAt: b.createdAt,
              syncId: b.syncId,
              photo: null,
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  List<Beneficiary> _groupRows(List<TypedResult> rows) {
    final beneficiaryRows = <int, BeneficiaryEntity>{};
    final values = <int, Map<int, String>>{};
    for (final row in rows) {
      final b = row.readTable(_db.beneficiaries);
      beneficiaryRows[b.id] = b;
      final v = row.readTableOrNull(_db.beneficiaryValues);
      final valueMap = values.putIfAbsent(b.id, () => {});
      if (v != null) {
        valueMap[v.customFieldId] = v.value;
      }
    }
    final result = beneficiaryRows.values
        .map((b) => Beneficiary(
              id: b.id,
              eventId: b.eventId,
              name: b.name,
              customFieldValues: Map.unmodifiable(values[b.id] ?? const {}),
              createdAt: b.createdAt,
              syncId: b.syncId,
              photo: b.photo,
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return result;
  }
}
