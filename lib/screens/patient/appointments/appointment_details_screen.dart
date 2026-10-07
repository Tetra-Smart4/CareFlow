import 'package:flutter/material.dart';
import 'package:careflow/screens/shared/feature_screen.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  const AppointmentDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) => const FeatureScreen(
    title: 'Appointment Details',
    subtitle: 'Dr. Priya Sharma • General Physician',
    items: [
      'Date • Tuesday, 8 October 2024',
      'Time • 10:00 AM',
      'Location • CareFlow Clinic',
      'Status • Confirmed',
    ],
  );
}
