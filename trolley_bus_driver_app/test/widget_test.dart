import 'package:flutter_test/flutter_test.dart';

import 'package:trolley_bus_driver/main.dart';

void main() {
  testWidgets('Start screen shows play button', (WidgetTester tester) async {
    await tester.pumpWidget(const TrolleyBusDriverApp());
    await tester.pump();

    expect(find.text('Play'), findsOneWidget);
    expect(find.textContaining('Trolley Bus Driver'), findsWidgets);
  });

  testWidgets('Start screen shows the update stamp', (WidgetTester tester) async {
    await tester.pumpWidget(const TrolleyBusDriverApp());
    await tester.pump();

    // Label comes from the ARB files ("Update no." in the test's default
    // locale); the number defaults to kUpdateNumber's fallback unless the
    // build passes --dart-define=UPDATE_NUMBER=..., so match on the label and
    // whatever number followed it rather than a hardcoded version.
    expect(find.textContaining('Update no.'), findsOneWidget);
    expect(find.textContaining(kUpdateNumber), findsWidgets);
  });
}
