class MedicationDose {
  final String medicationId;
  final String time;
  final bool taken;
  final bool missed;
  const MedicationDose({
    required this.medicationId,
    required this.time,
    required this.taken,
    required this.missed,
  });
}
