import 'package:flutter/material.dart';
import 'package:careflow/screens/shared/feature_screen.dart';

class DoctorAvailabilityScreen extends StatelessWidget {
  const DoctorAvailabilityScreen({super.key});
  @override
  Widget build(BuildContext context) => const FeatureScreen(
    title: 'Doctor Availability',
    subtitle: 'Select a day and available slot',
    items: [
      'Tuesday • 10:00 AM',
      'Tuesday • 10:30 AM',
      'Wednesday • 9:30 AM',
      'Thursday • 11:00 AM',
    ],
  );
}
