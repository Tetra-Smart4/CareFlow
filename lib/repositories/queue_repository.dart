import 'package:supabase_flutter/supabase_flutter.dart';

class QueueRepository {
  SupabaseClient get client => Supabase.instance.client;

  /// Fetches the live queue counter for a clinic (now_serving, current_token).
  Future<Map<String, dynamic>> getCounter(String clinicId) async {
    try {
      final data = await client
          .from('careflow_queue_counters')
          .select()
          .eq('clinic_id', clinicId)
          .maybeSingle();

      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}

    return {
      'clinic_id': clinicId,
      'current_token': 0,
      'now_serving': 0,
    };
  }

  /// Lists checked-in and active queue appointments for a clinic or doctor.
  Future<List<Map<String, dynamic>>> list({String? clinicId, String? doctorId}) async {
    try {
      var query = client.from('careflow_appointments').select();

      if (clinicId != null && clinicId.isNotEmpty) {
        query = query.eq('clinic_id', clinicId);
      }
      if (doctorId != null && doctorId.isNotEmpty) {
        query = query.eq('doctor_id', doctorId);
      }

      // In-queue statuses: checked_in, in_consultation, called
      query = query.inFilter('status', ['checked_in', 'waiting', 'in_consultation', 'called']);

      final data = await query.order('token_number', ascending: true);
      final List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(data);

      return await _attachNames(rows);
    } catch (_) {
      return [];
    }
  }

  /// Call next patient: increments now_serving, updates appointment to in_consultation.
  Future<Map<String, dynamic>> callNext(String clinicId) async {
    // 1. Try RPC careflow_call_next_patient
    try {
      final res = await client.rpc('careflow_call_next_patient', params: {
        'p_clinic_id': clinicId,
      });
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (_) {}

    // 2. Direct fallback
    int nowServing = 1;
    try {
      final counter = await client
          .from('careflow_queue_counters')
          .select('now_serving, current_token')
          .eq('clinic_id', clinicId)
          .maybeSingle();

      if (counter != null) {
        final currentNow = (counter['now_serving'] as num?)?.toInt() ?? 0;
        nowServing = currentNow + 1;
        await client
            .from('careflow_queue_counters')
            .update({'now_serving': nowServing, 'updated_at': DateTime.now().toIso8601String()})
            .eq('clinic_id', clinicId);
      } else {
        await client
            .from('careflow_queue_counters')
            .upsert({'clinic_id': clinicId, 'current_token': 1, 'now_serving': 1});
      }

      // Update matching appointment
      final matching = await client
          .from('careflow_appointments')
          .select('id, patient_id')
          .eq('clinic_id', clinicId)
          .eq('token_number', nowServing)
          .inFilter('status', ['checked_in', 'waiting'])
          .maybeSingle();

      if (matching != null) {
        await client
            .from('careflow_appointments')
            .update({'status': 'in_consultation'})
            .eq('id', matching['id']);

        if (matching['patient_id'] != null) {
          await client.from('careflow_notifications').insert({
            'user_id': matching['patient_id'],
            'title': 'Your Turn: Now Serving #$nowServing',
            'body': 'Please proceed to the consultation room.',
            'type': 'queue',
            'is_read': false,
          });
        }
      }
    } catch (_) {}

    return {
      'success': true,
      'clinic_id': clinicId,
      'now_serving': nowServing,
    };
  }

  /// Doctor atomically calls next waiting patient
  Future<Map<String, dynamic>> doctorCallNext(String doctorId) async {
    // We cannot use the 'careflow_doctor_call_next_patient' RPC because it incorrectly uses the 'called' status
    // which violates the check constraint. We use a safe atomic fallback instead.
    
    try {
      final waiting = await client
          .from('careflow_appointments')
          .select('id, patient_id, token_number, clinic_id, status, patient:profiles!patient_id(full_name)')
          .eq('doctor_id', doctorId)
          .inFilter('status', ['checked_in', 'waiting'])
          .order('token_number', ascending: true)
          .limit(1)
          .maybeSingle();

      if (waiting != null) {
        final apptId = waiting['id'].toString();
        final token = waiting['token_number'];
        final pId = waiting['patient_id'];
        final clinicId = waiting['clinic_id'];
        final prevStatus = waiting['status'];

        final updatedRows = await client.from('careflow_appointments').update({
          'status': 'in_consultation',
          'consultation_started_at': DateTime.now().toIso8601String(),
        }).eq('id', apptId).eq('status', prevStatus).select();

        // If no rows were returned, another device claimed it first!
        if (updatedRows.isEmpty) {
          return {
            'success': false,
            'message': 'Patient was called by another terminal.',
          };
        }

        if (clinicId != null && token != null && token is num) {
          try {
            await client.from('careflow_queue_counters').update({
              'now_serving': token.toInt(),
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('clinic_id', clinicId);
          } catch (_) {}
        }

        if (pId != null) {
          try {
            await client.from('careflow_notifications').insert({
              'user_id': pId,
              'title': 'Your Turn: Now Calling #$token',
              'body': 'The doctor is ready for your consultation. Please proceed to the room.',
              'type': 'queue',
              'is_read': false,
            });
          } catch (_) {}
        }

        return {
          'success': true,
          'appointment_id': apptId,
          'token_number': token,
          'patient_id': pId,
          'status': 'in_consultation',
        };
      }
    } catch (_) {}

    return {
      'success': false,
      'message': 'No waiting patients found in queue.',
    };
  }

  /// Start consultation: status -> 'in_consultation'
  Future<Map<String, dynamic>> startConsultation(String appointmentId) async {
    try {
      final res = await client.rpc('careflow_start_consultation', params: {
        'p_appointment_id': appointmentId,
      });
      if (res is Map<String, dynamic>) return res;
    } catch (_) {}

    await client.from('careflow_appointments').update({
      'status': 'in_consultation',
      'consultation_started_at': DateTime.now().toIso8601String(),
    }).eq('id', appointmentId);

    return {'success': true, 'status': 'in_consultation'};
  }

  /// Mark appointment status in queue (e.g. 'completed', 'no_show', 'cancelled')
  Future<void> updateStatus(String appointmentId, String status) async {
    final updateData = <String, dynamic>{'status': status};
    if (status == 'completed') {
      updateData['consultation_completed_at'] = DateTime.now().toIso8601String();
    }
    await client
        .from('careflow_appointments')
        .update(updateData)
        .eq('id', appointmentId);
  }

  Future<List<Map<String, dynamic>>> _attachNames(List<Map<String, dynamic>> items) async {
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
          .select('id, full_name, phone')
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
        }
        if (pId != null && map.containsKey(pId)) {
          it['patient_name'] = map[pId]!['full_name'];
          it['patient_phone'] = map[pId]!['phone'];
        }
      }
    } catch (_) {}

    return items;
  }

  Future<Map<String, dynamic>> checkIn(Map<String, dynamic> values) async {
    final qrToken = values['appointment_id'] ?? values['qr_token'] ?? values['id'];
    final clinicId = values['clinic_id'];
    if (qrToken != null && clinicId != null) {
      try {
        final res = await client.rpc('careflow_clinic_scan_qr', params: {
          'p_qr_token': qrToken.toString(),
          'p_clinic_id': clinicId.toString(),
        });
        if (res is Map) return Map<String, dynamic>.from(res);
      } catch (e) {
        return {'success': false, 'message': e.toString()};
      }
    }
    return {'success': false, 'message': 'Missing token or clinic ID'};
  }
}
