import 'package:flutter/material.dart';
import 'package:careflow/screens/shared/feature_screen.dart';

class SymptomsScreen extends StatelessWidget {
  const SymptomsScreen({super.key});
  @override
  Widget build(BuildContext context) => FeatureScreen(
    title: 'Symptoms',
    subtitle: 'Record chief complaint and history',
    items: const [
      'Fever and body pain for 2 days',
      'Headache reported',
      'No cough or breathlessness',
    ],
  );
}
