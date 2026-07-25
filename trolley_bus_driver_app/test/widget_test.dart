import 'package:flutter_test/flutter_test.dart';

import 'package:trolley_bus_driver/main.dart';

void main() {
  testWidgets('Start screen shows play button', (WidgetTester tester) async {
    await tester.pumpWidget(const TrolleyBusDriverApp());
    await tester.pump();

    expect(find.text('Play'), findsOneWidget);
    expect(find.textContaining('Trolley Bus Driver'), findsWidgets);
  });
}
