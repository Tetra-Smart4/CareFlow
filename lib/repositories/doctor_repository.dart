import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorRepository {
  SupabaseClient get client => Supabase.instance.client;

  /// Returns all real doctors from the profiles table.
  ///
  /// CareFlow uses profiles as the central identity table.
  /// Doctors are identified by role = 'doctor'.
  Future<List<Map<String, dynamic>>> list({String? orderBy}) async {
    final query = client
        .from('profiles')
        .select('id, full_name, role, phone, gender, age')
        .eq('role', 'doctor');

    final result = orderBy == null
        ? await query.order('full_name')
        : await query.order(orderBy);

    return List<Map<String, dynamic>>.from(result);
  }

  /// Returns a single doctor by profile ID.
  Future<Map<String, dynamic>?> getById(String doctorId) async {
    final result = await client
        .from('profiles')
        .select('id, full_name, role, phone, gender, age')
        .eq('id', doctorId)
        .eq('role', 'doctor')
        .maybeSingle();

    return result;
  }
}
