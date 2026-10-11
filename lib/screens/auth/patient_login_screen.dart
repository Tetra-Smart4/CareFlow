import 'package:flutter/material.dart';
import 'login_screen.dart';

class PatientLoginScreen extends StatelessWidget {
  const PatientLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialRole: LoginRole.patient);
  }
}