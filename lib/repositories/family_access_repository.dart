import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication_adherence.dart';

class FamilyAccessRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Fetches all active patients linked to the given family account
  Future<List<Map<String, dynamic>>> getLinkedPatients(String familyUserId) async {
    try {
      final data = await _client
          .from('careflow_family_access')
          .select('id, patient_id, relationship, active, can_view_notifications, can_view_prescriptions')
          .eq('family_user_id', familyUserId)
          .eq('active', true);

      final list = List<Map<String, dynamic>>.from(data);
      if (list.isEmpty) return [];

      final patientIds = list.map((e) => e['patient_id'].toString()).toList();
      final profiles = await _client
          .from('profiles')
          .select('id, full_name, phone, city')
          .inFilter('id', patientIds);

      final profileMap = {
        for (var p in profiles) p['id'].toString(): p,
      };

      for (var item in list) {
        final pid = item['patient_id'].toString();
        if (profileMap.containsKey(pid)) {
          item['patient_name'] = profileMap[pid]!['full_name'];
          item['patient_phone'] = profileMap[pid]!['phone'];
          item['patient_city'] = profileMap[pid]!['city'];
        }
      }

      return list;
    } catch (e) {
      debugPrint('Error getting linked patients: $e');
      return [];
    }
  }

  /// Fetches active caregiver alerts (unconfirmed or explicitly not taken doses) for family member
  Future<List<Map<String, dynamic>>> getCaregiverAlerts(String familyUserId) async {
    try {
      final notifications = await _client
          .from('careflow_notifications')
          .select()
          .eq('user_id', familyUserId)
          .eq('type', 'caregiver_alert')
          .order('created_at', ascending: false)
          .limit(30);

      final list = List<Map<String, dynamic>>.from(notifications);
      if (list.isEmpty) return [];

      final doseIds = list
          .map((n) => n['dose_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      if (doseIds.isNotEmpty) {
        final doses = await _client
            .from('careflow_medication_adherence')
            .select()
            .inFilter('id', doseIds);

        final doseMap = {
          for (var d in doses) d['id'].toString(): d,
        };

        for (var n in list) {
          final did = n['dose_id']?.toString();
          if (did != null && doseMap.containsKey(did)) {
            n['dose'] = doseMap[did];
          }
        }
      }

      return list;
    } catch (e) {
      debugPrint('Error fetching caregiver alerts: $e');
      return [];
    }
  }

  /// Fetches adherence for an authorized patient
  Future<List<MedicationAdherence>> getPatientAdherence(String patientId) async {
    try {
      final data = await _client
          .from('careflow_medication_adherence')
          .select()
          .eq('patient_id', patientId)
          .order('scheduled_time', ascending: false)
          .limit(30);

      return (data as List).map((e) => MedicationAdherence.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching patient adherence for family: $e');
      return [];
    }
  }
}
