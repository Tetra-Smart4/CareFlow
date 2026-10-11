import 'dart:async';
import '../../services/auth_service.dart';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;

      final initialRoute = await AuthService().getInitialRoute();

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        initialRoute,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1976D2);
    const Color primaryGreen = Color(0xFF26A69A);
    const Color background = Color(0xFFF7FAFC);
    const Color textPrimary = Color(0xFF172033);
    const Color textSecondary = Color(0xFF667085);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ----------------------------------------------------------
                // CAREFLOW LOGO
                // ----------------------------------------------------------

                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        primaryBlue,
                        primaryGreen,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(
                          alpha: 0.18,
                        ),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 58,
                  ),
                ),

                const SizedBox(height: 28),

                // ----------------------------------------------------------
                // APP NAME
                // ----------------------------------------------------------

                const Text(
                  'CareFlow',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: primaryBlue,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Connected care, better health.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Your health journey in one place',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 42),

                // ----------------------------------------------------------
                // LOADING INDICATOR
                // ----------------------------------------------------------

                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      primaryBlue,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Getting things ready...',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}