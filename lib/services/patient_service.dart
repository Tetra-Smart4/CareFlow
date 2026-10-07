import '../repositories/patient_repository.dart';

class PatientService {
  final PatientRepository repository = PatientRepository();

  /// Loads the patient record belonging to the
  /// currently authenticated Supabase user.
  Future<Map<String, dynamic>?> getCurrentPatient() {
    return repository.getCurrentPatient();
  }

  /// Loads all patient records.
  ///
  /// Kept for compatibility with the existing service layer.
  Future<List<Map<String, dynamic>>> load() {
    return repository.list();
  }
} 