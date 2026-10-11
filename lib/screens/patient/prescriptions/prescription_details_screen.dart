import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';

class PrescriptionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic>? prescription;

  const PrescriptionDetailsScreen({super.key, this.prescription});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? presc = prescription;
    if (presc == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        presc = args;
      }
    }

    if (presc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Prescription Details')),
        body: const Center(child: Text('No prescription data received.')),
      );
    }

    final med = presc['medicine_name'] ?? 'Prescription Medicine';
    final dosage = presc['dosage'] ?? 'As directed';
    final freq = presc['frequency'] ?? 'Daily';
    final instructions = presc['instructions'] ?? 'Take as instructed by physician.';
    final doctor = presc['doctor_name'] ?? 'Doctor';
    final spec = presc['doctor_specialization'] ?? 'Specialist';
    final date = presc['created_at'] != null ? presc['created_at'].toString().split('T').first : 'Recent';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prescription Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Medicine Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: ColorTokens.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: ColorTokens.lightGreen,
                          child: const Icon(Icons.medication_rounded, color: ColorTokens.careGreen, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: ColorTokens.darkNavy,
                                ),
                              ),
                              Text(
                                'Dosage: $dosage',
                                style: const TextStyle(fontSize: 13, color: ColorTokens.textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: ColorTokens.border),
                    const SizedBox(height: 14),
                    _buildRow('Prescribing Doctor', '$doctor ($spec)'),
                    const SizedBox(height: 10),
                    _buildRow('Date Issued', date),
                    const SizedBox(height: 10),
                    _buildRow('Frequency', freq),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Instructions Card
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
                      children: const [
                        Icon(Icons.info_outline_rounded, color: ColorTokens.primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Dosage & Timing Instructions',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      instructions,
                      style: const TextStyle(fontSize: 13, height: 1.4, color: ColorTokens.darkNavy),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Protection notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ColorTokens.lightBlue,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ColorTokens.primaryBlue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.verified_rounded, color: ColorTokens.primaryBlue, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Official prescription issued by certified healthcare provider. Always follow prescribed timing and complete full course.',
                      style: TextStyle(fontSize: 12, color: ColorTokens.darkNavy, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
          ),
        ),
      ],
    );
  }
}
