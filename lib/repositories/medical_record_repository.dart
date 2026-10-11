import 'package:supabase_flutter/supabase_flutter.dart';

class MedicalRecordRepository {
  SupabaseClient get client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> list({String? patientId, String? doctorId}) async {
    try {
      var query = client.from('careflow_consultations').select();

      if (patientId != null && patientId.isNotEmpty) {
        query = query.eq('patient_id', patientId);
      }
      if (doctorId != null && doctorId.isNotEmpty) {
        query = query.eq('doctor_id', doctorId);
      }

      final data = await query.order('created_at', ascending: false);
      final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(data);

      return await _attachProfiles(items);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createConsultation({
    required String appointmentId,
    required String doctorId,
    required String patientId,
    required String diagnosis,
    required String symptoms,
    required String notes,
  }) async {
    // 1. Insert into careflow_consultations
    final consultationData = await client
        .from('careflow_consultations')
        .insert({
          'appointment_id': appointmentId,
          'doctor_id': doctorId,
          'patient_id': patientId,
          'diagnosis': diagnosis,
          'symptoms': symptoms,
          'notes': notes,
        })
        .select()
        .single();

    // 2. Mark appointment completed
    try {
      await client
          .from('careflow_appointments')
          .update({'status': 'completed'})
          .eq('id', appointmentId);
    } catch (_) {}

    // 3. Insert notification for patient
    try {
      await client.from('careflow_notifications').insert({
        'user_id': patientId,
        'title': 'Consultation Summary Available',
        'body': 'Dr. completed your consultation. Diagnosis: $diagnosis',
        'type': 'health',
        'is_read': false,
      });
    } catch (_) {}

    return Map<String, dynamic>.from(consultationData);
  }

  Future<List<Map<String, dynamic>>> _attachProfiles(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return items;

    final userIds = <String>{};
    for (final it in items) {
      if (it['doctor_id'] != null) userIds.add(it['doctor_id'].toString());
      if (it['patient_id'] != null) userIds.add(it['patient_id'].toString());
    }

    if (userIds.isEmpty) return items;

    try {
      final profiles = await client
          .from('profiles')
          .select('id, full_name, specialization')
          .inFilter('id', userIds.toList());

      final map = <String, Map<String, dynamic>>{};
      for (final p in profiles) {
        map[p['id'].toString()] = p;
      }

      for (final it in items) {
        final dId = it['doctor_id']?.toString();
        final pId = it['patient_id']?.toString();

        if (dId != null && map.containsKey(dId)) {
          it['doctor_name'] = map[dId]!['full_name'];
          it['doctor_specialization'] = map[dId]!['specialization'];
        }
        if (pId != null && map.containsKey(pId)) {
          it['patient_name'] = map[pId]!['full_name'];
        }
      }
    } catch (_) {}

    return items;
  }
}
