import 'package:flutter/material.dart';
import 'patient_registration_screen.dart';
import 'clinic_registration_screen.dart';

enum RegistrationType {
  patient,
  clinic,
}

class RegisterScreen extends StatefulWidget {
  final RegistrationType initialType;

  const RegisterScreen({
    super.key,
    this.initialType = RegistrationType.patient,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late RegistrationType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    return _selectedType == RegistrationType.patient
        ? const PatientRegistrationScreen()
        : const ClinicRegistrationScreen();
  }
}