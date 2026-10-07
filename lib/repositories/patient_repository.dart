import 'package:supabase_flutter/supabase_flutter.dart';

class PatientRepository {
  SupabaseClient get client => Supabase.instance.client;

  /// Returns the patient record belonging to the
  /// currently authenticated Supabase user.
  ///
  /// In CareFlow:
  /// patients.id -> profiles.id
  Future<Map<String, dynamic>?> getCurrentPatient() async {
    final user = client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final result = await client
        .from('patients')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return result;
  }

  /// Returns all patient records.
  ///
  /// Kept for compatibility with the existing service layer.
  Future<List<Map<String, dynamic>>> list({String? orderBy}) async {
    final query = client.from('patients').select();

    final result = orderBy == null ? await query : await query.order(orderBy);

    return List<Map<String, dynamic>>.from(result);
  }
}
