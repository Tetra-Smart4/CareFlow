import '../repositories/notification_repository.dart';

class NotificationService {
  final repository = NotificationRepository();
  Future<List<Map<String, dynamic>>> load({String? userId}) =>
      repository.list(userId: userId);
  Future<void> markRead(String id) => repository.markRead(id);
  Future<Map<String, dynamic>> create(Map<String, dynamic> values) =>
      repository.create(values);
}
