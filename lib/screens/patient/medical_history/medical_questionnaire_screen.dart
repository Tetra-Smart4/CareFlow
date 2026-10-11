import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/patient_medical_history_repository.dart';

class MedicalQuestionnaireScreen extends StatefulWidget {
  const MedicalQuestionnaireScreen({super.key});

  @override
  State<MedicalQuestionnaireScreen> createState() => _MedicalQuestionnaireScreenState();
}

class _MedicalQuestionnaireScreenState extends State<MedicalQuestionnaireScreen> {
  final _repository = PatientMedicalHistoryRepository();
  int _currentStep = 0;
  bool _loading = true;
  bool _isSaving = false;

  // Master questionnaire state dictionary
  final Map<String, dynamic> _data = {
    'previous_conditions': <String>[],
    'current_health_problems': <String>[],
    'previous_diagnoses': <String>[],
    'surgeries': <String>[],
    'hospitalizations': <String>[],
    'major_illnesses': <String>[],
    'current_medicines': <String>[],
    'medicine_dosages': <String>[],
    'drug_allergies': <String>[],
    'food_allergies': <String>[],
    'allergy_reactions': <String>[],
    'medicine_side_effects': <String>[],
    'supplements': <String>[],
    'family_history': <String>[],
    'lifestyle': <String, dynamic>{
      'smoking': 'No',
      'alcohol': 'No',
      'diet': 'Regular',
      'exercise': 'Moderate',
    },
    'other_disclosures': '',
    'past_prescriptions_notes': '',
    'lab_reports_summary': '',
    'imaging_summary': '',
    'discharge_summaries_notes': '',
  };

  // Step Controllers
  final _conditionsCtrl = TextEditingController();
  final _currentProblemsCtrl = TextEditingController();
  final _diagnosesCtrl = TextEditingController();
  final _surgeriesCtrl = TextEditingController();
  final _hospitalizationsCtrl = TextEditingController();
  final _medicinesCtrl = TextEditingController();
  final _dosagesCtrl = TextEditingController();
  final _drugAllergiesCtrl = TextEditingController();
  final _foodAllergiesCtrl = TextEditingController();
  final _allergyReactionsCtrl = TextEditingController();
  final _sideEffectsCtrl = TextEditingController();
  final _supplementsCtrl = TextEditingController();
  final _familyHistoryCtrl = TextEditingController();
  final _otherDisclosuresCtrl = TextEditingController();
  final _prescriptionsNotesCtrl = TextEditingController();
  final _labSummaryCtrl = TextEditingController();
  final _imagingSummaryCtrl = TextEditingController();

  final List<String> _stepTitles = [
    'Conditions & Diagnoses',
    'Surgeries & Hospitalizations',
    'Medicines & Supplements',
    'Allergies & Reactions',
    'Family & Lifestyle',
    'Historical Records Summary',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingHistory();
  }

