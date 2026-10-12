class SymptomFollowUpQuestion {
  final String question;
  final List<String> options;
  final List<String> redFlagOptions;

  const SymptomFollowUpQuestion({
    required this.question,
    required this.options,
    this.redFlagOptions = const [],
  });
}

class SymptomGuidanceItem {
  final String id;
  final String name;
  final String category;
  final bool isEmergency;
  final String? emergencyWarning;
  final List<String> redFlags;
  final List<String> commonCauses;
  final List<SymptomFollowUpQuestion> followUpQuestions;
  final List<String> safeSelfCareGuidance;
  final String whenToSeekDoctor;

  const SymptomGuidanceItem({
    required this.id,
    required this.name,
    required this.category,
    this.isEmergency = false,
    this.emergencyWarning,
    required this.redFlags,
    required this.commonCauses,
    required this.followUpQuestions,
    required this.safeSelfCareGuidance,
    required this.whenToSeekDoctor,
  });
}
