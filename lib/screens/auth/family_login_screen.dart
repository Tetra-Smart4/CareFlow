import 'package:flutter/material.dart';

import 'login_screen.dart';

class FamilyLoginScreen extends StatelessWidget {
  const FamilyLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(
      initialRole: LoginRole.family,
    );
  }
}