  Future<void> _loadExistingHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final history = await _repository.getHistory(user.id);
    if (history != null && mounted) {
      final q = history.questionnaireData;
      setState(() {
        _data.addAll(q);
        _conditionsCtrl.text = _joinList(q['previous_conditions']);
        _currentProblemsCtrl.text = _joinList(q['current_health_problems']);
        _diagnosesCtrl.text = _joinList(q['previous_diagnoses']);
        _surgeriesCtrl.text = _joinList(q['surgeries']);
        _hospitalizationsCtrl.text = _joinList(q['hospitalizations']);
        _medicinesCtrl.text = _joinList(q['current_medicines']);
        _dosagesCtrl.text = _joinList(q['medicine_dosages']);
        _drugAllergiesCtrl.text = _joinList(q['drug_allergies']);
        _foodAllergiesCtrl.text = _joinList(q['food_allergies']);
        _allergyReactionsCtrl.text = _joinList(q['allergy_reactions']);
        _sideEffectsCtrl.text = _joinList(q['medicine_side_effects']);
        _supplementsCtrl.text = _joinList(q['supplements']);
        _familyHistoryCtrl.text = _joinList(q['family_history']);
        _otherDisclosuresCtrl.text = q['other_disclosures']?.toString() ?? '';
        _prescriptionsNotesCtrl.text = q['past_prescriptions_notes']?.toString() ?? '';
        _labSummaryCtrl.text = q['lab_reports_summary']?.toString() ?? '';
        _imagingSummaryCtrl.text = q['imaging_summary']?.toString() ?? '';
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  String _joinList(dynamic val) {
    if (val is List) return val.join(', ');
    return val?.toString() ?? '';
  }

  List<String> _splitText(String val) {
    return val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  void _syncCurrentStepData() {
    _data['previous_conditions'] = _splitText(_conditionsCtrl.text);
    _data['current_health_problems'] = _splitText(_currentProblemsCtrl.text);
    _data['previous_diagnoses'] = _splitText(_diagnosesCtrl.text);
    _data['surgeries'] = _splitText(_surgeriesCtrl.text);
    _data['hospitalizations'] = _splitText(_hospitalizationsCtrl.text);
    _data['current_medicines'] = _splitText(_medicinesCtrl.text);
    _data['medicine_dosages'] = _splitText(_dosagesCtrl.text);
    _data['drug_allergies'] = _splitText(_drugAllergiesCtrl.text);
    _data['food_allergies'] = _splitText(_foodAllergiesCtrl.text);
    _data['allergy_reactions'] = _splitText(_allergyReactionsCtrl.text);
    _data['medicine_side_effects'] = _splitText(_sideEffectsCtrl.text);
    _data['supplements'] = _splitText(_supplementsCtrl.text);
    _data['family_history'] = _splitText(_familyHistoryCtrl.text);
    _data['other_disclosures'] = _otherDisclosuresCtrl.text.trim();
    _data['past_prescriptions_notes'] = _prescriptionsNotesCtrl.text.trim();
    _data['lab_reports_summary'] = _labSummaryCtrl.text.trim();
    _data['imaging_summary'] = _imagingSummaryCtrl.text.trim();
  }

  Future<void> _saveProgress({bool isCompleted = false}) async {
    _syncCurrentStepData();
    setState(() => _isSaving = true);

    final percentage = (((_currentStep + 1) / _stepTitles.length) * 100).toInt();
    final ok = await _repository.saveHistory(
      questionnaire: _data,
      isCompleted: isCompleted,
      completionPercentage: isCompleted ? 100 : percentage,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCompleted ? 'Medical questionnaire successfully submitted!' : 'Progress saved. You can resume at any time.'),
            backgroundColor: ColorTokens.careGreen,
          ),
        );
        if (isCompleted) {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save questionnaire. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = (_currentStep + 1) / _stepTitles.length;

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Medical History Questionnaire'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: ColorTokens.border,
            color: ColorTokens.primaryBlue,
            minHeight: 6,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Patient-Reported Notice Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: ColorTokens.primaryBlue, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Patient-Reported Information: Answers provide essential context for your care team and are verified during doctor consultations.',
                    style: TextStyle(fontSize: 12, color: ColorTokens.darkNavy, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Step Title Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_stepTitles.length}',
                style: const TextStyle(color: ColorTokens.primaryBlue, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Text(
                '${(progress * 100).toInt()}% Completed',
                style: const TextStyle(color: ColorTokens.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _stepTitles[_currentStep],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
          ),
          const SizedBox(height: 16),

          // Dynamic Step Body
          _buildCurrentStepContent(),
          const SizedBox(height: 24),

          // Bottom Action Row
          Row(
            children: [
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: () {
                    _syncCurrentStepData();
                    setState(() => _currentStep--);
                  },
                  child: const Text('Previous'),
                ),
              if (_currentStep > 0) const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Save Progress'),
                onPressed: _isSaving ? null : () => _saveProgress(isCompleted: false),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_currentStep < _stepTitles.length - 1) {
                          _syncCurrentStepData();
                          setState(() => _currentStep++);
                        } else {
                          _saveProgress(isCompleted: true);
                        }
                      },
                child: Text(_currentStep < _stepTitles.length - 1 ? 'Next' : 'Complete & Submit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Conditions();
      case 1:
        return _buildStep2Surgeries();
      case 2:
        return _buildStep3Medicines();
      case 3:
        return _buildStep4Allergies();
      case 4:
        return _buildStep5FamilyLifestyle();
      case 5:
      default:
        return _buildStep6HistoricalRecords();
    }
  }

  Widget _buildStep1Conditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionCard(
          title: '1. Previous Medical Conditions',
          subtitle: 'List any past medical conditions, chronic illnesses, or childhood illnesses.',
          controller: _conditionsCtrl,
          hint: 'e.g., Asthma, Hypertension, Diabetes Type 2',
        ),
        const SizedBox(height: 14),
        _buildQuestionCard(
          title: '2. Current Active Health Problems',
          subtitle: 'What ongoing symptoms or health concerns are you experiencing?',
          controller: _currentProblemsCtrl,
          hint: 'e.g., Migraines, Lower back pain, Fatigue',
        ),
        const SizedBox(height: 14),
        _buildQuestionCard(
          title: '3. Previous Diagnoses & Approximate Dates',
          subtitle: 'Include the diagnosis name and month/year when given by a physician.',
          controller: _diagnosesCtrl,
          hint: 'e.g., Pneumonia (March 2023), Thyroid disorder (2021)',
        ),
      ],
    );
  }

  Widget _buildStep2Surgeries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionCard(
          title: '4. Previous Surgeries & Operations',
          subtitle: 'List any surgical procedures with approximate dates.',
          controller: _surgeriesCtrl,
          hint: 'e.g., Appendectomy (2018), Knee Arthroscopy (2022), None',
        ),
        const SizedBox(height: 14),
        _buildQuestionCard(
          title: '5. Hospitalizations & Emergency Admissions',
          subtitle: 'Mention any hospital stays overnight or ICU admissions.',
          controller: _hospitalizationsCtrl,
          hint: 'e.g., City Hospital (4 days, Dengue fever, 2020), None',
        ),
      ],
    );
  }

  Widget _buildStep3Medicines() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionCard(
          title: '6. Current Prescribed Medicines',
          subtitle: 'Medicines you are taking regularly right now.',
          controller: _medicinesCtrl,
          hint: 'e.g., Metformin, Amlodipine, Inhaler, None',
        ),
        const SizedBox(height: 14),
        _buildQuestionCard(
          title: '7. Dosage & Schedule',
          subtitle: 'How much and how often do you take each medicine?',
          controller: _dosagesCtrl,
          hint: 'e.g., Metformin 500mg twice daily with meals',
        ),
        const SizedBox(height: 14),
        _buildQuestionCard(
          title: '8. Dietary Supplements & Other Treatments',
          subtitle: 'Vitamins, herbal remedies, protein powders, or homeopathic products.',
          controller: _supplementsCtrl,
          hint: 'e.g., Vitamin D3 60k weekly, Omega 3, Multivitamin',
        ),
      ],
    );
  }

  Widget _buildStep4Allergies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionCard(
          title: '9. Drug & Medication Allergies',
          subtitle: 'Are you allergic to any antibiotics, painkillers, or anesthetics?',
          controller: _drugAllergiesCtrl,
          hint: 'e.g., Penicillin, Sulfa drugs, Aspirin, None known',
        ),
        const SizedBox(height: 14),
        _buildQuestionCard(
          title: '10. Food & Environmental Allergies',
          subtitle: 'Food items, latex, pollen, or insect stings.',
          controller: _foodAllergiesCtrl,
          hint: 'e.g., Peanuts, Shellfish, Dust mites, None',
        ),
        const SizedBox(height: 14),
        _buildQuestionCard(
          title: '11. Allergy Reactions & Severity',
          subtitle: 'Describe the symptoms experienced when exposed.',
          controller: _allergyReactionsCtrl,
          hint: 'e.g., Hives, Swelling of lips, Anaphylaxis, Mild rash',
        ),
        const SizedBox(height: 14),
        _buildQuestionCard(
          title: '12. Previous Medicine Side Effects',
          subtitle: 'Medications that caused unpleasant reactions (e.g. nausea, dizziness).',
          controller: _sideEffectsCtrl,
          hint: 'e.g., Ciprofloxacin caused severe tendon pain',
        ),
      ],
    );
  }

  Widget _buildStep5FamilyLifestyle() {
    final lifestyle = _data['lifestyle'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionCard(
          title: '13. Family Medical History',
          subtitle: 'Conditions prevalent in immediate family (parents, siblings, grandparents).',
          controller: _familyHistoryCtrl,
          hint: 'e.g., Father had heart disease at 55; Mother has diabetes',
        ),
        const SizedBox(height: 14),
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
                const Text('14. Relevant Lifestyle Factors', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ColorTokens.darkNavy)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Text('Tobacco / Smoking:', style: TextStyle(fontWeight: FontWeight.w600))),
                    DropdownButton<String>(
                      value: lifestyle['smoking']?.toString() ?? 'No',
                      items: ['No', 'Yes', 'Former smoker', 'Prefer not to answer']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) => setState(() => lifestyle['smoking'] = val),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    const Expanded(child: Text('Alcohol Consumption:', style: TextStyle(fontWeight: FontWeight.w600))),
                    DropdownButton<String>(
                      value: lifestyle['alcohol']?.toString() ?? 'No',
                      items: ['No', 'Occasional', 'Regular', 'Prefer not to answer']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) => setState(() => lifestyle['alcohol'] = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildQuestionCard(
          title: '15. Other Health Information',
          subtitle: 'Any other details or health priorities you wish to share with your doctor.',
          controller: _otherDisclosuresCtrl,
          hint: 'e.g., Frequently travel abroad for work, vegan diet for 10 years',
        ),
      ],
    );
  }

  Widget _buildStep6HistoricalRecords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionCard(
          title: '16. Past Prescriptions & Treatment Notes',
          subtitle: 'Summary of long-term treatments from previous doctors.',
          controller: _prescriptionsNotesCtrl,
          hint: 'e.g., Was on physiotherapy for 6 months following sports injury',
        ),
        const SizedBox(height: 14),
        _buildQuestionCard(
          title: '17. Blood Test & Laboratory Reports Summary',
          subtitle: 'Recent notable lab results (e.g., HbA1c, Cholesterol, CBC).',
          controller: _labSummaryCtrl,
          hint: 'e.g., Last HbA1c was 6.8 in August 2024; Normal kidney function',
        ),
        const SizedBox(height: 14),
        _buildQuestionCard(
          title: '18. Imaging & Scan Reports Summary',
          subtitle: 'Recent X-rays, MRIs, CT scans, or Ultrasounds.',
          controller: _imagingSummaryCtrl,
          hint: 'e.g., Chest X-ray clear (Jan 2024); Lumbar spine MRI showed L4-L5 bulge',
        ),
      ],
    );
  }

  Widget _buildQuestionCard({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String hint,
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ColorTokens.darkNavy)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
