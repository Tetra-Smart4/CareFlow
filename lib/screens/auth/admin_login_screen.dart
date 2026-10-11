import 'package:flutter/material.dart';
import 'login_screen.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialRole: LoginRole.clinic);
  }
}