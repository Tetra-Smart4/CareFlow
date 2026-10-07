import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  SupabaseClient get client => Supabase.instance.client;
  Future<List<Map<String, dynamic>>> list({String? userId}) async {
    var q = client.from('notifications').select();
    if (userId != null) q = q.eq('user_id', userId);
    final data = await q.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> markRead(String id) async {
    await client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> values) async {
    final data = await client
        .from('notifications')
        .insert(values)
        .select()
        .single();
    return Map<String, dynamic>.from(data);
  }
}
