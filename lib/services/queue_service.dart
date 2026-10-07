import '../repositories/queue_repository.dart';

class QueueService {
  final repository = QueueRepository();
  Future<List<Map<String, dynamic>>> load({String? doctorId}) =>
      repository.list(doctorId: doctorId);
  Future<Map<String, dynamic>> checkIn(Map<String, dynamic> values) =>
      repository.checkIn(values);
  Future<void> updateStatus(String id, String status) =>
      repository.updateStatus(id, status);
}
