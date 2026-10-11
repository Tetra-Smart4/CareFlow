import 'package:supabase_flutter/supabase_flutter.dart';

class FollowUpRepository {
  SupabaseClient get client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> list({
    String? patientId,
    String? doctorId,
    String? orderBy,
  }) async {
    try {
      var query = client.from('careflow_followups').select();
      if (patientId != null) query = query.eq('patient_id', patientId);
      if (doctorId != null) query = query.eq('doctor_id', doctorId);

      final result = orderBy == null
          ? await query.order('followup_date', ascending: true)
          : await query.order(orderBy);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      try {
        var query = client.from('follow_up').select();
        final result = orderBy == null ? await query : await query.order(orderBy);
        return List<Map<String, dynamic>>.from(result);
      } catch (_) {
        return [];
      }
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> values) async {
    final data = await client
        .from('careflow_followups')
        .insert(values)
        .select()
        .single();
    return Map<String, dynamic>.from(data);
  }
}
