class MedicationReminderService {
  Future<void> scheduleDoseReminder({
    required String medicine,
    required DateTime time,
  }) async {}
  Future<void> markTaken(String medicationId) async {}
  Future<void> markMissed(String medicationId) async {}
}
