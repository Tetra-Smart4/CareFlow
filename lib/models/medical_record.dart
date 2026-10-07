class MedicalRecord {
  final String id;
  final String date;
  final String title;
  final String doctorName;
  final String diagnosis;
  final String notes;
  const MedicalRecord({
    required this.id,
    required this.date,
    required this.title,
    required this.doctorName,
    required this.diagnosis,
    required this.notes,
  });
}
