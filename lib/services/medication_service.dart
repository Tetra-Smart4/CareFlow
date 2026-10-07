import '../repositories/medication_repository.dart';

class MedicationService {
  final MedicationRepository repository = MedicationRepository();
  Future<List<Map<String, dynamic>>> load() => repository.list();
}
