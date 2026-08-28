import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/custom_field_type.dart';
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_event_repository.dart';

void main() {
  test('activeEventsProvider streams events from the overridden repository', () async {
    final fake = FakeEventRepository(events: [
      Event(
        id: 1,
        shortCode: 'EVT1',
        name: 'Gala DIF 2026',
        date: DateTime(2026, 12, 1),
        presenceMode: PresenceMode.simple,
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [eventRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final events = await container.read(activeEventsProvider.future);
    expect(events, hasLength(1));
    expect(events.single.name, 'Gala DIF 2026');
  });

  test('customFieldsProvider re-emits after replaceCustomFields', () async {
    final fake = FakeEventRepository();
    final eventId = await fake.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    final container = ProviderContainer(
      overrides: [eventRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final emissions = <List<CustomField>>[];
    final subscription = container.listen(
      customFieldsProvider(eventId),
      (previous, next) {
        final value = next.valueOrNull;
        if (value != null) emissions.add(value);
      },
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await fake.replaceCustomFields(eventId, const [
      NewCustomField(label: 'Table number', type: CustomFieldType.text, sortOrder: 0),
    ]);
    // Let the microtask-scheduled emission land. If one delayed(Duration.zero)
    // isn't enough to observe both emissions, add one or two more, this is
    // waiting for a known-to-arrive event, not racing an ordering bug.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(emissions, isNotEmpty);
    expect(emissions.first, isEmpty);
    expect(emissions.last, hasLength(1));
    expect(emissions.last.single.label, 'Table number');
  });
}
