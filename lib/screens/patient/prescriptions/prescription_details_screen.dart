import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';

class PrescriptionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic>? prescription;

  const PrescriptionDetailsScreen({super.key, this.prescription});

  Widget _buildSectionCard({
    required String stepNumber,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stepNumber.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: iconColor,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ColorTokens.darkNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: ColorTokens.border),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isEmphasized = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: ColorTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isEmphasized ? FontWeight.w800 : FontWeight.w600,
                color: isEmphasized ? ColorTokens.primaryBlue : ColorTokens.darkNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

    final medicineName = presc['medicine_name'] ?? presc['name'] ?? 'Prescription Medication';
    final dosage = presc['dosage'] ?? 'As directed by physician';
    final frequency = presc['frequency'] ?? 'Daily';
    final instructions = presc['instructions'] ?? 'Take strictly as instructed by your doctor.';
    final indication = presc['indication'] ?? presc['reason'] ?? presc['diagnosis'] ?? 'Not specified by clinician';
    final duration = presc['duration'] ?? 'As prescribed';
    final route = presc['route'] ?? 'Oral';
    final doctor = presc['doctor_name'] ?? 'Treating Physician';
    final spec = presc['doctor_specialization'] ?? 'Specialist';
    final date = presc['created_at'] != null ? presc['created_at'].toString().split('T').first : 'Recent';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medication Guide & Safety'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Medicine Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ColorTokens.border),
              ),
              child: Row(
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
                          medicineName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: ColorTokens.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Prescribed by Dr. $doctor ($spec)',
                          style: const TextStyle(fontSize: 12.5, color: ColorTokens.primaryBlue, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Issued: $date',
                          style: const TextStyle(fontSize: 12, color: ColorTokens.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1. WHAT IS THIS MEDICINE?
            _buildSectionCard(
              stepNumber: 'Section 1',
              title: 'What is this medicine?',
              icon: Icons.info_outline_rounded,
              iconColor: ColorTokens.primaryBlue,
              children: [
                _buildInfoRow('Medicine Name', medicineName, isEmphasized: true),
                _buildInfoRow('Strength / Dosage', dosage),
                _buildInfoRow('Administration Route', route),
                _buildInfoRow('Prescription Duration', duration),
                const SizedBox(height: 4),
                const Text(
                  'This is an authorized therapeutic pharmaceutical product prescribed specifically for your medical condition. The active pharmaceutical ingredient works according to clinical guidelines.',
                  style: TextStyle(fontSize: 12.5, color: ColorTokens.muted, height: 1.4),
                ),
              ],
            ),

            // 2. WHY DID YOUR DOCTOR PRESCRIBE IT?
            _buildSectionCard(
              stepNumber: 'Section 2',
              title: 'Why did your doctor prescribe it?',
              icon: Icons.medical_services_outlined,
              iconColor: ColorTokens.careGreen,
              children: [
                _buildInfoRow('Recorded Clinical Indication', indication, isEmphasized: true),
                const SizedBox(height: 4),
                Text(
                  indication == 'Not specified by clinician'
                      ? 'Note: The prescribing clinician did not enter an explicit diagnosis code for this individual item. This medication is part of your official consultation care plan.'
                      : 'This medication was specifically selected by your doctor to treat the recorded clinical indication above.',
                  style: const TextStyle(fontSize: 12.5, color: ColorTokens.muted, height: 1.4),
                ),
              ],
            ),

            // 3. HOW SHOULD YOU TAKE IT?
            _buildSectionCard(
              stepNumber: 'Section 3',
              title: 'How should you take it?',
              icon: Icons.schedule_rounded,
              iconColor: ColorTokens.warning,
              children: [
                _buildInfoRow('Prescribed Schedule', frequency, isEmphasized: true),
                _buildInfoRow('Dosage Quantity', dosage),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorTokens.lightWarning,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Physician Directions:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        instructions,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ColorTokens.darkNavy),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Take the medication at the same time each day. If a dose is missed, take it as soon as remembered unless it is almost time for the next dose. Never double up doses.',
                  style: TextStyle(fontSize: 12, color: ColorTokens.muted, height: 1.4),
                ),
              ],
            ),

            // 4. WHAT SHOULD YOU KNOW?
            _buildSectionCard(
              stepNumber: 'Section 4',
              title: 'What should you know?',
              icon: Icons.shield_outlined,
              iconColor: ColorTokens.navy,
              children: [
                _buildInfoRow('Storage Condition', 'Store below 25°C in a dry place away from sunlight'),
                _buildInfoRow('Alcohol & Interactions', 'Consult doctor before consuming alcohol'),
                _buildInfoRow('General Precautions', 'Keep out of reach of children. Do not share medication'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorTokens.lightBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Safety Alert: If you experience unexpected symptoms such as severe rash, facial swelling, breathing difficulty, or dizziness, seek emergency medical care immediately.',
                    style: TextStyle(fontSize: 12, color: ColorTokens.darkNavy, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            // 5. WHERE CAN YOU LEARN MORE?
            _buildSectionCard(
              stepNumber: 'Section 5',
              title: 'Where can you learn more?',
              icon: Icons.menu_book_rounded,
              iconColor: ColorTokens.primaryBlue,
              children: [
                _buildInfoRow('Prescribing Clinic', 'CareFlow Network Clinic'),
                _buildInfoRow('Medical Reference Source', 'MedlinePlus / National Drug Information Standards'),
                _buildInfoRow('Last Clinical Review', date),
                const SizedBox(height: 6),
                const Text(
                  'For inquiries regarding side effects or dosage adjustments, contact your prescribing clinic directly or consult your licensed pharmacist. Never discontinue prescribed treatment without medical consultation.',
                  style: TextStyle(fontSize: 12, color: ColorTokens.muted, height: 1.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
