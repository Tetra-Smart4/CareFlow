import '../repositories/prescription_repository.dart';

class PrescriptionService {
  final PrescriptionRepository repository = PrescriptionRepository();
  Future<List<Map<String, dynamic>>> load() => repository.list();
}
