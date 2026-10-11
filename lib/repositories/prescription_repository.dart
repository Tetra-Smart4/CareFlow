import 'package:supabase_flutter/supabase_flutter.dart';

class PrescriptionRepository {
  SupabaseClient get client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> list({String? patientId, String? doctorId}) async {
    try {
      var query = client.from('careflow_prescriptions').select();

      if (patientId != null && patientId.isNotEmpty) {
        query = query.eq('patient_id', patientId);
      }
      if (doctorId != null && doctorId.isNotEmpty) {
        query = query.eq('doctor_id', doctorId);
      }

      final data = await query.order('created_at', ascending: false);
      final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(data);

      return await _attachDoctorNames(items);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> values) async {
    final data = await client
        .from('careflow_prescriptions')
        .insert(values)
        .select()
        .single();

    final result = Map<String, dynamic>.from(data);

    // Automatically generate scheduled doses in careflow_medication_adherence
    try {
      if (result['id'] != null) {
        await client.rpc(
          'careflow_generate_doses_for_prescription',
          params: {'p_prescription_id': result['id']},
        );
      }
    } catch (_) {}

    // Notify patient of new prescription
    try {
      final patientId = result['patient_id'];
      if (patientId != null) {
        await client.from('careflow_notifications').insert({
          'user_id': patientId,
          'title': 'New Prescription Issued',
          'body': 'A new prescription has been added to your medical records.',
          'type': 'prescription',
          'reference_id': result['id'],
          'is_read': false,
        });
      }
    } catch (_) {}

    return result;
  }

  Future<List<Map<String, dynamic>>> _attachDoctorNames(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return items;

    final doctorIds = items
        .map((e) => e['doctor_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    if (doctorIds.isEmpty) return items;

    try {
      final profiles = await client
          .from('profiles')
          .select('id, full_name, specialization')
          .inFilter('id', doctorIds);

      final map = <String, Map<String, dynamic>>{};
      for (final p in profiles) {
        map[p['id'].toString()] = p;
      }

      for (final it in items) {
        final dId = it['doctor_id']?.toString();
        if (dId != null && map.containsKey(dId)) {
          it['doctor_name'] = map[dId]!['full_name'];
          it['doctor_specialization'] = map[dId]!['specialization'];
        }
      }
    } catch (_) {}

    return items;
  }
}
