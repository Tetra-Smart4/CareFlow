import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../models/patient_medical_history.dart';
import '../../../repositories/patient_medical_history_repository.dart';
import '../../../repositories/medical_record_repository.dart';
import '../../../repositories/prescription_repository.dart';
import '../../../repositories/report_repository.dart';
import 'package:careflow/widgets/common/lottie_animation.dart';

class DoctorMedicalHistoryScreen extends StatefulWidget {
  final Map<String, dynamic>? args;
  const DoctorMedicalHistoryScreen({super.key, this.args});

  @override
  State<DoctorMedicalHistoryScreen> createState() => _DoctorMedicalHistoryScreenState();
}

class _DoctorMedicalHistoryScreenState extends State<DoctorMedicalHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _historyRepo = PatientMedicalHistoryRepository();
  final _recordRepo = MedicalRecordRepository();
  final _prescRepo = PrescriptionRepository();
  final _reportRepo = ReportRepository();

  bool _loading = true;
  String? _error;
  String? _patientId;
  String? _patientName;

  PatientMedicalHistory? _questionnaire;
  List<Map<String, dynamic>> _consultations = [];
  List<Map<String, dynamic>> _prescriptions = [];
  List<dynamic> _reports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalArgs = ModalRoute.of(context)?.settings.arguments;
    final combined = widget.args ?? (modalArgs is Map<String, dynamic> ? modalArgs : {});
    _patientId ??= combined['patientId']?.toString();
    _patientName ??= combined['patientName']?.toString() ?? 'Patient';

    if (_patientId != null && _loading) {
      _loadPatientData();
    } else if (_patientId == null && _loading) {
      setState(() {
        _loading = false;
        _error = 'No patient specified for medical history review.';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pid = _patientId!;
      final history = await _historyRepo.getHistory(pid);
      final consults = await _recordRepo.list(patientId: pid);
      final prescs = await _prescRepo.list(patientId: pid);
      final reps = await _reportRepo.listForPatient(pid);

      if (mounted) {
        setState(() {
          _questionnaire = history;
          _consultations = consults;
          _prescriptions = prescs;
          _reports = reps;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load medical history: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: Text(_patientName != null ? '$_patientName\'s Medical Record' : 'Patient Medical History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading || _patientId == null ? null : _loadPatientData,
            tooltip: 'Refresh Records',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorTokens.primaryBlue,
          unselectedLabelColor: ColorTokens.textSecondary,
          indicatorColor: ColorTokens.primaryBlue,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Patient Questionnaire'),
            Tab(text: 'Verified Consultations'),
            Tab(text: 'Prescriptions'),
            Tab(text: 'Reports & Scans'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, size: 48, color: ColorTokens.primaryBlue),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: ColorTokens.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _patientId != null ? _loadPatientData : () => Navigator.pop(context), child: Text(_patientId != null ? 'Retry' : 'Go Back')),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQuestionnaireTab(),
                    _buildConsultationsTab(),
                    _buildPrescriptionsTab(),
                    _buildReportsTab(),
                  ],
                ),
    );
  }

  Widget _buildQuestionnaireTab() {
    if (_questionnaire == null || _questionnaire!.questionnaireData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              LottieAnimation(
                assetName: 'assets/animations/empty.json',
                width: 110,
                fallback: Icon(Icons.assignment_late_outlined, size: 48, color: ColorTokens.muted),
              ),
              SizedBox(height: 12),
              Text('No Patient Questionnaire Submitted', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: ColorTokens.darkNavy)),
              SizedBox(height: 6),
              Text('The patient has not completed their initial medical questionnaire yet.', textAlign: TextAlign.center, style: TextStyle(color: ColorTokens.textSecondary)),
            ],
          ),
        ),
      );
    }

    final q = _questionnaire!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Patient-Reported History (Status: ${q.status.toUpperCase()}, ${q.completionPercentage}% Complete)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _buildSectionCard('Allergies & Reactions', Icons.warning_amber_rounded, ColorTokens.error, [
          _buildItemRow('Drug Allergies:', q.drugAllergies.isEmpty ? 'None reported' : q.drugAllergies.join(', ')),
          _buildItemRow('Food & Environmental:', q.foodAllergies.isEmpty ? 'None reported' : q.foodAllergies.join(', ')),
          _buildItemRow('Reaction Severity:', q.allergyReactions.isEmpty ? 'Not specified' : q.allergyReactions.join(', ')),
          _buildItemRow('Medicine Side Effects:', q.medicineSideEffects.isEmpty ? 'None' : q.medicineSideEffects.join(', ')),
        ]),
        const SizedBox(height: 12),

        _buildSectionCard('Conditions & Diagnoses', Icons.medical_services_outlined, ColorTokens.primaryBlue, [
          _buildItemRow('Past Conditions:', q.previousConditions.isEmpty ? 'None' : q.previousConditions.join(', ')),
          _buildItemRow('Current Health Problems:', q.currentHealthProblems.isEmpty ? 'None' : q.currentHealthProblems.join(', ')),
          _buildItemRow('Previous Diagnoses & Dates:', q.previousDiagnoses.isEmpty ? 'None' : q.previousDiagnoses.join(', ')),
        ]),
        const SizedBox(height: 12),

        _buildSectionCard('Current Medications & Supplements', Icons.medication_outlined, ColorTokens.careGreen, [
          _buildItemRow('Active Medicines:', q.currentMedicines.isEmpty ? 'None reported' : q.currentMedicines.join(', ')),
          _buildItemRow('Dosages & Schedules:', q.medicineDosages.isEmpty ? 'Not specified' : q.medicineDosages.join(', ')),
          _buildItemRow('Supplements:', q.supplements.isEmpty ? 'None' : q.supplements.join(', ')),
        ]),
        const SizedBox(height: 12),

        _buildSectionCard('Surgeries & Hospitalizations', Icons.local_hospital_outlined, Colors.purple, [
          _buildItemRow('Previous Surgeries:', q.surgeries.isEmpty ? 'None reported' : q.surgeries.join(', ')),
          _buildItemRow('Hospital Admissions:', q.hospitalizations.isEmpty ? 'None reported' : q.hospitalizations.join(', ')),
        ]),
        const SizedBox(height: 12),

        _buildSectionCard('Family & Lifestyle History', Icons.family_restroom, Colors.teal, [
          _buildItemRow('Family Medical History:', q.familyHistory.isEmpty ? 'None reported' : q.familyHistory.join(', ')),
          _buildItemRow('Smoking:', q.lifestyle['smoking']?.toString() ?? 'No'),
          _buildItemRow('Alcohol:', q.lifestyle['alcohol']?.toString() ?? 'No'),
          if (q.otherDisclosures.isNotEmpty) _buildItemRow('Other Notes:', q.otherDisclosures),
        ]),
      ],
    );
  }

  Widget _buildConsultationsTab() {
    if (_consultations.isEmpty) {
      return const Center(child: Text('No previous clinical consultations recorded.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _consultations.length,
      itemBuilder: (ctx, i) {
        final c = _consultations[i];
        final diag = c['diagnosis'] ?? 'General Consultation';
        final symptoms = c['symptoms'] ?? 'None recorded';
        final notes = c['notes'] ?? 'None';
        final doc = c['doctor_name'] ?? 'Doctor';
        final date = c['created_at']?.toString().split('T').first ?? 'Past Visit';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: ColorTokens.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(diag, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ColorTokens.darkNavy)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Doctor-Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ColorTokens.careGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Dr. $doc • $date', style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
                const Divider(height: 16),
                Text('Symptoms: $symptoms', style: const TextStyle(fontSize: 13, color: ColorTokens.darkNavy)),
                if (notes.isNotEmpty && notes != 'None') ...[
                  const SizedBox(height: 4),
                  Text('Advice / Plan: $notes', style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionsTab() {
    if (_prescriptions.isEmpty) {
      return const Center(child: Text('No historical prescriptions recorded.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _prescriptions.length,
      itemBuilder: (ctx, i) {
        final p = _prescriptions[i];
        final med = p['medicine_name'] ?? 'Prescription';
        final dosage = p['dosage'] ?? 'As directed';
        final freq = p['frequency'] ?? '';
        final dur = p['duration'] ?? '';
        final inst = p['instructions'] ?? '';
        final date = p['created_at']?.toString().split('T').first ?? 'Recent';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: ColorTokens.border)),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: ColorTokens.lightBlue, child: Icon(Icons.medication, color: ColorTokens.primaryBlue)),
            title: Text(med, style: const TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
            subtitle: Text('$dosage • $freq • $dur\nInstructions: $inst • Date: $date', style: const TextStyle(fontSize: 12)),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    if (_reports.isEmpty) {
      return const Center(child: Text('No laboratory or scan reports uploaded.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (ctx, i) {
        final r = _reports[i];
        final title = r.title ?? 'Medical Document';
        final type = r.reportType ?? 'Report';
        final date = r.reportDate ?? '';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: ColorTokens.border)),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: ColorTokens.lightBlue, child: Icon(Icons.description, color: ColorTokens.primaryBlue)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
            subtitle: Text('$type • Date: $date', style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.open_in_new, size: 18, color: ColorTokens.primaryBlue),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children) {
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
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ColorTokens.darkNavy)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Patient-Reported', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                ),
              ],
            ),
            const Divider(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: ColorTokens.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ColorTokens.darkNavy)),
          ),
        ],
      ),
    );
  }
}
