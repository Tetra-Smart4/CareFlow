import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:careflow/screens/auth/role_selection_screen.dart';
import 'package:careflow/screens/auth/login_screen.dart';
import 'package:careflow/screens/auth/patient_registration_screen.dart';
import 'package:careflow/screens/auth/clinic_registration_screen.dart';
import 'package:careflow/screens/patient/emergency/emergency_contact_screen.dart';
import 'package:careflow/models/emergency_contact.dart';

void main() {
  group('Section 2: Final Public Authentication Screen', () {
    testWidgets('Displays brand header, LOGIN button, and exactly 2 public registration options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RoleSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Brand Title and Tagline
      expect(find.text('CAREFLOW'), findsOneWidget);
      expect(find.text('Better care begins with better connections.'), findsOneWidget);

      // Prominent LOGIN button
      expect(find.byKey(const Key('login_button')), findsOneWidget);
      expect(find.text('LOGIN'), findsOneWidget);

      // Section label
      expect(find.text('New to CareFlow?'), findsOneWidget);

      // Exactly 2 public registration options
      expect(find.byKey(const Key('register_patient_button')), findsOneWidget);
      expect(find.text('Register as Patient'), findsOneWidget);

      expect(find.byKey(const Key('register_clinic_button')), findsOneWidget);
      expect(find.text('Register as Clinic'), findsOneWidget);

      // Must NOT show unauthorized public registration options
      expect(find.text('Register as Doctor'), findsNothing);
      expect(find.text('Register as Admin'), findsNothing);
      expect(find.text('Register as Staff'), findsNothing);
      expect(find.text('Register as Family'), findsNothing);
    });
  });

  group('Section 24 & 25: Common Login Screen', () {
    testWidgets('Has email, password, show password toggle, forgot password, and NO role selector', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Email and password fields
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('submit_login_button')), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);

      // Must NOT prompt for role selection during login
      expect(find.text('Login as Patient'), findsNothing);
      expect(find.text('Login as Doctor'), findsNothing);
      expect(find.text('Login as Clinic'), findsNothing);
      expect(find.text('Login as Admin'), findsNothing);
      expect(find.text('Select Role'), findsNothing);
    });

    testWidgets('Shows validation errors on empty submission', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });
  });

  group('Section 3 & 5: Patient Registration Form', () {
    testWidgets('Collects account and personal details, and excludes emergency contacts and medical questions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatientRegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Account Details
      expect(find.text('1. Account Details'), findsOneWidget);
      expect(find.byKey(const Key('patient_name_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_email_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_password_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_confirm_password_field')), findsOneWidget);

      // Personal Details
      expect(find.text('2. Personal Details'), findsOneWidget);
      expect(find.byKey(const Key('patient_dob_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_gender_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_address_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_city_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_state_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_pincode_field')), findsOneWidget);

      // Explicit prohibition: MUST NOT collect emergency contact or medical info during registration
      expect(find.text('Emergency Contact Name'), findsNothing);
      expect(find.text('Emergency Contact Phone'), findsNothing);
      expect(find.text('Emergency Contact Relationship'), findsNothing);
      expect(find.text('Medical History'), findsNothing);
      expect(find.text('Symptoms'), findsNothing);
      expect(find.text('Diagnosis'), findsNothing);
      expect(find.text('Prescription'), findsNothing);
    });
  });

  group('Section 14 & 16: Clinic Registration Form', () {
    testWidgets('Collects clinic details and authorized contact person, explains pending approval', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ClinicRegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Clinic details
      expect(find.text('1. Clinic Details'), findsOneWidget);
      expect(find.byKey(const Key('clinic_name_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_email_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_type_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_address_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_city_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_state_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_pincode_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_about_field')), findsOneWidget);

      // Authorized contact details
      expect(find.text('2. Authorized Account Contact'), findsOneWidget);
      expect(find.byKey(const Key('contact_name_field')), findsOneWidget);
      expect(find.byKey(const Key('contact_email_field')), findsOneWidget);
      expect(find.byKey(const Key('contact_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_password_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_confirm_password_field')), findsOneWidget);

      // Status notice
      expect(find.textContaining('PENDING status'), findsOneWidget);
    });
  });

  group('Section 9-12: Emergency Contacts Model & Screen', () {
    test('EmergencyContact model serializes and deserializes properly', () {
      final model = EmergencyContact(
        id: 'ec-123',
        patientId: 'patient-456',
        name: 'Jane Doe',
        phone: '+91 9876543210',
        relationship: 'Spouse',
      );

      final json = model.toJson();
      expect(json['name'], 'Jane Doe');
      expect(json['phone'], '+91 9876543210');
      expect(json['relationship'], 'Spouse');
      expect(json['patient_id'], 'patient-456');

      final fromJson = EmergencyContact.fromJson({
        'id': 'ec-123',
        'patient_id': 'patient-456',
        'name': 'Jane Doe',
        'phone': '+91 9876543210',
        'relationship': 'Spouse',
      });
      expect(fromJson.name, 'Jane Doe');
      expect(fromJson.relationship, 'Spouse');
    });

    testWidgets('Emergency Contact Screen displays network info and Add Contact action', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmergencyContactScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Emergency Contacts'), findsOneWidget);
      expect(find.text('Patient Emergency Network'), findsOneWidget);
      expect(find.byKey(const Key('add_emergency_contact_button')), findsOneWidget);
    });
  });
}
