import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';

class RecordDetailsScreen extends StatelessWidget {
  final Map<String, dynamic>? record;

  const RecordDetailsScreen({super.key, this.record});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? rec = record;
    if (rec == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        rec = args;
      }
    }

    if (rec == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Consultation Details')),
        body: const Center(child: Text('No record data received.')),
      );
    }

    final diagnosis = rec['diagnosis'] ?? 'Clinical Consultation';
    final doctor = rec['doctor_name'] ?? 'Doctor';
    final spec = rec['doctor_specialization'] ?? 'Specialist';
    final date = rec['created_at'] != null ? rec['created_at'].toString().split('T').first : 'Recent Visit';
    final symptoms = rec['symptoms'] ?? 'None recorded';
    final notes = rec['notes'] ?? 'No additional clinical notes recorded.';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consultation Summary'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: ColorTokens.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: ColorTokens.lightGreen,
                          child: const Icon(Icons.verified_user_rounded, color: ColorTokens.careGreen, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                diagnosis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: ColorTokens.darkNavy,
                                ),
                              ),
                              Text(
                                '$doctor • $spec',
                                style: const TextStyle(fontSize: 13, color: ColorTokens.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: ColorTokens.border),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Encounter Date', style: TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
                        Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Symptoms Card
            _buildSectionCard(
              icon: Icons.sick_outlined,
              title: 'Reported Symptoms',
              content: symptoms,
            ),
            const SizedBox(height: 14),

            // Clinical Findings & Notes Card
            _buildSectionCard(
              icon: Icons.notes_rounded,
              title: 'Clinical Notes & Treatment Plan',
              content: notes,
            ),
            const SizedBox(height: 16),

            // Medical Integrity Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ColorTokens.lightBlue,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ColorTokens.primaryBlue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined, color: ColorTokens.primaryBlue, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Official Clinical Record: Certified by attending physician. Patient records are cryptographically protected.',
                      style: TextStyle(fontSize: 12, color: ColorTokens.darkNavy, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/patient/prescriptions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('View Prescriptions in Health', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ColorTokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: ColorTokens.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(fontSize: 13, height: 1.4, color: ColorTokens.darkNavy),
            ),
          ],
        ),
      ),
    );
  }
}
