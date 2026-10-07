import '../repositories/message_repository.dart';

class MessageService {
  final repository = MessageRepository();
  Future<List<Map<String, dynamic>>> conversation(String a, String b) =>
      repository.conversation(a, b);
  Future<void> send(String a, String b, String text) =>
      repository.send(a, b, text);
  Future<void> markRead(String id) => repository.markRead(id);
}
