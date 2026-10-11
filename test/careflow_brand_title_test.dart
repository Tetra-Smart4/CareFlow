import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:careflow/widgets/common/careflow_brand_title.dart';

void main() {
  group('CareFlowBrandTitle and CareFlowLogoIcon Tests', () {
    testWidgets('renders CareFlowLogoIcon with gradient and heart icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CareFlowLogoIcon(),
          ),
        ),
      );

      expect(find.byType(CareFlowLogoIcon), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('renders CareFlowBrandTitle with brand text and icon side by side', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const CareFlowBrandTitle(),
            ),
          ),
        ),
      );

      expect(find.byType(CareFlowBrandTitle), findsOneWidget);
      expect(find.byType(CareFlowLogoIcon), findsOneWidget);
      expect(find.text('CareFlow'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      // Verify that icon and text are children of a Row
      final rowFinder = find.descendant(
        of: find.byType(CareFlowBrandTitle),
        matching: find.byType(Row),
      );
      expect(rowFinder, findsOneWidget);
    });

    testWidgets('renders CareFlowBrandTitle with custom subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const CareFlowBrandTitle(
                subtitle: 'Platform Admin',
              ),
            ),
          ),
        ),
      );

      expect(find.text('CareFlow'), findsOneWidget);
      expect(find.text('Platform Admin'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });
  });
}
