// test/widget_test.dart
import 'package:dif_pass/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DifPassApp boots to the placeholder home screen',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DifPassApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to DIF Pass'), findsOneWidget);
  });
}
