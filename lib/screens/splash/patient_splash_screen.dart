import 'dart:async';

import 'package:flutter/material.dart';

class PatientSplashScreen extends StatefulWidget {
  const PatientSplashScreen({super.key});

  @override
  State<PatientSplashScreen> createState() =>
      _PatientSplashScreenState();
}

class _PatientSplashScreenState extends State<PatientSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();

    // After the splash screen, open Patient Login.
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/auth/patient-login',
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final logoWidth = screenWidth < 500
        ? screenWidth * 0.78
        : 360.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ------------------------------------------------
                  // CAREFLOW LOGO
                  // ------------------------------------------------
                  Image.asset(
                    'assets/images/careflow_logo.png',
                    width: logoWidth,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 22),

                  // ------------------------------------------------
                  // TAGLINE
                  // ------------------------------------------------
                  const Text(
                    'Your Health Journey, Our Commitment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF557080),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}