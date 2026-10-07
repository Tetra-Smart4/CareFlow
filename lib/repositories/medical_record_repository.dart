import 'package:supabase_flutter/supabase_flutter.dart';

class MedicalRecordRepository {
  SupabaseClient get client => Supabase.instance.client;
  Future<List<Map<String, dynamic>>> list({String? orderBy}) async {
    final query = client.from('medical_record').select();
    final result = orderBy == null ? await query : await query.order(orderBy);
    return List<Map<String, dynamic>>.from(result);
  }
}
