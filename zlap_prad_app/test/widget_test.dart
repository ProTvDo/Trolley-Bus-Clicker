import 'package:flutter_test/flutter_test.dart';

import 'package:zlap_prad/main.dart';

void main() {
  testWidgets('Start screen shows play button', (WidgetTester tester) async {
    await tester.pumpWidget(const ZlapPradApp());
    await tester.pump();

    expect(find.text('Zagraj'), findsOneWidget);
    expect(find.textContaining('Złap Prąd'), findsWidgets);
  });
}
