import '../repositories/medication_adherence_repository.dart';

class MedicationReminderService {
  final MedicationAdherenceRepository _repository = MedicationAdherenceRepository();

  /// Confirms a dose was taken
  Future<Map<String, dynamic>> markTaken(String doseId) async {
    return await _repository.confirmDoseTaken(doseId);
  }

  /// Reports a dose explicitly not taken
  Future<Map<String, dynamic>> markNotTaken(String doseId, {String? reason}) async {
    return await _repository.reportDoseNotTaken(doseId, reason: reason);
  }

  /// Triggers scheduler evaluation for due doses (zero-grace-period escalation)
  Future<Map<String, dynamic>> evaluateDueDoses() async {
    return await _repository.triggerDueDoseScheduler();
  }

  /// Generates doses from a newly created prescription
  Future<Map<String, dynamic>> generatePrescriptionDoses(String prescriptionId) async {
    return await _repository.generateDosesForPrescription(prescriptionId);
  }
}
