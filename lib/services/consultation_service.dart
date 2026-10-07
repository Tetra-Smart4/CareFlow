import '../repositories/encounter_repository.dart';

class ConsultationService {
  final EncounterRepository repository = EncounterRepository();
  Future<List<Map<String, dynamic>>> load() => repository.list();
}
