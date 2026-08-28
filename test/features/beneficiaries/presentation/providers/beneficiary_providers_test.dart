import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_beneficiary_repository.dart';

void main() {
  test('beneficiariesProvider streams beneficiaries for the given event', () async {
    final fake = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 42,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [beneficiaryRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final beneficiaries = await container.read(beneficiariesProvider(42).future);
    expect(beneficiaries, hasLength(1));
    expect(beneficiaries.single.name, 'Jane Doe');
  });
}
