class Appointment {
  final String id;
  final String patientName;
  final String doctorName;
  final String date;
  final String time;
  final String reason;
  final String status;
  const Appointment({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.reason,
    required this.status,
  });
}
