class Encounter {
  final String id;
  final String patientId;
  final String doctorId;
  final String date;
  final String summary;
  const Encounter({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.date,
    required this.summary,
  });
}
