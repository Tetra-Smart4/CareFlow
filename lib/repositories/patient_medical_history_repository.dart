import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient_medical_history.dart';

class PatientMedicalHistoryRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Fetches the medical history questionnaire for a patient
  Future<PatientMedicalHistory?> getHistory(String patientId) async {
    try {
      final data = await _client
          .from('careflow_patient_medical_history')
          .select()
          .eq('patient_id', patientId)
          .maybeSingle();

      if (data == null) return null;
      return PatientMedicalHistory.fromJson(data);
    } catch (e) {
      debugPrint('Error loading patient medical history: $e');
      return null;
    }
  }

  /// Saves or updates the patient medical questionnaire (via RPC or direct upsert)
  Future<bool> saveHistory({
    required Map<String, dynamic> questionnaire,
    bool isCompleted = false,
    int completionPercentage = 100,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Call secure transaction RPC
      try {
        final res = await _client.rpc(
          'careflow_save_medical_history',
          params: {
            'p_questionnaire': questionnaire,
            'p_is_completed': isCompleted,
            'p_completion_percentage': completionPercentage,
          },
        );
        if (res is Map && res['success'] == true) return true;
      } catch (rpcErr) {
        debugPrint('RPC save fallback: $rpcErr');
      }

      // Direct upsert fallback
      await _client.from('careflow_patient_medical_history').upsert({
        'patient_id': user.id,
        'questionnaire_data': questionnaire,
        'status': isCompleted ? 'completed' : 'in_progress',
        'completion_percentage': completionPercentage,
        'last_reviewed_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Error saving patient medical history: $e');
      return false;
    }
  }
}
