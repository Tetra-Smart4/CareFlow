import 'package:supabase_flutter/supabase_flutter.dart';

class QueueRepository {
  SupabaseClient get client => Supabase.instance.client;
  Future<List<Map<String, dynamic>>> list({String? doctorId}) async {
    var q = client.from('queue_entries').select('*, patients(*), doctors(*)');
    if (doctorId != null) q = q.eq('doctor_id', doctorId);
    final data = await q.order('queue_number');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> checkIn(Map<String, dynamic> values) async {
    final data = await client
        .from('queue_entries')
        .insert(values)
        .select()
        .single();
    return Map<String, dynamic>.from(data);
  }

  Future<void> updateStatus(String id, String status) async {
    await client.from('queue_entries').update({'status': status}).eq('id', id);
  }
}
