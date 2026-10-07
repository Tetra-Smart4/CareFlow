import 'package:flutter/material.dart';
import 'package:careflow/screens/shared/feature_screen.dart';

class DoctorAppointmentDetailsScreen extends StatelessWidget {
  const DoctorAppointmentDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) => const FeatureScreen(
    title: 'Appointment Details',
    subtitle: 'Amit Kumar • General Checkup',
    items: [
      '10:00 AM',
      'Confirmed',
      'Patient age 28 • Male',
      'Emergency contact on file',
    ],
  );
}
