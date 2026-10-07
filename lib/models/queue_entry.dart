class QueueEntry {
  final String id;
  final int token;
  final String patientName;
  final String doctorName;
  final String status;
  final int patientsAhead;
  const QueueEntry({
    required this.id,
    required this.token,
    required this.patientName,
    required this.doctorName,
    required this.status,
    required this.patientsAhead,
  });
}
