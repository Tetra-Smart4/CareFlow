import 'package:flutter_test/flutter_test.dart';
import 'package:careflow/core/app.dart';

void main() {
  testWidgets('CareFlow app builds and displays brand elements', (WidgetTester tester) async {
    await tester.pumpWidget(const CareFlowApp());
    await tester.pump();

    // Verify CareFlow branding is present on splash screen
    expect(find.text('CareFlow'), findsWidgets);

    // Advance animation and splash timer
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
