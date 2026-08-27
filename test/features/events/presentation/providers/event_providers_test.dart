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

    final stream = container.read(customFieldsProvider(eventId).stream);
    final expectation = expectLater(
      stream,
      emitsInOrder([
        predicate<List<CustomField>>((list) => list.isEmpty),
        predicate<List<CustomField>>(
            (list) => list.length == 1 && list.single.label == 'Table number'),
      ]),
    );

    await fake.replaceCustomFields(eventId, const [
      NewCustomField(label: 'Table number', type: CustomFieldType.text, sortOrder: 0),
    ]);

    await expectation;
  });
}
