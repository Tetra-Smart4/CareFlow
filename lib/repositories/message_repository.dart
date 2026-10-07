import 'package:supabase_flutter/supabase_flutter.dart';

class MessageRepository {
  SupabaseClient get client => Supabase.instance.client;
  Future<List<Map<String, dynamic>>> conversation(
    String userA,
    String userB,
  ) async {
    final data = await client
        .from('messages')
        .select()
        .or(
          'and(sender_id.eq.$userA,receiver_id.eq.$userB),and(sender_id.eq.$userB,receiver_id.eq.$userA)',
        )
        .order('created_at');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> send(String senderId, String receiverId, String text) async {
    await client.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': text,
    });
  }

  Future<void> markRead(String id) async =>
      client.from('messages').update({'is_read': true}).eq('id', id);
}
