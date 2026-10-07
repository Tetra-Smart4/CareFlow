import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentRepository {
  SupabaseClient get client => Supabase.instance.client;

  /// Loads appointments from the real CareFlow appointment table.
  ///
  /// When [patientId] is provided, only that patient's appointments
  /// are returned.
  Future<List<Map<String, dynamic>>> list({String? patientId}) async {
    var query = client.from('careflow_appointments').select();

    if (patientId != null && patientId.trim().isNotEmpty) {
      query = query.eq('patient_id', patientId);
    }

    final data = await query
        .order('appointment_date', ascending: true)
        .order('appointment_time', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Creates a new appointment in the real CareFlow appointment table.
  Future<Map<String, dynamic>> create(Map<String, dynamic> values) async {
    final data = await client
        .from('careflow_appointments')
        .insert(values)
        .select()
        .single();

    return Map<String, dynamic>.from(data);
  }

  /// Cancels an existing appointment.
  Future<void> cancel(String id) async {
    await client
        .from('careflow_appointments')
        .update({'status': 'cancelled'})
        .eq('id', id);
  }
}
