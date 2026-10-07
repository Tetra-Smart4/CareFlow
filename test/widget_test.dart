import 'package:flutter_test/flutter_test.dart';
import 'package:careflow/core/app.dart';

void main() {
  testWidgets('CareFlow app builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const CareFlowApp());
    await tester.pump();

    expect(find.text('CareFlow'), findsOneWidget);
  });
}
