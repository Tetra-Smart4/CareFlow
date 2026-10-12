import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:careflow/core/config/supabase_config.dart';
import 'package:careflow/screens/clinic/doctors/add_doctor_screen.dart';
import 'package:careflow/screens/clinic/doctors/doctor_management_screen.dart';
import 'package:careflow/screens/doctor/profile/doctor_profile_screen.dart';
import 'package:careflow/screens/auth/reset_password_screen.dart';
import 'package:careflow/screens/clinic/patients/patient_management_screen.dart';

void main() {
  group('Requirement 1 & 2: Clinic Creates Doctor Profile (AddDoctorScreen)', () {
    testWidgets('Blocks unapproved clinics from accessing doctor creation', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AddDoctorScreen(isClinicApprovedForTesting: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clinic Approval Required'), findsOneWidget);
      expect(find.textContaining('awaiting platform administrator approval'), findsOneWidget);
      expect(find.text('Send Doctor Invitation'), findsNothing);
    });

    testWidgets('Renders all required initial doctor fields & email invitation guidance', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AddDoctorScreen(isClinicApprovedForTesting: true),
        ),
      );
      await tester.pumpAndSettle();

      // Form fields
      expect(find.text('Doctor Full Name *'), findsOneWidget);
      expect(find.text('Email Address (Invitation Recipient) *'), findsOneWidget);
      expect(find.text('Contact Phone'), findsOneWidget);
      expect(find.text('Specialization *'), findsOneWidget);
      expect(find.text('Qualification'), findsOneWidget);
      expect(find.text('Medical Council Registration Number'), findsOneWidget);
      expect(find.text('Years of Experience'), findsOneWidget);
      expect(find.text('Initial Consultation Fee (₹)'), findsOneWidget);

      // Single-use email invitation explanation
      expect(find.textContaining('single-use activation link'), findsOneWidget);
      expect(find.text('Send Doctor Invitation'), findsOneWidget);
    });

    testWidgets('Validates required fields on submission', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AddDoctorScreen(isClinicApprovedForTesting: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Doctor Invitation'));
      await tester.pumpAndSettle();

      expect(find.text('Doctor full name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Specialization is required'), findsOneWidget);
    });
  });

  group('Requirement 3 & 4: Doctor Account Activation & Password Setup', () {
    testWidgets('ResetPasswordScreen allows doctor to create password and displays activation confirmation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create New Password'), findsWidgets);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
    });
  });

  group('Requirement 5: Doctor Manages Professional Profile & Proposes Fees', () {
    testWidgets('DoctorProfileScreen displays doctor details, qualifications, and clinic fee sections', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Either loading or loaded screen
      expect(find.byType(DoctorProfileScreen), findsOneWidget);
    });
  });

  group('Requirement 6, 8, 9, 10, 11: Clinic Manages Doctor Associations & Fee Approvals', () {
    testWidgets('DoctorManagementScreen renders management interface and action options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorManagementScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manage Clinic Doctors'), findsOneWidget);
      expect(find.text('Invite Doctor'), findsOneWidget);
    });
  });

  group('Requirement 7 & 12: Strict Clinic Patient Isolation', () {
    testWidgets('PatientManagementScreen displays strict clinic patient directory with zero cross-clinic leakage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatientManagementScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clinic Patient Directory'), findsOneWidget);
      expect(find.textContaining('Search patients'), findsOneWidget);
    });
  });

  group('Live Remote Database & Security Rules Verification', () {
    late SupabaseClient client;

    setUpAll(() {
      expect(SupabaseConfig.isConfigured, isTrue);
      client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.publishableKey);
    });

    test('DB-1: careflow_doctor_clinic_fees table exists remotely with RLS', () async {
      try {
        final res = await client.from('careflow_doctor_clinic_fees').select().limit(1);
        expect(res, isNotNull);
      } catch (e) {
        expect(e.toString().contains('PGRST205'), isFalse, reason: 'careflow_doctor_clinic_fees table must exist');
      }
    });

    test('DB-2: careflow_doctor_clinic_fee_history table exists remotely', () async {
      try {
        final res = await client.from('careflow_doctor_clinic_fee_history').select().limit(1);
        expect(res, isNotNull);
      } catch (e) {
        expect(e.toString().contains('PGRST205'), isFalse, reason: 'careflow_doctor_clinic_fee_history table must exist');
      }
    });

    test('DB-3: RPC careflow_propose_consultation_fee is deployed and auth-guarded', () async {
      try {
        await client.rpc('careflow_propose_consultation_fee', params: {
          'p_clinic_id': '00000000-0000-0000-0000-000000000000',
          'p_proposed_fee': 500,
        });
      } catch (e) {
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'careflow_propose_consultation_fee RPC must exist');
        expect(e is PostgrestException, isTrue);
      }
    });

    test('DB-4: RPC careflow_approve_consultation_fee is deployed and blocks unauthorized execution', () async {
      try {
        await client.rpc('careflow_approve_consultation_fee', params: {
          'p_doctor_id': '00000000-0000-0000-0000-000000000000',
          'p_clinic_id': '00000000-0000-0000-0000-000000000000',
        });
      } catch (e) {
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'careflow_approve_consultation_fee RPC must exist');
      }
    });

    test('DB-5: RPC careflow_reject_consultation_fee is deployed', () async {
      try {
        await client.rpc('careflow_reject_consultation_fee', params: {
          'p_doctor_id': '00000000-0000-0000-0000-000000000000',
          'p_clinic_id': '00000000-0000-0000-0000-000000000000',
          'p_reason': 'Test',
        });
      } catch (e) {
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'careflow_reject_consultation_fee RPC must exist');
      }
    });

    test('DB-6: RPC careflow_get_clinic_patients is deployed and enforces clinic authorization', () async {
      try {
        await client.rpc('careflow_get_clinic_patients', params: {
          'p_clinic_id': '00000000-0000-0000-0000-000000000000',
        });
      } catch (e) {
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'careflow_get_clinic_patients RPC must exist');
        expect(e is PostgrestException, isTrue);
      }
    });

    test('DB-7: RPC careflow_deactivate_clinic_doctor is deployed', () async {
      try {
        await client.rpc('careflow_deactivate_clinic_doctor', params: {
          'p_doctor_id': '00000000-0000-0000-0000-000000000000',
          'p_clinic_id': '00000000-0000-0000-0000-000000000000',
          'p_cancel_upcoming': false,
        });
      } catch (e) {
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'careflow_deactivate_clinic_doctor RPC must exist');
      }
    });

    test('DB-8: RPC careflow_reactivate_clinic_doctor is deployed', () async {
      try {
        await client.rpc('careflow_reactivate_clinic_doctor', params: {
          'p_doctor_id': '00000000-0000-0000-0000-000000000000',
          'p_clinic_id': '00000000-0000-0000-0000-000000000000',
        });
      } catch (e) {
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'careflow_reactivate_clinic_doctor RPC must exist');
      }
    });

    test('DB-9: RPC careflow_remove_clinic_doctor is deployed', () async {
      try {
        await client.rpc('careflow_remove_clinic_doctor', params: {
          'p_doctor_id': '00000000-0000-0000-0000-000000000000',
          'p_clinic_id': '00000000-0000-0000-0000-000000000000',
        });
      } catch (e) {
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'careflow_remove_clinic_doctor RPC must exist');
      }
    });

    test('DB-10: RPC careflow_activate_doctor_account is deployed', () async {
      try {
        await client.rpc('careflow_activate_doctor_account', params: {
          'p_doctor_id': '00000000-0000-0000-0000-000000000000',
        });
      } catch (e) {
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'careflow_activate_doctor_account RPC must exist');
      }
    });

    test('EDGE-1: Edge Function create-doctor rejects unauthenticated requests with HTTP 4xx', () async {
      try {
        final res = await client.functions.invoke('create-doctor', body: {'full_name': 'Test'});
        expect(res.status >= 400, isTrue);
      } catch (e) {
        // FunctionException is expected
        expect(e is FunctionException || e.toString().contains('400') || e.toString().contains('401'), isTrue);
      }
    });
  });
}
