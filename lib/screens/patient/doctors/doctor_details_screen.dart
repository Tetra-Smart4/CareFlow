import 'package:flutter/material.dart';
import 'package:careflow/screens/shared/feature_screen.dart';

class DoctorDetailsScreen extends StatelessWidget {
  const DoctorDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) => FeatureScreen(
    title: 'Dr. Priya Sharma',
    subtitle: 'General Physician • 8 years experience • ★ 4.8',
    items: const [
      'Available today',
      'Consultation fee ₹500',
      'Mon–Sat, 9:00 AM–2:00 PM',
      'City Care Clinic',
    ],
    actions: [
      FeatureAction('Book Appointment', Icons.calendar_month, () {
        Navigator.pushNamed(context, '/patient/appointments/book');
      }),
    ],
  );
}
