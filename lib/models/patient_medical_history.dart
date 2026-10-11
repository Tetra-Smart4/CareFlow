class PatientMedicalHistory {
  final String id;
  final String patientId;
  final Map<String, dynamic> questionnaireData;
  final String status; // 'in_progress', 'completed'
  final int completionPercentage;
  final DateTime? lastReviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatientMedicalHistory({
    required this.id,
    required this.patientId,
    required this.questionnaireData,
    this.status = 'in_progress',
    this.completionPercentage = 0,
    this.lastReviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => status == 'completed';

  // Helper getters for the 20 questionnaire categories
  List<String> get previousConditions => _getList('previous_conditions');
  List<String> get currentHealthProblems => _getList('current_health_problems');
  List<String> get previousDiagnoses => _getList('previous_diagnoses');
  List<String> get surgeries => _getList('surgeries');
  List<String> get hospitalizations => _getList('hospitalizations');
  List<String> get majorIllnesses => _getList('major_illnesses');
  List<String> get currentMedicines => _getList('current_medicines');
  List<String> get medicineDosages => _getList('medicine_dosages');
  List<String> get drugAllergies => _getList('drug_allergies');
  List<String> get foodAllergies => _getList('food_allergies');
  List<String> get allergyReactions => _getList('allergy_reactions');
  List<String> get medicineSideEffects => _getList('medicine_side_effects');
  List<String> get supplements => _getList('supplements');
  List<String> get familyHistory => _getList('family_history');
  Map<String, dynamic> get lifestyle => _getMap('lifestyle');
  String get otherDisclosures => questionnaireData['other_disclosures']?.toString() ?? '';
  String get pastPrescriptionsNotes => questionnaireData['past_prescriptions_notes']?.toString() ?? '';
  String get labReportsSummary => questionnaireData['lab_reports_summary']?.toString() ?? '';
  String get imagingSummary => questionnaireData['imaging_summary']?.toString() ?? '';
  String get dischargeSummariesNotes => questionnaireData['discharge_summaries_notes']?.toString() ?? '';

  List<String> _getList(String key) {
    final val = questionnaireData[key];
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    return [];
  }

  Map<String, dynamic> _getMap(String key) {
    final val = questionnaireData[key];
    if (val is Map) {
      return Map<String, dynamic>.from(val);
    }
    return {};
  }

  factory PatientMedicalHistory.fromJson(Map<String, dynamic> json) {
    return PatientMedicalHistory(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      questionnaireData: json['questionnaire_data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['questionnaire_data'])
          : {},
      status: json['status']?.toString() ?? 'in_progress',
      completionPercentage: (json['completion_percentage'] as num?)?.toInt() ?? 0,
      lastReviewedAt: json['last_reviewed_at'] != null
          ? DateTime.tryParse(json['last_reviewed_at'].toString())?.toLocal()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'questionnaire_data': questionnaireData,
      'status': status,
      'completion_percentage': completionPercentage,
      'last_reviewed_at': lastReviewedAt?.toUtc().toIso8601String(),
    };
  }
}
