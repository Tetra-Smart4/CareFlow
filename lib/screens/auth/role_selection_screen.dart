import 'package:flutter/material.dart';
import '../../core/theme/color_tokens.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: ColorTokens.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --------------------------------------------------------
                      // BRAND LOGO & HEADER
                      // --------------------------------------------------------
                      Center(
                        child: Image.asset(
                          'assets/images/careflow_logo.png',
                          height: 72,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: ColorTokens.lightBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: ColorTokens.primaryBlue,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'CAREFLOW',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: ColorTokens.darkNavy,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      const Text(
                        'Better care begins with better connections.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: ColorTokens.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // --------------------------------------------------------
                      // [ LOGIN ]
                      // --------------------------------------------------------
                      ElevatedButton(
                        key: const Key('login_button'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorTokens.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/auth/login'),
                        child: const Text(
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --------------------------------------------------------
                      // DIVIDER: New to CareFlow?
                      // --------------------------------------------------------
                      Row(
                        children: [
                          const Expanded(child: Divider(color: ColorTokens.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'New to CareFlow?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ColorTokens.textMuted.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: ColorTokens.border)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --------------------------------------------------------
                      // [ Register as Patient ]
                      // --------------------------------------------------------
                      OutlinedButton.icon(
                        key: const Key('register_patient_button'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorTokens.primaryBlue,
                          side: const BorderSide(color: ColorTokens.primaryBlue, width: 1.5),
                          backgroundColor: ColorTokens.lightBlue.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/auth/register-patient'),
                        icon: const Icon(Icons.person_outline_rounded, size: 22),
                        label: const Text(
                          'Register as Patient',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // --------------------------------------------------------
                      // [ Register as Clinic ]
                      // --------------------------------------------------------
                      OutlinedButton.icon(
                        key: const Key('register_clinic_button'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorTokens.careGreen,
                          side: const BorderSide(color: ColorTokens.careGreen, width: 1.5),
                          backgroundColor: ColorTokens.careGreen.withValues(alpha: 0.08),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/auth/register-clinic'),
                        icon: const Icon(Icons.local_hospital_outlined, size: 22),
                        label: const Text(
                          'Register as Clinic',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // --------------------------------------------------------
                      // NOTE & SECURITY BADGE
                      // --------------------------------------------------------
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: ColorTokens.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ColorTokens.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 16, color: ColorTokens.textMuted),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Doctor accounts are provisioned by registered clinics.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ColorTokens.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}