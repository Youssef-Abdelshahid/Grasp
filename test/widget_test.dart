import 'package:flutter_test/flutter_test.dart';
import 'package:grasp/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GraspApp());
    expect(find.byType(GraspApp), findsOneWidget);
  });
}
