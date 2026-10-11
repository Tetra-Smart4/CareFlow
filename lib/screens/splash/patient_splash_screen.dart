import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

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

    // Check existing session on startup and navigate appropriately
    Timer(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;

      final targetRoute = await AuthService().getInitialRoute();
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        targetRoute,
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
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFF1677E8),
                      size: 64,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'CareFlow',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF10245C),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Better care begins with better connections.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
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