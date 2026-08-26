// test/features/events/domain/event_test.dart
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Event.isArchived reflects archivedAt', () {
    final active = Event(
      id: 1,
      shortCode: 'EVT1',
      name: 'Gala',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      createdAt: DateTime(2026, 1, 1),
    );
    expect(active.isArchived, isFalse);

    final archived = Event(
      id: 2,
      shortCode: 'EVT2',
      name: 'Old event',
      date: DateTime(2025, 1, 1),
      presenceMode: PresenceMode.multiple,
      archivedAt: DateTime(2026, 2, 1),
      createdAt: DateTime(2025, 1, 1),
    );
    expect(archived.isArchived, isTrue);
  });
}
