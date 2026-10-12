import 'package:flutter/material.dart';
import 'find_patient_walkin_screen.dart';

/// Legacy alias for FindPatientWalkInScreen.
/// Replaces the old static patient creator with the real CareFlow patient search
/// and walk-in encounter workflow adhering to patient data ownership rules.
class AddPatientScreen extends StatelessWidget {
  const AddPatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FindPatientWalkInScreen();
  }
}
