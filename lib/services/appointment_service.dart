import '../repositories/appointment_repository.dart';

class AppointmentService {
  final repository = AppointmentRepository();
  Future<List<Map<String, dynamic>>> load({String? patientId}) =>
      repository.list(patientId: patientId);
  Future<List<String>> getAvailableSlots(String doctorId, DateTime date) =>
      repository.getAvailableSlots(doctorId, date);
  Future<Map<String, dynamic>> create(Map<String, dynamic> values) =>
      repository.create(values);
  Future<void> cancel(String id) => repository.cancel(id);
}
