import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../models/symptom_guidance_item.dart';
import '../../../repositories/medicine_repository.dart';

class SymptomGuidanceScreen extends StatefulWidget {
  const SymptomGuidanceScreen({super.key});

  @override
  State<SymptomGuidanceScreen> createState() => _SymptomGuidanceScreenState();
}

class _SymptomGuidanceScreenState extends State<SymptomGuidanceScreen> {
  final MedicineRepository _repository = MedicineRepository();
  final TextEditingController _searchController = TextEditingController();

  List<SymptomGuidanceItem> _allSymptoms = [];
  List<SymptomGuidanceItem> _filteredSymptoms = [];
  SymptomGuidanceItem? _selectedSymptom;
  final Map<int, String> _selectedAnswers = {};
  bool _emergencyTriggered = false;

  @override
  void initState() {
    super.initState();
    _allSymptoms = _repository.getSymptomGuidanceList();
    _filteredSymptoms = List.from(_allSymptoms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final clean = query.trim().toLowerCase();
    setState(() {
      if (clean.isEmpty) {
        _filteredSymptoms = List.from(_allSymptoms);
      } else {
        _filteredSymptoms = _allSymptoms.where((s) {
          return s.name.toLowerCase().contains(clean) ||
              s.category.toLowerCase().contains(clean) ||
              s.commonCauses.any((c) => c.toLowerCase().contains(clean));
        }).toList();
      }
    });
  }

  void _selectSymptom(SymptomGuidanceItem symptom) {
    setState(() {
      _selectedSymptom = symptom;
      _selectedAnswers.clear();
      _emergencyTriggered = symptom.isEmergency;
    });
  }

  void _answerQuestion(int questionIndex, String answer, bool isRedFlag) {
    setState(() {
      _selectedAnswers[questionIndex] = answer;
      if (isRedFlag) {
        _emergencyTriggered = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFF0D9488), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Symptom Guidance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
      ),
      body: _selectedSymptom == null ? _buildSymptomSelectionView() : _buildTriageDetailView(),
    );
  }

  Widget _buildSymptomSelectionView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Intro Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Explore Symptom Guidance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              SizedBox(height: 4),
              Text(
                'Identify symptoms, review emergency triage signs, and learn safe self-care recommendations before consulting a clinic doctor.',
                style: TextStyle(fontSize: 13, color: Colors.white, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Urgent Red Flag Notice
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
              Icon(Icons.emergency_rounded, color: ColorTokens.error, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'If you or someone else is experiencing severe difficulty breathing, crushing chest pain, sudden numbness, or heavy bleeding, call 108 or emergency ambulance services immediately.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w600, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search Symptom Input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ColorTokens.border),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearch,
            decoration: const InputDecoration(
              hintText: 'Search symptom (e.g. fever, headache, cough)...',
              hintStyle: TextStyle(fontSize: 13.5, color: ColorTokens.textMuted),
              prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF0D9488)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 18),

        const Text(
          'Common Symptoms & Triage',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
        ),
        const SizedBox(height: 10),

        ..._filteredSymptoms.map((sym) => _buildSymptomListItem(sym)),
      ],
    );
  }

  Widget _buildSymptomListItem(SymptomGuidanceItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isEmergency ? const Color(0xFFFCA5A5) : ColorTokens.border,
          width: item.isEmergency ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _selectSymptom(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.isEmergency
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFF0D9488).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.isEmergency ? Icons.warning_rounded : Icons.healing_rounded,
                    color: item.isEmergency ? ColorTokens.error : const Color(0xFF0D9488),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: ColorTokens.darkNavy,
                              ),
                            ),
                          ),
                          if (item.isEmergency)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: ColorTokens.error,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'RED FLAG',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.category,
                        style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: ColorTokens.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTriageDetailView() {
    final sym = _selectedSymptom!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Back Button
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSymptom = null;
                  _emergencyTriggered = false;
                });
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('All Symptoms'),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Emergency Alert Box if Triggered
        if (_emergencyTriggered || sym.isEmergency) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.emergency_rounded, color: ColorTokens.error, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'EMERGENCY WARNING DETECTED',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: ColorTokens.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  sym.emergencyWarning ??
                      'Urgent emergency signs are present. Do not wait for home measures to take effect.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B), height: 1.35, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorTokens.error,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Call Ambulance (108)',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Calling Emergency Services (108)...'),
                        backgroundColor: ColorTokens.error,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Symptom Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorTokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sym.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ColorTokens.darkNavy),
              ),
              const SizedBox(height: 4),
              Text(
                'Category: ${sym.category}',
                style: const TextStyle(fontSize: 13, color: ColorTokens.textSecondary),
              ),
              const SizedBox(height: 12),
              const Text(
                'Common Causes:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
              ),
              const SizedBox(height: 4),
              Text(
                sym.commonCauses.join(', '),
                style: const TextStyle(fontSize: 13, color: ColorTokens.textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Red Flags Checklist
        if (sym.redFlags.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.flag_rounded, color: Color(0xFFD97706), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Warning Signs & Red Flags',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...sym.redFlags.map(
                  (rf) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, size: 6, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rf,
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Follow-up Questions
        if (sym.followUpQuestions.isNotEmpty) ...[
          const Text(
            'Triage Questions',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
          ),
          const SizedBox(height: 8),
          ...sym.followUpQuestions.asMap().entries.map((entry) {
            final qIndex = entry.key;
            final q = entry.value;
            final currentSelection = _selectedAnswers[qIndex];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ColorTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.question,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
                  ),
                  const SizedBox(height: 10),
                  ...q.options.map((opt) {
                    final isSelected = currentSelection == opt;
                    final isRedFlag = q.redFlagOptions.contains(opt);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _answerQuestion(qIndex, opt, isRedFlag),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isRedFlag
                                    ? const Color(0xFFFEF2F2)
                                    : const Color(0xFF0D9488).withValues(alpha: 0.1))
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? (isRedFlag ? ColorTokens.error : const Color(0xFF0D9488))
                                  : ColorTokens.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 16,
                                color: isSelected
                                    ? (isRedFlag ? ColorTokens.error : const Color(0xFF0D9488))
                                    : ColorTokens.textMuted,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  opt,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected && isRedFlag ? ColorTokens.error : ColorTokens.darkNavy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
        ],

        // Safe Self-Care Guidance
        Container(
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
                children: const [
                  Icon(Icons.self_improvement_rounded, color: Color(0xFF0D9488), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Safe Home Guidance & Self-Care',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...sym.safeSelfCareGuidance.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF0D9488)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          g,
                          style: const TextStyle(fontSize: 13, color: ColorTokens.darkNavy, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: ColorTokens.border),
              const SizedBox(height: 10),
              Text(
                'When to See a Doctor: ${sym.whenToSeekDoctor}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ColorTokens.navy),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action: Book Appointment
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D9488),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
          label: const Text(
            'Book Appointment with Doctor',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/patient/appointments/book');
          },
        ),
      ],
    );
  }
}
