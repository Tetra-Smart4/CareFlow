class MedicationAlert {
  final String title;
  final String message;
  final DateTime scheduledAt;
  final bool emergencyNotified;
  const MedicationAlert({
    required this.title,
    required this.message,
    required this.scheduledAt,
    required this.emergencyNotified,
  });
}
