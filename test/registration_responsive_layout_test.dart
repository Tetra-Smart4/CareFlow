import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:careflow/screens/auth/patient_registration_screen.dart';
import 'package:careflow/screens/auth/clinic_registration_screen.dart';

void main() {
  group('Patient Registration Responsive Layout Tests', () {
    testWidgets('Renders on small mobile screen (360x800) without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientRegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify section headers
      expect(find.text('1. Account Details'), findsOneWidget);
      expect(find.text('2. Personal Details'), findsOneWidget);

      // Verify all Row 1 to Row 6 fields exist and are rendered
      expect(find.byKey(const Key('patient_name_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_email_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_dob_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_password_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_confirm_password_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_gender_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_city_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_state_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_pincode_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_address_field')), findsOneWidget);

      // Submit button is present
      expect(find.byKey(const Key('submit_patient_registration_button')), findsOneWidget);
    });

    testWidgets('Renders on wider screen (800x1000) with row-wise arrangement', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientRegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Row 1: Full Name and Email Address are horizontally aligned (same Top Y)
      final nameTop = tester.getTopLeft(find.byKey(const Key('patient_name_field'))).dy;
      final emailTop = tester.getTopLeft(find.byKey(const Key('patient_email_field'))).dy;
      expect((nameTop - emailTop).abs(), lessThan(4.0));

      // Row 2: Phone Number and DOB are horizontally aligned
      final phoneTop = tester.getTopLeft(find.byKey(const Key('patient_phone_field'))).dy;
      final dobTop = tester.getTopLeft(find.byKey(const Key('patient_dob_field'))).dy;
      expect((phoneTop - dobTop).abs(), lessThan(4.0));

      // Row 3: Password and Confirm Password are horizontally aligned
      final pwdTop = tester.getTopLeft(find.byKey(const Key('patient_password_field'))).dy;
      final confirmTop = tester.getTopLeft(find.byKey(const Key('patient_confirm_password_field'))).dy;
      expect((pwdTop - confirmTop).abs(), lessThan(4.0));

      // Row 4: Gender and City are horizontally aligned
      final genderTop = tester.getTopLeft(find.byKey(const Key('patient_gender_field'))).dy;
      final cityTop = tester.getTopLeft(find.byKey(const Key('patient_city_field'))).dy;
      expect((genderTop - cityTop).abs(), lessThan(4.0));

      // Row 5: State and Pincode are horizontally aligned
      final stateTop = tester.getTopLeft(find.byKey(const Key('patient_state_field'))).dy;
      final pincodeTop = tester.getTopLeft(find.byKey(const Key('patient_pincode_field'))).dy;
      expect((stateTop - pincodeTop).abs(), lessThan(4.0));

      // Row 6: Street Address is below Row 5
      final addressTop = tester.getTopLeft(find.byKey(const Key('patient_address_field'))).dy;
      expect(addressTop, greaterThan(stateTop));
    });
  });

  group('Clinic Registration Responsive Layout Tests', () {
    testWidgets('Renders on small mobile screen (360x900) without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ClinicRegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify section headers
      expect(find.text('1. Clinic Details'), findsOneWidget);
      expect(find.text('2. Authorized Account Contact'), findsOneWidget);

      // Verify all fields are present
      expect(find.byKey(const Key('clinic_name_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_email_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_password_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_confirm_password_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_type_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_address_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_city_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_state_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_pincode_field')), findsOneWidget);
      expect(find.byKey(const Key('contact_name_field')), findsOneWidget);
      expect(find.byKey(const Key('contact_email_field')), findsOneWidget);
      expect(find.byKey(const Key('contact_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('clinic_about_field')), findsOneWidget);

      expect(find.textContaining('PENDING status'), findsOneWidget);
      expect(find.byKey(const Key('submit_clinic_registration_button')), findsOneWidget);
    });

    testWidgets('Renders on wider screen (800x1100) with row-wise arrangement', (tester) async {
      tester.view.physicalSize = const Size(800, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ClinicRegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Row 1: Clinic Name and Email Address are horizontally aligned
      final clinicNameTop = tester.getTopLeft(find.byKey(const Key('clinic_name_field'))).dy;
      final clinicEmailTop = tester.getTopLeft(find.byKey(const Key('clinic_email_field'))).dy;
      expect((clinicNameTop - clinicEmailTop).abs(), lessThan(4.0));

      // Row 2: Phone Number and Password are horizontally aligned
      final clinicPhoneTop = tester.getTopLeft(find.byKey(const Key('clinic_phone_field'))).dy;
      final clinicPwdTop = tester.getTopLeft(find.byKey(const Key('clinic_password_field'))).dy;
      expect((clinicPhoneTop - clinicPwdTop).abs(), lessThan(4.0));

      // Row 3: Confirm Password and Clinic Type are horizontally aligned
      final clinicConfirmTop = tester.getTopLeft(find.byKey(const Key('clinic_confirm_password_field'))).dy;
      final clinicTypeTop = tester.getTopLeft(find.byKey(const Key('clinic_type_field'))).dy;
      expect((clinicConfirmTop - clinicTypeTop).abs(), lessThan(4.0));

      // Row 4: Street Address is full width below Row 3
      final clinicAddrTop = tester.getTopLeft(find.byKey(const Key('clinic_address_field'))).dy;
      expect(clinicAddrTop, greaterThan(clinicConfirmTop));

      // Row 5: City, State, and Pincode are all 3 horizontally aligned
      final cityTop = tester.getTopLeft(find.byKey(const Key('clinic_city_field'))).dy;
      final stateTop = tester.getTopLeft(find.byKey(const Key('clinic_state_field'))).dy;
      final pincodeTop = tester.getTopLeft(find.byKey(const Key('clinic_pincode_field'))).dy;
      expect((cityTop - stateTop).abs(), lessThan(4.0));
      expect((cityTop - pincodeTop).abs(), lessThan(4.0));
    });
  });
}
