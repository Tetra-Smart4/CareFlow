import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({
    super.key,
  });

  // --------------------------------------------------------------
  // CareFlow Theme
  // --------------------------------------------------------------

  static const Color primaryBlue = Color(0xFF1479D1);

  static const Color background = Color(0xFFF7FBFF);

  static const Color textDark = Color(0xFF12304A);

  static const Color textGrey = Color(0xFF6B7C8D);

  static const Color border = Color(0xFFD6E6F3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),

            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                24,
                45,
                24,
                30,
              ),

              children: [
                // ------------------------------------------------
                // CareFlow icon
                // ------------------------------------------------

                Center(
                  child: Container(
                    width: 64,
                    height: 64,

                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6FF),

                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: const Icon(
                      Icons.favorite_rounded,

                      color: primaryBlue,

                      size: 34,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                // ------------------------------------------------
                // Heading
                // ------------------------------------------------

                const Text(
                  'Welcome to CareFlow',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 28,

                    fontWeight: FontWeight.w800,

                    color: textDark,

                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                // ------------------------------------------------
                // Subtitle
                // ------------------------------------------------

                const Text(
                  'Choose your role to continue',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 15,

                    color: textGrey,

                    height: 1.4,
                  ),
                ),

                const SizedBox(
                  height: 38,
                ),

                // =================================================
                // PATIENT
                // =================================================

                _RoleCard(
                  title: 'Patient',

                  subtitle:
                      'Access your health records, appointments and prescriptions.',

                  icon: Icons.person_outline_rounded,

                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/auth/patient-login',
                    );
                  },
                ),

                const SizedBox(
                  height: 16,
                ),

                // =================================================
                // DOCTOR
                // =================================================

                _RoleCard(
                  title: 'Doctor',

                  subtitle:
                      'Manage patients, consultations, prescriptions and follow-ups.',

                  icon: Icons.medical_services_outlined,

                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/auth/doctor-login',
                    );
                  },
                ),

                const SizedBox(
                  height: 16,
                ),

                // =================================================
                // CLINIC
                // =================================================

                _RoleCard(
                  title: 'Clinic',

                  subtitle:
                      'Manage appointments, patients, doctors, queue and billing.',

                  icon: Icons.local_hospital_outlined,

                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/auth/admin-login',
                    );
                  },
                ),

                const SizedBox(
                  height: 38,
                ),

                // ------------------------------------------------
                // Security information
                // ------------------------------------------------

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,

                      size: 15,

                      color: textGrey,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Text(
                      'Secure healthcare access',

                      style: const TextStyle(
                        fontSize: 12,

                        color: textGrey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'CareFlow keeps your healthcare experience connected and secure.',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 11,

                    color: textGrey,

                    height: 1.4,
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

// ==================================================================
// ROLE CARD
// ==================================================================

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;

  final String subtitle;

  final IconData icon;

  final VoidCallback onTap;

  static const Color primaryBlue = Color(0xFF1479D1);

  static const Color textDark = Color(0xFF12304A);

  static const Color textGrey = Color(0xFF6B7C8D);

  static const Color border = Color(0xFFD6E6F3);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,

      borderRadius: BorderRadius.circular(18),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(18),

        child: Container(
          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: border,

              width: 1,
            ),
          ),

          child: Row(
            children: [
              // --------------------------------------------------
              // Icon
              // --------------------------------------------------

              Container(
                width: 58,
                height: 58,

                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6FF),

                  borderRadius: BorderRadius.circular(16),
                ),

                child: Icon(
                  icon,

                  color: primaryBlue,

                  size: 29,
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              // --------------------------------------------------
              // Text
              // --------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style: const TextStyle(
                        fontSize: 17,

                        fontWeight: FontWeight.w700,

                        color: textDark,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      subtitle,

                      maxLines: 2,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 12,

                        color: textGrey,

                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // --------------------------------------------------
              // Arrow
              // --------------------------------------------------

              const Icon(
                Icons.arrow_forward_ios_rounded,

                size: 17,

                color: textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}