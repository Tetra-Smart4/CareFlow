import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../models/medicine_item.dart';

class MedicineDetailsScreen extends StatelessWidget {
  final MedicineItem medicine;
  final String role; // 'patient', 'doctor', 'clinic', etc.

  const MedicineDetailsScreen({
    super.key,
    required this.medicine,
    this.role = 'patient',
  });

  Color get _roleAccentColor {
    switch (role.toLowerCase()) {
      case 'doctor':
        return const Color(0xFF0284C7);
      case 'clinic':
      case 'admin':
        return const Color(0xFFD97706);
      case 'patient':
      default:
        return const Color(0xFF0D9488);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: Text(
          medicine.name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Share reference',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Clinical reference for ${medicine.name} copied.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // 1. Header Card with Verification Status
          _buildHeroHeaderCard(),
          const SizedBox(height: 16),

          // 2. Medical Advice Disclaimer Banner & Unverified Alert
          _buildMedicalDisclaimerBanner(),
          const SizedBox(height: 16),

          // 3. Overview & Composition
          _buildSectionCard(
            title: 'Overview & Composition',
            icon: Icons.biotech_outlined,
            children: [
              Text(
                medicine.overview,
                style: const TextStyle(
                  fontSize: 14,
                  color: ColorTokens.darkNavy,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              _buildInfoRow('Generic Name', medicine.genericName),
              _buildInfoRow('Strength', medicine.strength),
              _buildInfoRow('Dosage Form', '${medicine.dosageForm} (${medicine.dosageCategory})'),
              _buildInfoRow('Route', medicine.route.toUpperCase()),
              if (medicine.brandName != null) _buildInfoRow('Brand Name', medicine.brandName!),
              if (medicine.manufacturer != null) _buildInfoRow('Manufacturer', medicine.manufacturer!),
              if (medicine.mrpInr != null) _buildInfoRow('Government MRP', '₹${medicine.mrpInr!.toStringAsFixed(2)}', highlightColor: ColorTokens.primaryBlue),
              _buildInfoRow(
                'Prescription Status',
                medicine.isPrescriptionRequired ? 'Rx Required (Schedule H/H1)' : 'Over-the-Counter (OTC)',
                highlightColor: medicine.isPrescriptionRequired ? ColorTokens.error : ColorTokens.careGreen,
              ),
              const SizedBox(height: 8),
              const Text(
                'Active Ingredients & Composition:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
              ),
              const SizedBox(height: 6),
              ...medicine.ingredients.map(
                (ing) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 14, color: ColorTokens.careGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ing,
                          style: const TextStyle(fontSize: 13, color: ColorTokens.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4. Common Indications & Uses
          if (medicine.commonUses.isNotEmpty) ...[
            _buildSectionCard(
              title: 'Common Uses & Indications',
              icon: Icons.healing_outlined,
              children: [
                ...medicine.commonUses.map(
                  (use) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _roleAccentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            use,
                            style: const TextStyle(fontSize: 13.5, color: ColorTokens.darkNavy, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // 5. Precautions & Contraindications
          _buildSectionCard(
            title: 'Precautions & Contraindications',
            icon: Icons.shield_outlined,
            children: [
              if (medicine.contraindications.isNotEmpty) ...[
                const Text(
                  'Contraindications (Do NOT Take If):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ColorTokens.error),
                ),
                const SizedBox(height: 6),
                ...medicine.contraindications.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cancel_rounded, size: 15, color: ColorTokens.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c,
                            style: const TextStyle(fontSize: 13, color: ColorTokens.darkNavy, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (medicine.precautions.isNotEmpty) ...[
                const Text(
                  'Clinical Precautions:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ColorTokens.warning),
                ),
                const SizedBox(height: 6),
                ...medicine.precautions.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 15, color: ColorTokens.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p,
                            style: const TextStyle(fontSize: 13, color: ColorTokens.darkNavy, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // 6. Side Effects
          if (medicine.sideEffects.isNotEmpty) ...[
            _buildSectionCard(
              title: 'Known Side Effects',
              icon: Icons.report_problem_outlined,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: medicine.sideEffects.map((se) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ColorTokens.border),
                      ),
                      child: Text(
                        se,
                        style: const TextStyle(fontSize: 12.5, color: ColorTokens.darkNavy, fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Report any persistent or severe adverse effects to your treating physician.',
                  style: TextStyle(fontSize: 11.5, color: ColorTokens.textMuted, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // 7. Drug-Drug Interactions
          if (medicine.drugInteractions.isNotEmpty) ...[
            _buildSectionCard(
              title: 'Drug-Drug Interactions',
              icon: Icons.sync_problem_rounded,
              children: [
                ...medicine.drugInteractions.map((inter) {
                  final isMajor = inter.severity.toLowerCase() == 'major';
                  final badgeColor = isMajor ? ColorTokens.error : ColorTokens.warning;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              inter.interactingDrug,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                inter.severity.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          inter.clinicalEffect,
                          style: const TextStyle(fontSize: 12.5, color: ColorTokens.darkNavy, height: 1.3),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Management: ${inter.management}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: badgeColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Source: ${inter.evidenceSource}',
                          style: const TextStyle(fontSize: 10.5, color: ColorTokens.textMuted),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // 8. Storage & Regulatory Verification Sources
          _buildSectionCard(
            title: 'Storage & Regulatory Verification',
            icon: Icons.verified_user_outlined,
            children: [
              if (medicine.storageInfo != null) ...[
                _buildInfoRow('Storage Conditions', medicine.storageInfo!),
                const SizedBox(height: 8),
              ],
              _buildInfoRow('Product Identity', medicine.identityVerificationStatus.displayName,
                  highlightColor: medicine.identityVerificationStatus == IdentityVerificationStatus.sourceConfirmed ||
                          medicine.identityVerificationStatus == IdentityVerificationStatus.regulatoryRegistered
                      ? ColorTokens.careGreen
                      : ColorTokens.warning),
              _buildInfoRow('Clinical Monograph', medicine.clinicalVerificationStatus.displayName,
                  highlightColor: medicine.clinicalVerificationStatus == ClinicalVerificationStatus.clinicallyReviewed
                      ? ColorTokens.careGreen
                      : (medicine.clinicalVerificationStatus == ClinicalVerificationStatus.monographLinked
                          ? ColorTokens.primaryBlue
                          : ColorTokens.error)),
              _buildInfoRow('Verification Scope', medicine.verificationScope),
              if (medicine.sourceMetadata['source_record_id'] != null)
                _buildInfoRow('Drug Code / SKU', medicine.sourceMetadata['source_record_id'].toString()),
              if (medicine.sourceMetadata['source_name'] != null)
                _buildInfoRow('Origin Source', medicine.sourceMetadata['source_name'].toString()),
              if (medicine.lastReviewedDate != null) _buildInfoRow('Last Reviewed', medicine.lastReviewedDate!),
              const SizedBox(height: 8),
              const Text(
                'Authoritative Reference Sources:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
              ),
              const SizedBox(height: 6),
              ...medicine.sourceReferences.map(
                (src) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.library_books_rounded, size: 14, color: ColorTokens.primaryBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          src,
                          style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Attribution: Clinical concepts and chemical definitions mapped to public domain datasets from the U.S. National Library of Medicine (NLM), NIH, and the Ministry of Chemicals & Fertilizers, Government of India.',
                  style: TextStyle(fontSize: 11, color: ColorTokens.textMuted, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Contextual Action Button
          _buildContextualActionButton(context),
        ],
      ),
    );
  }

  Widget _buildHeroHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorTokens.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorTokens.lightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  medicine.classification.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: ColorTokens.primaryBlue,
                  ),
                ),
              ),
              // Badge 1: Product Identity
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: medicine.identityVerificationStatus == IdentityVerificationStatus.sourceConfirmed ||
                          medicine.identityVerificationStatus == IdentityVerificationStatus.regulatoryRegistered
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: medicine.identityVerificationStatus == IdentityVerificationStatus.sourceConfirmed ||
                            medicine.identityVerificationStatus == IdentityVerificationStatus.regulatoryRegistered
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      medicine.identityVerificationStatus == IdentityVerificationStatus.sourceConfirmed ||
                              medicine.identityVerificationStatus == IdentityVerificationStatus.regulatoryRegistered
                          ? Icons.verified_rounded
                          : Icons.help_outline_rounded,
                      size: 13,
                      color: medicine.identityVerificationStatus == IdentityVerificationStatus.sourceConfirmed ||
                              medicine.identityVerificationStatus == IdentityVerificationStatus.regulatoryRegistered
                          ? const Color(0xFF10B981)
                          : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      medicine.identityVerificationStatus.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: medicine.identityVerificationStatus == IdentityVerificationStatus.sourceConfirmed ||
                                medicine.identityVerificationStatus == IdentityVerificationStatus.regulatoryRegistered
                            ? const Color(0xFF047857)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              // Badge 2: Clinical Evidence
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: medicine.clinicalVerificationStatus == ClinicalVerificationStatus.clinicallyReviewed
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : (medicine.clinicalVerificationStatus == ClinicalVerificationStatus.monographLinked
                          ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                          : const Color(0xFFEF4444).withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: medicine.clinicalVerificationStatus == ClinicalVerificationStatus.clinicallyReviewed
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : (medicine.clinicalVerificationStatus == ClinicalVerificationStatus.monographLinked
                            ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                            : const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      medicine.clinicalVerificationStatus == ClinicalVerificationStatus.clinicallyReviewed
                          ? Icons.local_hospital_rounded
                          : (medicine.clinicalVerificationStatus == ClinicalVerificationStatus.monographLinked
                              ? Icons.menu_book_rounded
                              : Icons.warning_amber_rounded),
                      size: 13,
                      color: medicine.clinicalVerificationStatus == ClinicalVerificationStatus.clinicallyReviewed
                          ? const Color(0xFF10B981)
                          : (medicine.clinicalVerificationStatus == ClinicalVerificationStatus.monographLinked
                              ? const Color(0xFF0284C7)
                              : const Color(0xFFEF4444)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      medicine.clinicalVerificationStatus.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: medicine.clinicalVerificationStatus == ClinicalVerificationStatus.clinicallyReviewed
                            ? const Color(0xFF047857)
                            : (medicine.clinicalVerificationStatus == ClinicalVerificationStatus.monographLinked
                                ? const Color(0xFF0369A1)
                                : const Color(0xFFB91C1C)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            medicine.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: ColorTokens.darkNavy,
            ),
          ),
          if (medicine.genericName.isNotEmpty && medicine.genericName != medicine.name) ...[
            const SizedBox(height: 3),
            Text(
              medicine.genericName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ColorTokens.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.medication_liquid_rounded, size: 16, color: ColorTokens.darkNavy),
                const SizedBox(width: 6),
                Text(
                  '${medicine.dosageForm} • ${medicine.strength}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ColorTokens.darkNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalDisclaimerBanner() {
    final isClinicallyUnverified = medicine.clinicalVerificationStatus == ClinicalVerificationStatus.unverified;
    return Column(
      children: [
        if (isClinicallyUnverified) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.report_problem_rounded, color: ColorTokens.error, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Unreviewed Clinical Monograph: Clinical indications, interactions, and contraindications for this imported medicine have not yet been signed off by a licensed medical practitioner. Use for identification only.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF991B1B),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info_rounded, color: Color(0xFFB45309), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Educational medical reference only. Never start, stop, or adjust prescription medication without consulting a qualified healthcare professional.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _roleAccentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ColorTokens.darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: ColorTokens.textMuted, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: highlightColor ?? ColorTokens.darkNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextualActionButton(BuildContext context) {
    if (role == 'doctor') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0284C7),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text(
          'Prescribe This Medicine in Consultation',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/doctor/consultation/prescription');
        },
      );
    }

    if (role == 'clinic' || role == 'admin') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD97706),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.inventory_2_outlined, color: Colors.white),
        label: const Text(
          'Check Clinic Inventory Stock',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/clinic/inventory');
        },
      );
    }

    // Default Patient
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D9488),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.alarm_add_rounded, color: Colors.white),
      label: const Text(
        'Add Medication Dose Reminder',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      onPressed: () {
        Navigator.pushNamed(context, '/patient/medications/reminder');
      },
    );
  }
}
