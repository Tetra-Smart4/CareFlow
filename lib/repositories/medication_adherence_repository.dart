import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication_adherence.dart';

class MedicationAdherenceRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Fetches doses scheduled for today in the patient's local timezone
  Future<List<MedicationAdherence>> getTodayDoses(String patientId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toUtc().toIso8601String();

      final data = await _client
          .from('careflow_medication_adherence')
          .select()
          .eq('patient_id', patientId)
          .gte('scheduled_time', startOfDay)
          .lte('scheduled_time', endOfDay)
          .order('scheduled_time', ascending: true);

      return (data as List).map((e) => MedicationAdherence.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching today doses: $e');
      return [];
    }
  }

  /// Fetches dose history for a patient
  Future<List<MedicationAdherence>> getDoseHistory(String patientId, {int limit = 50}) async {
    try {
      final data = await _client
          .from('careflow_medication_adherence')
          .select()
          .eq('patient_id', patientId)
          .order('scheduled_time', ascending: false)
          .limit(limit);

      return (data as List).map((e) => MedicationAdherence.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching dose history: $e');
      return [];
    }
  }

  /// Patient confirms dose taken using server-time security definer operation
  Future<Map<String, dynamic>> confirmDoseTaken(String doseId) async {
    try {
      final res = await _client.rpc(
        'careflow_confirm_dose_taken',
        params: {'p_dose_id': doseId},
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      debugPrint('Error confirming dose taken: $e');
      // Direct update fallback if RPC unavailable in dev
      try {
        await _client
            .from('careflow_medication_adherence')
            .update({
              'status': 'taken',
              'taken_at': DateTime.now().toUtc().toIso8601String(),
              'reported_at': DateTime.now().toUtc().toIso8601String(),
              'escalation_status': 'resolved',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', doseId);
        return {'success': true, 'status': 'taken'};
      } catch (fallbackError) {
        return {'success': false, 'error': fallbackError.toString()};
      }
    }
  }

  /// Patient explicitly reports dose not taken with optional reason
  Future<Map<String, dynamic>> reportDoseNotTaken(String doseId, {String? reason}) async {
    try {
      final res = await _client.rpc(
        'careflow_report_dose_not_taken',
        params: {'p_dose_id': doseId, 'p_reason': reason},
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      debugPrint('Error reporting dose not taken: $e');
      try {
        await _client
            .from('careflow_medication_adherence')
            .update({
              'status': 'not_taken',
              'reported_at': DateTime.now().toUtc().toIso8601String(),
              'patient_notes': reason,
              'escalation_status': 'escalated',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', doseId);
        return {'success': true, 'status': 'not_taken'};
      } catch (fallbackError) {
        return {'success': false, 'error': fallbackError.toString()};
      }
    }
  }

  /// Generates scheduled doses for a saved prescription
  Future<Map<String, dynamic>> generateDosesForPrescription(String prescriptionId) async {
    try {
      final res = await _client.rpc(
        'careflow_generate_doses_for_prescription',
        params: {'p_prescription_id': prescriptionId},
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      debugPrint('Error generating doses: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Claims and processes due doses atomically (runs scheduler)
  Future<Map<String, dynamic>> triggerDueDoseScheduler({int limit = 50}) async {
    try {
      final res = await _client.rpc(
        'careflow_claim_and_process_due_doses',
        params: {'p_limit': limit},
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      debugPrint('Error claiming due doses: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetches medication alert consents for a patient
  Future<List<Map<String, dynamic>>> getConsents(String patientId) async {
    try {
      final data = await _client
          .from('careflow_medication_alert_consents')
          .select()
          .eq('patient_id', patientId);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Updates or inserts a medication alert consent
  Future<bool> setConsent({
    required String patientId,
    required String contactType,
    String? familyUserId,
    String? emergencyContactId,
    required bool granted,
  }) async {
    try {
      final payload = <String, dynamic>{
        'patient_id': patientId,
        'contact_type': contactType,
        'medication_alert_permission': granted,
        'consent_status': granted ? 'granted' : 'revoked',
        'consented_at': granted ? DateTime.now().toUtc().toIso8601String() : null,
        'revoked_at': granted ? null : DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (familyUserId != null) payload['family_user_id'] = familyUserId;
      if (emergencyContactId != null) payload['emergency_contact_id'] = emergencyContactId;

      await _client
          .from('careflow_medication_alert_consents')
          .upsert(payload);
      return true;
    } catch (e) {
      debugPrint('Error updating consent: $e');
      return false;
    }
  }
}
