import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:careflow/screens/clinic/dashboard/admin_dashboard.dart';
import 'package:careflow/screens/clinic/more/more_menu_screen.dart';
import 'package:careflow/screens/clinic/patients/find_patient_walkin_screen.dart';
import 'package:careflow/screens/patient/prescriptions/prescription_details_screen.dart';
import 'package:careflow/screens/clinic/inventory/inventory_screen.dart';
import 'package:careflow/screens/clinic/analytics/analytics_dashboard.dart';
import 'package:careflow/screens/clinic/reports/upload_report_screen.dart';

void main() {
  group('1. Clinic Dashboard 5-Destination Persistent Navigation', () {
    testWidgets('Renders persistent 5 destinations without duplicate nav bars', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the 5 required navigation destinations
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Appointments'), findsOneWidget);
      expect(find.text('Queue'), findsOneWidget);
      expect(find.text('Patients'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Verify exactly one NavigationBar exists at root level (zero duplicate bars)
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('2. Clinic Home Redesign & Prioritized Quick Actions', () {
    testWidgets('Renders Rapid QR Check-in banner and 8 prioritized quick actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminHomeTab(
            onTabSelected: (_) {},
            initialLoadingForTesting: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Primary Hero QR Check-in
      expect(find.text('Rapid QR Check-in'), findsOneWidget);
      expect(find.text('Scan Patient QR'), findsOneWidget);
      expect(find.text('Manual Entry'), findsOneWidget);

      // Live Dashboard Summary Overview
      expect(find.text("Today's Overview"), findsOneWidget);
      expect(find.text("Scheduled Today"), findsOneWidget);
      expect(find.text("Waiting in Queue"), findsOneWidget);
      expect(find.text("Completed Visits"), findsOneWidget);
      expect(find.text("Pending Actions"), findsOneWidget);

      // 8 Prioritized Quick Actions with unclipped readable labels
      expect(find.text('QR Check-in'), findsOneWidget);
      expect(find.text('Find / Walk-in'), findsOneWidget);
      expect(find.text('Book Appt'), findsOneWidget);
      expect(find.text('Upload Report'), findsOneWidget);
      expect(find.text('Create Bill'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Doctors'), findsOneWidget);

      // Today's Work
      expect(find.text("Today's Work & Appointments"), findsOneWidget);
    });
  });

  group('3. Patient Account Rules — Find Patient / Walk-in Screen', () {
    testWidgets('Enforces patient data sovereignty and search workflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: FindPatientWalkInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Find Patient / Walk-in'), findsOneWidget);
      expect(find.textContaining('CareFlow Patient Data Sovereignty'), findsOneWidget);
      expect(find.textContaining('Patients own their personal accounts'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });
  });

  group('4. More Menu Screen — Grouped Architecture', () {
    testWidgets('Organizes modules into PATIENT CARE, CLINIC OPERATIONS, and MANAGEMENT', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MoreMenuScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Category Headers
      expect(find.text('PATIENT CARE'), findsOneWidget);
      expect(find.text('CLINIC OPERATIONS'), findsOneWidget);
      expect(find.text('MANAGEMENT'), findsOneWidget);

      // Patient Care items
      expect(find.text('Medical Records'), findsOneWidget);
      expect(find.text('Medical Reports'), findsOneWidget);
      expect(find.text('Prescriptions & Medications'), findsOneWidget);
      expect(find.text('Follow-ups'), findsOneWidget);

      // Clinic Operations items
      expect(find.text('Doctors & Staff'), findsOneWidget);
      expect(find.text('Clinic Calendar & Availability'), findsOneWidget);
      expect(find.text('Billing & Payments'), findsOneWidget);
      expect(find.text('Medicine Inventory'), findsOneWidget);

      // Management items
      expect(find.text('Analytics & Reports'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('User Management'), findsOneWidget);
      expect(find.text('Clinic Settings'), findsOneWidget);
    });
  });

  group('5. Patient Medication Guide & Safety Education', () {
    testWidgets('Renders all 5 required patient-facing medication guide sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final samplePrescription = {
        'medicine_name': 'Amoxicillin 500mg',
        'dosage': '1 Capsule (500mg)',
        'frequency': '3 times daily after meals',
        'instructions': 'Take every 8 hours with water. Finish entire 7-day course.',
        'indication': 'Bacterial Upper Respiratory Tract Infection',
        'duration': '7 days',
        'route': 'Oral',
        'doctor_name': 'Rajesh Sharma',
        'doctor_specialization': 'General Physician',
        'created_at': '2026-10-12T09:00:00Z',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: PrescriptionDetailsScreen(prescription: samplePrescription),
        ),
      );
      await tester.pumpAndSettle();

      // Heading 1: What is this medicine?
      expect(find.text('What is this medicine?'), findsOneWidget);
      expect(find.text('Amoxicillin 500mg'), findsNWidgets(2)); // Header banner + section row

      // Heading 2: Why did your doctor prescribe it?
      expect(find.text('Why did your doctor prescribe it?'), findsOneWidget);
      expect(find.text('Bacterial Upper Respiratory Tract Infection'), findsOneWidget);

      // Heading 3: How should you take it?
      expect(find.text('How should you take it?'), findsOneWidget);
      expect(find.text('Take every 8 hours with water. Finish entire 7-day course.'), findsOneWidget);

      // Heading 4: What should you know?
      expect(find.text('What should you know?'), findsOneWidget);
      expect(find.textContaining('Store below 25°C'), findsOneWidget);

      // Heading 5: Where can you learn more?
      expect(find.text('Where can you learn more?'), findsOneWidget);
      expect(find.textContaining('MedlinePlus / National Drug Information Standards'), findsOneWidget);
    });
  });

  group('6. Clinic Medicine Inventory Screen', () {
    testWidgets('Renders inventory metrics, search, and filter options', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clinic Medicine Inventory'), findsOneWidget);
      expect(find.text('Total Medicines'), findsOneWidget);
      expect(find.text('Low Stock Alerts'), findsOneWidget);
      expect(find.text('Expiring Soon'), findsNWidgets(2)); // Chip and metric
      expect(find.text('All Items'), findsOneWidget);
      expect(find.text('Low Stock'), findsOneWidget);
      expect(find.text('Add Medicine'), findsOneWidget);
    });
  });

  group('7. Daily Clinic Analytics Dashboard', () {
    testWidgets('Renders operational, financial, and volume analytics', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AnalyticsDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Clinic Analytics'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Clinical Operations'), findsOneWidget);
      expect(find.text('Revenue & Billing'), findsOneWidget);
      expect(find.text('Reports & Pharmacy Stock'), findsOneWidget);
    });
  });

  group('8. Medical Reports Upload Categories', () {
    testWidgets('Renders comprehensive clinical report categories', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: UploadReportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upload Patient Report'), findsOneWidget);
      expect(find.text('Select Patient *'), findsOneWidget);
      expect(find.text('Report Metadata'), findsOneWidget);
      expect(find.text('Report Type'), findsOneWidget);
    });
  });
}
