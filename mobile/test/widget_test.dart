import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('App launches and shows the splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CareerReadyApp());
    expect(find.text('career ready'), findsOneWidget);
  });
}
