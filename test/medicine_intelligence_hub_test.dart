import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:careflow/models/medicine_item.dart';
import 'package:careflow/repositories/medicine_repository.dart';
import 'package:careflow/widgets/medicine/medicine_search_bar_card.dart';
import 'package:careflow/screens/shared/medicine/medicine_search_screen.dart';
import 'package:careflow/screens/shared/medicine/medicine_details_screen.dart';
import 'package:careflow/screens/patient/symptom_guidance/symptom_guidance_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. MedicineRepository & Data Engine Tests', () {
    late MedicineRepository repo;

    setUp(() {
      repo = MedicineRepository();
    });

    test('Searches by brand name (e.g. Dolo, Augmentin)', () async {
      final results = await repo.searchMedicines(query: 'Dolo');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((m) => m.name.contains('Dolo')), isTrue);
      expect(results.first.genericName, equals('Paracetamol'));
    });

    test('Searches by generic name (e.g. Metformin)', () async {
      final results = await repo.searchMedicines(query: 'Metformin');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((m) => m.genericName.toLowerCase().contains('metformin')), isTrue);
    });

    test('Searches by active ingredient and formulation', () async {
      final results = await repo.searchMedicines(query: 'Clavulanate');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.name, contains('Augmentin'));
    });

    test('Filters by dosage form correctly', () async {
      final inhalers = await repo.searchMedicines(query: '', dosageForm: 'Inhaler');
      expect(inhalers.isNotEmpty, isTrue);
      expect(inhalers.every((m) => m.dosageForm.toLowerCase() == 'inhaler'), isTrue);
    });

    test('Verification status is parsed and preserved', () async {
      final results = await repo.searchMedicines(query: 'Telma');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.verificationStatus, equals(MedicineVerificationStatus.verified));
      expect(results.first.verificationScope, contains('verified'));
    });

    test('Drug-drug interactions exist with severity and management', () async {
      final results = await repo.searchMedicines(query: 'Augmentin');
      expect(results.isNotEmpty, isTrue);
      final item = results.first;
      expect(item.drugInteractions.isNotEmpty, isTrue);
      expect(item.drugInteractions.first.severity, isNotEmpty);
      expect(item.drugInteractions.first.management, isNotEmpty);
    });
  });

  group('2. Symptom Guidance & Emergency Triage Tests', () {
    late MedicineRepository repo;

    setUp(() {
      repo = MedicineRepository();
    });

    test('Loads symptom guidance catalog with red flags', () {
      final list = repo.getSymptomGuidanceList();
      expect(list.length, greaterThanOrEqualTo(5));
      final chestPain = list.firstWhere((s) => s.id == 'sym_chest_pain');
      expect(chestPain.isEmergency, isTrue);
      expect(chestPain.emergencyWarning, contains('RED FLAG EMERGENCY'));
      expect(chestPain.redFlags.isNotEmpty, isTrue);
    });

    test('Emergency red flag evaluator detects urgent answers', () {
      final list = repo.getSymptomGuidanceList();
      final breath = list.firstWhere((s) => s.id == 'sym_breathlessness');
      final isEmergency = repo.evaluateEmergencyRedFlags(breath, ['No, struggling to speak even short words']);
      expect(isEmergency, isTrue);
    });
  });

  group('3. Dashboard Medicine Cards Widget Tests', () {
    testWidgets('Renders Patient prominent teal Medicine Intelligence card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MedicineSearchBarCard(role: MedicineCardRole.patient),
          ),
        ),
      );

      expect(find.text('Medicine Intelligence'), findsOneWidget);
      expect(find.text('Search medicines and explore symptom guidance'), findsOneWidget);
      expect(find.text('Search medicine name or brand...'), findsOneWidget);
      expect(find.byIcon(Icons.medication_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets('Renders Doctor light-blue Medicine Intelligence card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MedicineSearchBarCard(role: MedicineCardRole.doctor),
          ),
        ),
      );

      expect(find.text('Medicine Intelligence'), findsOneWidget);
      expect(
        find.text('Search medicines, check clinical details and review safety information'),
        findsOneWidget,
      );
      expect(find.text('Search medicine name, brand or ingredient...'), findsOneWidget);
      expect(find.byIcon(Icons.medication_rounded), findsOneWidget);
    });

    testWidgets('Renders Clinic Admin amber Medicine Intelligence card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MedicineSearchBarCard(role: MedicineCardRole.clinic),
          ),
        ),
      );

      expect(find.text('Medicine Intelligence'), findsOneWidget);
      expect(
        find.text('Search medicines, view product information and manage clinic inventory'),
        findsOneWidget,
      );
      expect(find.text('Search medicine name, brand or ingredient...'), findsOneWidget);
      expect(find.byIcon(Icons.medication_rounded), findsOneWidget);
    });
  });

  group('4. Shared Medicine Search Screen Tests', () {
    testWidgets('Renders search screen with filter chips and search bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MedicineSearchScreen(role: 'patient'),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Medicine Intelligence'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Inhaler'), findsOneWidget);
    });

    testWidgets('Displays search results with verification badges', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MedicineSearchScreen(
            role: 'patient',
            initialQuery: 'Dolo',
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Dolo 650'), findsOneWidget);
      expect(find.text('Verified'), findsWidgets);
      expect(find.text('View Details'), findsOneWidget);
    });

    testWidgets('Displays empty state with suggestions when query does not match', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MedicineSearchScreen(
            role: 'patient',
            initialQuery: 'NonExistentMedicineXyZ123',
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('No Medicines Found'), findsOneWidget);
      expect(find.text('Paracetamol'), findsOneWidget);
    });
  });

  group('5. Medicine Details Screen Tests', () {
    final sampleMedicine = MedicineItem(
      id: 'med_test_1',
      name: 'Augmentin 625 Duo',
      brandName: 'Augmentin',
      genericName: 'Amoxicillin + Clavulanic Acid',
      ingredients: ['Amoxicillin 500mg', 'Clavulanate 125mg'],
      strength: '625 mg',
      dosageForm: 'Tablet',
      manufacturer: 'GSK Pharmaceuticals',
      classification: 'Combination',
      overview: 'Broad spectrum antibacterial combination.',
      commonUses: ['Bacterial respiratory tract infections'],
      sideEffects: ['Diarrhea', 'Nausea'],
      precautions: ['Complete full course'],
      contraindications: ['Penicillin allergy'],
      drugInteractions: [
        const MedicineInteraction(
          interactingDrug: 'Methotrexate',
          severity: 'Major',
          clinicalEffect: 'Increased toxicity risk',
          management: 'Monitor serum levels',
          evidenceSource: 'WHO Monograph',
        ),
      ],
      storageInfo: 'Store below 25°C',
      verificationStatus: MedicineVerificationStatus.verified,
      verificationScope: 'Product verified via CDSCO',
      sourceReferences: ['Indian Pharmacopoeia (IP 2022)'],
      lastReviewedDate: '2026-09-01',
      isPrescriptionRequired: true,
    );

    testWidgets('Renders all required clinical sections and disclaimers', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MedicineDetailsScreen(medicine: sampleMedicine, role: 'doctor'),
        ),
      );

      expect(find.text('Augmentin 625 Duo'), findsWidgets);
      expect(find.text('Overview & Composition'), findsOneWidget);
      expect(find.text('Common Uses & Indications'), findsOneWidget);
      expect(find.text('Precautions & Contraindications'), findsOneWidget);
      expect(find.text('Known Side Effects'), findsOneWidget);
      expect(find.text('Drug-Drug Interactions'), findsOneWidget);
      expect(find.text('Storage & Regulatory Verification'), findsOneWidget);
      expect(find.textContaining('Educational medical reference only'), findsOneWidget);
      expect(find.text('Prescribe This Medicine in Consultation'), findsOneWidget);
    });
  });

  group('6. Symptom Guidance Screen Tests', () {
    testWidgets('Renders symptom guidance catalog and emergency notice', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SymptomGuidanceScreen(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Symptom Guidance'), findsWidgets);
      expect(find.text('Explore Symptom Guidance'), findsOneWidget);
      expect(find.textContaining('call 108 or emergency ambulance'), findsOneWidget);
      expect(find.text('Chest Pain or Pressure'), findsOneWidget);
      expect(find.text('Fever & Chills'), findsOneWidget);
    });

    testWidgets('Tapping emergency symptom displays red flag warning and Call 108 action', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SymptomGuidanceScreen(),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Chest Pain or Pressure'));
      await tester.pumpAndSettle();

      expect(find.text('EMERGENCY WARNING DETECTED'), findsOneWidget);
      expect(find.text('Call Ambulance (108)'), findsOneWidget);
      expect(find.text('Book Appointment with Doctor'), findsOneWidget);
    });
  });
}
