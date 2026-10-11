import 'package:supabase_flutter/supabase_flutter.dart';

class PatientRepository {
  SupabaseClient get client => Supabase.instance.client;

  /// Returns the patient profile belonging to the current user.
  Future<Map<String, dynamic>?> getCurrentPatient() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final result = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return result;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getById(String patientId) async {
    try {
      final result = await client
          .from('profiles')
          .select()
          .eq('id', patientId)
          .maybeSingle();

      return result;
    } catch (_) {
      return null;
    }
  }

  /// Returns all patients (for Admin or Clinic).
  Future<List<Map<String, dynamic>>> list({String? orderBy}) async {
    try {
      final query = client
          .from('profiles')
          .select()
          .eq('role', 'patient');

      final result = orderBy == null ? await query.order('full_name') : await query.order(orderBy);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return [];
    }
  }

  /// Returns patients who have had appointments with a clinic.
  Future<List<Map<String, dynamic>>> listForClinic(String clinicId) async {
    // 1. Try RPC careflow_clinic_patients
    try {
      final rpcData = await client.rpc('careflow_clinic_patients', params: {'p_clinic_id': clinicId});
      if (rpcData is List && rpcData.isNotEmpty) {
        return List<Map<String, dynamic>>.from(rpcData);
      }
    } catch (_) {}

    // 2. Query distinct patients from appointments
    try {
      final appointments = await client
          .from('careflow_appointments')
          .select('patient_id')
          .eq('clinic_id', clinicId);

      if (appointments.isEmpty) return [];

      final patientIds = appointments
          .map((e) => e['patient_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      if (patientIds.isEmpty) return [];

      final profiles = await client
          .from('profiles')
          .select()
          .inFilter('id', patientIds);

      return List<Map<String, dynamic>>.from(profiles);
    } catch (_) {
      return [];
    }
  }
}
