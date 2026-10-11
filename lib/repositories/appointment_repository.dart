import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentRepository {
  SupabaseClient get client => Supabase.instance.client;

  /// Loads appointments with joined doctor, clinic, and patient details.
  Future<List<Map<String, dynamic>>> list({
    String? patientId,
    String? doctorId,
    String? clinicId,
    String? status,
  }) async {
    try {
      var query = client.from('careflow_appointments').select();

      if (patientId != null && patientId.trim().isNotEmpty) {
        query = query.eq('patient_id', patientId);
      }
      if (doctorId != null && doctorId.trim().isNotEmpty) {
        query = query.eq('doctor_id', doctorId);
      }
      if (clinicId != null && clinicId.trim().isNotEmpty) {
        query = query.eq('clinic_id', clinicId);
      }
      if (status != null && status.trim().isNotEmpty) {
        query = query.eq('status', status.toLowerCase());
      }

      final data = await query
          .order('appointment_date', ascending: true)
          .order('appointment_time', ascending: true);

      final List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(data);

      // Enhance with names from profiles where helpful
      return await _attachProfileNames(results);
    } catch (_) {
      // Fallback: try careflow_clinic_appointments RPC if clinic
      if (clinicId != null) {
        try {
          final rpcData = await client.rpc('careflow_clinic_appointments');
          if (rpcData is List) {
            return List<Map<String, dynamic>>.from(rpcData);
          }
        } catch (_) {}
      }
      return [];
    }
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    try {
      final data = await client
          .from('careflow_appointments')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      final enhanced = await _attachProfileNames([Map<String, dynamic>.from(data)]);
      return enhanced.isNotEmpty ? enhanced.first : null;
    } catch (_) {
      return null;
    }
  }

  /// Returns available slots for a doctor on a specific date, filtering out booked times.
  Future<List<String>> getAvailableSlots(String doctorId, DateTime date) async {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final dateStr = '$year-$month-$day';

    // 1. Try RPC careflow_get_available_slots
    try {
      final rpcData = await client.rpc('careflow_get_available_slots', params: {
        'p_doctor_id': doctorId,
        'p_date': dateStr,
      });

      if (rpcData is List && rpcData.isNotEmpty) {
        final available = <String>[];
        for (final item in rpcData) {
          if (item['is_available'] == true && item['slot_time'] != null) {
            available.add(item['slot_time'].toString());
          }
        }
        return available;
      }
    } catch (_) {}

    // 2. Fallback query: query existing active bookings
    const defaultSlots = [
      '09:00 AM',
      '09:30 AM',
      '10:00 AM',
      '10:30 AM',
      '11:00 AM',
      '11:30 AM',
      '02:00 PM',
      '02:30 PM',
      '03:00 PM',
      '03:30 PM',
      '04:00 PM',
      '04:30 PM',
    ];

    try {
      final booked = await client
          .from('careflow_appointments')
          .select('appointment_time, status')
          .eq('doctor_id', doctorId)
          .eq('appointment_date', dateStr)
          .not('status', 'in', '(cancelled,rejected)');

      final bookedTimes = <String>{};
      for (final b in booked) {
        final rawTime = b['appointment_time']?.toString() ?? '';
        if (rawTime.isNotEmpty) {
          // Convert HH:mm:ss to 12-hour format if needed
          final normalized = _normalizeTimeTo12Hour(rawTime);
          if (normalized != null) bookedTimes.add(normalized);
        }
      }

      return defaultSlots.where((slot) => !bookedTimes.contains(slot)).toList();
    } catch (_) {
      return defaultSlots;
    }
  }

  static String? _normalizeTimeTo12Hour(String raw) {
    try {
      final parts = raw.split(':');
      if (parts.length < 2) return null;
      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> values) async {
    Map<String, dynamic>? resultData;

    // 1. Try atomic booking RPC if applicable
    if (values['patient_id'] != null &&
        values['doctor_id'] != null &&
        values['clinic_id'] != null &&
        values['appointment_date'] != null &&
        values['appointment_time'] != null) {
      try {
        final rpcResult = await client.rpc('careflow_book_appointment', params: {
          'p_patient_id': values['patient_id'],
          'p_doctor_id': values['doctor_id'],
          'p_clinic_id': values['clinic_id'],
          'p_date': values['appointment_date'],
          'p_time': values['appointment_time'],
          'p_reason': values['reason'],
        });
        if (rpcResult is Map) {
          resultData = Map<String, dynamic>.from(rpcResult);
        }
      } catch (e) {
        // If conflict error thrown by RPC, rethrow so UI displays it
        if (e.toString().contains('already booked')) {
          rethrow;
        }
      }
    }

    // 2. Direct table insert fallback
    if (resultData == null) {
      final data = await client
          .from('careflow_appointments')
          .insert(values)
          .select()
          .single();
      resultData = Map<String, dynamic>.from(data);
    }

    // Notify patient of booking confirmation
    try {
      final patientId = resultData['patient_id'];
      if (patientId != null) {
        final date = resultData['appointment_date'] ?? 'scheduled date';
        final time = resultData['appointment_time'] ?? '';
        await client.from('careflow_notifications').insert({
          'user_id': patientId,
          'title': 'Appointment Confirmed',
          'body': 'Your appointment has been scheduled for $date $time.',
          'type': 'appointment',
          'reference_id': resultData['id'],
          'is_read': false,
        });
      }
    } catch (_) {}

    return resultData;
  }

  Future<void> updateStatus(String id, String status) async {
    // 1. Try RPC first if available
    try {
      await client.rpc('careflow_set_appointment_status', params: {
        'p_appointment_id': id,
        'p_status': status,
      });
    } catch (_) {
      // 2. Direct table update
      await client
          .from('careflow_appointments')
          .update({'status': status})
          .eq('id', id);
    }

    // 3. Notify the counter-party of status change
    try {
      final appt = await getById(id);
      if (appt != null) {
        final patientId = appt['patient_id'];
        final doctorId = appt['doctor_id'];
        final currentUserId = client.auth.currentUser?.id;
        final targetUser = (currentUserId == patientId) ? doctorId : patientId;
        if (targetUser != null) {
          await client.from('careflow_notifications').insert({
            'user_id': targetUser,
            'title': status == 'cancelled' ? 'Appointment Cancelled' : 'Appointment Status Updated',
            'body': 'Appointment on ${appt['appointment_date']} has been updated to $status.',
            'type': 'appointment',
            'reference_id': id,
            'is_read': false,
          });
        }
      }
    } catch (_) {}
  }

  Future<void> cancel(String id) async {
    await updateStatus(id, 'cancelled');
  }

  /// Patient check-in: validates, assigns token from queue counter, marks checked_in.
  Future<Map<String, dynamic>> checkIn(String appointmentId, {String? clinicId}) async {
    // 1. Try RPC careflow_patient_check_in first
    try {
      final res = await client.rpc('careflow_patient_check_in', params: {
        'p_appointment_id': appointmentId,
      });
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (_) {}

    // 2. Direct fallback
    final appt = await getById(appointmentId);
    if (appt == null) {
      throw Exception('Appointment not found.');
    }

    final targetClinicId = clinicId ?? appt['clinic_id'];
    int tokenNumber = 1;

    if (targetClinicId != null) {
      try {
        final counter = await client
            .from('careflow_queue_counters')
            .select('current_token')
            .eq('clinic_id', targetClinicId)
            .maybeSingle();

        if (counter != null && counter['current_token'] != null) {
          tokenNumber = ((counter['current_token'] as num).toInt()) + 1;
          await client
              .from('careflow_queue_counters')
              .update({'current_token': tokenNumber, 'updated_at': DateTime.now().toIso8601String()})
              .eq('clinic_id', targetClinicId);
        } else {
          await client
              .from('careflow_queue_counters')
              .upsert({'clinic_id': targetClinicId, 'current_token': 1, 'now_serving': 0});
          tokenNumber = 1;
        }
      } catch (_) {}
    }

    final updatePayload = {
      'status': 'checked_in',
      'checked_in_at': DateTime.now().toIso8601String(),
      'token_number': tokenNumber,
    };

    await client
        .from('careflow_appointments')
        .update(updatePayload)
        .eq('id', appointmentId);

    // Notify patient
    try {
      final patientId = appt['patient_id'];
      if (patientId != null) {
        await client.from('careflow_notifications').insert({
          'user_id': patientId,
          'title': 'Checked In Successfully',
          'body': 'Your queue token number is #$tokenNumber.',
          'type': 'queue',
          'is_read': false,
        });
      }
    } catch (_) {}

    return {
      'success': true,
      'token_number': tokenNumber,
      'status': 'checked_in',
    };
  }

  Future<List<Map<String, dynamic>>> _attachProfileNames(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return items;

    final userIds = <String>{};
    for (final it in items) {
      if (it['doctor_id'] != null) userIds.add(it['doctor_id'].toString());
      if (it['patient_id'] != null) userIds.add(it['patient_id'].toString());
      if (it['clinic_id'] != null) userIds.add(it['clinic_id'].toString());
    }

    if (userIds.isEmpty) return items;

    try {
      final profiles = await client
          .from('profiles')
          .select('id, full_name, clinic_name, specialization, phone')
          .inFilter('id', userIds.toList());

      final map = <String, Map<String, dynamic>>{};
      for (final p in profiles) {
        map[p['id'].toString()] = p;
      }

      for (final it in items) {
        final dId = it['doctor_id']?.toString();
        final pId = it['patient_id']?.toString();
        final cId = it['clinic_id']?.toString();

        if (dId != null && map.containsKey(dId)) {
          it['doctor_name'] = map[dId]!['full_name'];
          it['doctor_specialization'] = map[dId]!['specialization'];
        }
        if (pId != null && map.containsKey(pId)) {
          it['patient_name'] = map[pId]!['full_name'];
          it['patient_phone'] = map[pId]!['phone'];
        }
        if (cId != null && map.containsKey(cId)) {
          it['clinic_name'] = map[cId]!['clinic_name'] ?? map[cId]!['full_name'];
        }
      }
    } catch (_) {}

    return items;
  }
}
