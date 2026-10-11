import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsRepository {
  SupabaseClient get client => Supabase.instance.client;

  /// Platform Admin aggregated platform statistics from PostgreSQL.
  Future<Map<String, int>> getAdminPlatformStats() async {
    int totalPatients = 0;
    int totalClinics = 0;
    int totalDoctors = 0;
    int pendingClinics = 0;

    try {
      final patientsRes = await client
          .from('profiles')
          .select('id')
          .eq('role', 'patient');
      totalPatients = patientsRes.length;
    } catch (_) {}

    try {
      final clinicsRes = await client.from('clinics').select('id');
      totalClinics = clinicsRes.length;
    } catch (_) {
      try {
        final clinicProfiles = await client
            .from('profiles')
            .select('id')
            .inFilter('role', ['clinic', 'admin']);
        totalClinics = clinicProfiles.length;
      } catch (_) {}
    }

    try {
      final doctorsRes = await client
          .from('profiles')
          .select('id')
          .eq('role', 'doctor');
      totalDoctors = doctorsRes.length;
    } catch (_) {}

    try {
      final pendingRes = await client
          .from('clinics')
          .select('id')
          .eq('status', 'pending');
      pendingClinics = pendingRes.length;
    } catch (_) {}

    return {
      'totalPatients': totalPatients,
      'totalClinics': totalClinics,
      'totalDoctors': totalDoctors,
      'pendingClinics': pendingClinics,
    };
  }

  /// Clinic operations aggregated statistics from PostgreSQL.
  Future<Map<String, int>> getClinicStats(String clinicId) async {
    int todayAppointments = 0;
    int activeDoctors = 0;
    int waitingPatients = 0;
    int completedConsultations = 0;
    int pendingRequests = 0;

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      final appts = await client
          .from('careflow_appointments')
          .select('id, status, appointment_date')
          .eq('clinic_id', clinicId);

      for (final a in appts) {
        final status = (a['status'] ?? '').toString().toLowerCase();
        final date = (a['appointment_date'] ?? '').toString();

        if (date.startsWith(todayStr)) {
          todayAppointments++;
        }
        if (status == 'checked_in' || status == 'waiting') {
          waitingPatients++;
        } else if (status == 'completed') {
          completedConsultations++;
        } else if (status == 'pending') {
          pendingRequests++;
        }
      }
    } catch (_) {}

    try {
      final docs = await client
          .from('clinic_doctors')
          .select('doctor_id')
          .eq('clinic_id', clinicId)
          .eq('active', true);
      activeDoctors = docs.length;
    } catch (_) {}

    return {
      'todayAppointments': todayAppointments,
      'activeDoctors': activeDoctors,
      'waitingPatients': waitingPatients,
      'completedConsultations': completedConsultations,
      'pendingRequests': pendingRequests,
    };
  }

  /// Doctor operational statistics from PostgreSQL.
  Future<Map<String, int>> getDoctorStats(String doctorId) async {
    int todayAppointments = 0;
    int waitingPatients = 0;
    int completedConsultations = 0;
    int followUps = 0;

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      final appts = await client
          .from('careflow_appointments')
          .select('id, status, appointment_date')
          .eq('doctor_id', doctorId);

      for (final a in appts) {
        final status = (a['status'] ?? '').toString().toLowerCase();
        final date = (a['appointment_date'] ?? '').toString();

        if (date.startsWith(todayStr)) {
          todayAppointments++;
        }
        if (status == 'checked_in' || status == 'waiting') {
          waitingPatients++;
        } else if (status == 'completed') {
          completedConsultations++;
        }
      }
    } catch (_) {}

    try {
      final fUps = await client
          .from('careflow_followups')
          .select('id')
          .eq('doctor_id', doctorId);
      followUps = fUps.length;
    } catch (_) {}

    return {
      'todayAppointments': todayAppointments,
      'waitingPatients': waitingPatients,
      'completedConsultations': completedConsultations,
      'followUps': followUps,
    };
  }

  Future<List<Map<String, dynamic>>> list() async => [];
}
