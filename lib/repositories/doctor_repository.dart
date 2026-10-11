import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorRepository {
  SupabaseClient get client => Supabase.instance.client;

  /// Returns real doctors from the database with specialization, qualifications, and clinics.
  Future<List<Map<String, dynamic>>> list({String? orderBy}) async {
    // 1. Try RPC careflow_list_doctors
    try {
      final rpcData = await client.rpc('careflow_list_doctors');
      if (rpcData is List && rpcData.isNotEmpty) {
        return List<Map<String, dynamic>>.from(rpcData);
      }
    } catch (_) {}

    // 2. Query profiles with role = 'doctor'
    try {
      final data = await client
          .from('profiles')
          .select('id, full_name, phone, gender, age, specialization, qualification, experience, consultation_fee')
          .eq('role', 'doctor');

      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Returns doctors assigned to a specific clinic.
  Future<List<Map<String, dynamic>>> getByClinic(String clinicId) async {
    try {
      final assignments = await client
          .from('clinic_doctors')
          .select('doctor_id, is_available, active')
          .eq('clinic_id', clinicId);

      if (assignments.isEmpty) return [];

      final doctorIds = assignments.map((e) => e['doctor_id'].toString()).toList();
      final profiles = await client
          .from('profiles')
          .select()
          .inFilter('id', doctorIds);

      final map = <String, Map<String, dynamic>>{};
      for (final a in assignments) {
        map[a['doctor_id'].toString()] = a;
      }

      final List<Map<String, dynamic>> results = [];
      for (final p in profiles) {
        final dId = p['id'].toString();
        final copy = Map<String, dynamic>.from(p);
        if (map.containsKey(dId)) {
          copy['is_available'] = map[dId]!['is_available'];
          copy['active'] = map[dId]!['active'];
        }
        results.add(copy);
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  /// Returns a single doctor by profile ID.
  Future<Map<String, dynamic>?> getById(String doctorId) async {
    try {
      final result = await client
          .from('profiles')
          .select()
          .eq('id', doctorId)
          .eq('role', 'doctor')
          .maybeSingle();

      return result;
    } catch (_) {
      return null;
    }
  }

  /// Toggles doctor availability.
  Future<void> setAvailability(String doctorId, bool isAvailable, {String? clinicId}) async {
    if (clinicId != null) {
      await client
          .from('clinic_doctors')
          .update({'is_available': isAvailable})
          .eq('doctor_id', doctorId)
          .eq('clinic_id', clinicId);
    }

    try {
      await client
          .from('doctors')
          .update({'is_available': isAvailable})
          .eq('id', doctorId);
    } catch (_) {}
  }
}
