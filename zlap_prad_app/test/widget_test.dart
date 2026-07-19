import 'package:flutter_test/flutter_test.dart';

import 'package:zlap_prad/main.dart';

void main() {
  testWidgets('Start screen shows play button', (WidgetTester tester) async {
    await tester.pumpWidget(const ZlapPradApp());
    await tester.pump();

    expect(find.text('Play'), findsOneWidget);
    expect(find.textContaining('Troley Bus Clicker'), findsWidgets);
  });
}
