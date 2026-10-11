class PrescriptionItem {
  final String medicine;
  final String dose;
  final String frequency;
  final String duration;
  final String? instructions;

  const PrescriptionItem({
    required this.medicine,
    required this.dose,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      medicine: (json['medicine_name'] ?? json['medicine'] ?? 'Medicine').toString(),
      dose: (json['dosage'] ?? json['dose'] ?? '').toString(),
      frequency: (json['frequency'] ?? '').toString(),
      duration: (json['duration'] ?? '').toString(),
      instructions: json['instructions']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine_name': medicine,
      'dosage': dose,
      'frequency': frequency,
      'duration': duration,
      if (instructions != null) 'instructions': instructions,
    };
  }
}
