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
}
