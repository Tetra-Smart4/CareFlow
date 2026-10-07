import '../repositories/doctor_repository.dart';

class DoctorService {
  final DoctorRepository repository = DoctorRepository();

  /// Loads all real doctors from Supabase.
  Future<List<Map<String, dynamic>>> loadDoctors() {
    return repository.list();
  }

  /// Kept for compatibility with the existing service layer.
  Future<List<Map<String, dynamic>>> load() {
    return repository.list();
  }

  /// Loads one real doctor by profile ID.
  Future<Map<String, dynamic>?> getDoctorById(String doctorId) {
    return repository.getById(doctorId);
  }
}
