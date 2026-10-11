import 'package:flutter/material.dart';

import 'login_screen.dart';

class StaffLoginScreen extends StatelessWidget {
  const StaffLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(
      initialRole: LoginRole.staff,
    );
  }
}
