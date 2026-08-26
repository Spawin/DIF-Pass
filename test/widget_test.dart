import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/events/fake_event_repository.dart';

void main() {
  testWidgets('DifPassApp boots to the events list screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [eventRepositoryProvider.overrideWithValue(FakeEventRepository())],
        child: const DifPassApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Events'), findsOneWidget);
  });
}
