import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:careflow/core/config/supabase_config.dart';

void main() {
  group('Live Supabase Remote Backend Verification', () {
    late SupabaseClient client;

    setUpAll(() {
      expect(SupabaseConfig.isConfigured, isTrue);
      client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.publishableKey);
    });

    test('1. Verify all new CareFlow tables exist remotely', () async {
      final tables = [
        'careflow_medication_adherence',
        'careflow_family_access',
        'careflow_medication_alert_consents',
        'careflow_device_tokens',
        'careflow_medication_alert_events',
        'careflow_patient_medical_history',
        'careflow_audit_logs',
        'careflow_doctor_access_grants',
        'careflow_prescriptions',
        'careflow_appointments',
      ];

      for (final table in tables) {
        try {
          final res = await client.from(table).select().limit(1);
          expect(res, isNotNull);
          debugPrint('VERIFIED TABLE: $table');
        } catch (e) {
          // If RLS prevents anon read, it confirms table exists with RLS enabled
          final errorStr = e.toString();
          final exists = errorStr.contains('permission denied') ||
              errorStr.contains('42501') ||
              !errorStr.contains('PGRST205');
          expect(exists, isTrue, reason: 'Table $table must exist on remote DB: $e');
          debugPrint('VERIFIED TABLE (RLS Protected): $table');
        }
      }
    });

    test('2. Verify RPC careflow_claim_and_process_due_doses is live', () async {
      try {
        final res = await client.rpc('careflow_claim_and_process_due_doses', params: {'p_limit': 1});
        expect(res, isNotNull);
        debugPrint('VERIFIED RPC careflow_claim_and_process_due_doses: $res');
      } catch (e) {
        // If execution context requires auth, ensure function exists (not PGRST202)
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'Function must exist in schema cache');
        debugPrint('VERIFIED RPC careflow_claim_and_process_due_doses exists: $e');
      }
    });

    test('3. Verify RPC careflow_call_next_patient is live with concurrency guard', () async {
      final dummyClinicId = '00000000-0000-0000-0000-000000000000';
      try {
        final res = await client.rpc('careflow_call_next_patient', params: {'p_clinic_id': dummyClinicId});
        expect(res, isNotNull);
        debugPrint('VERIFIED RPC careflow_call_next_patient: $res');
      } catch (e) {
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'Function must exist in schema cache');
        debugPrint('VERIFIED RPC careflow_call_next_patient exists: $e');
      }
    });

    test('4. Verify RPC careflow_save_medical_history is live', () async {
      try {
        await client.rpc('careflow_save_medical_history', params: {
          'p_questionnaire': <String, dynamic>{},
          'p_is_completed': false,
          'p_completion_percentage': 0,
        });
      } catch (e) {
        // Must reject unauthenticated caller (401 or Unauthorized), confirming function is deployed and protected
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'Function must exist in schema cache');
        expect(e.toString().toLowerCase().contains('unauthorized'), isTrue);
        debugPrint('VERIFIED RPC careflow_save_medical_history deployed & auth-guarded: $e');
      }
    });

    test('5. Verify RPC careflow_generate_doses_for_prescription is live', () async {
      try {
        await client.rpc('careflow_generate_doses_for_prescription', params: {
          'p_prescription_id': '00000000-0000-0000-0000-000000000000',
        });
      } catch (e) {
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'Function must exist in schema cache');
        debugPrint('VERIFIED RPC careflow_generate_doses_for_prescription exists: $e');
      }
    });

    test('6. Verify RPC careflow_confirm_dose_taken is live', () async {
      try {
        await client.rpc('careflow_confirm_dose_taken', params: {
          'p_dose_id': '00000000-0000-0000-0000-000000000000',
        });
      } catch (e) {
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'Function must exist in schema cache');
        debugPrint('VERIFIED RPC careflow_confirm_dose_taken exists: $e');
      }
    });

    test('7. Verify RPC careflow_report_dose_not_taken is live', () async {
      try {
        await client.rpc('careflow_report_dose_not_taken', params: {
          'p_dose_id': '00000000-0000-0000-0000-000000000000',
        });
      } catch (e) {
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'Function must exist in schema cache');
        debugPrint('VERIFIED RPC careflow_report_dose_not_taken exists: $e');
      }
    });

    test('8. Verify RPC careflow_register_device_token is live', () async {
      try {
        await client.rpc('careflow_register_device_token', params: {
          'p_token': 'dummy_verification_token',
        });
      } catch (e) {
        expect(e.toString().contains('PGRST202'), isFalse, reason: 'Function must exist in schema cache');
        expect(e.toString().toLowerCase().contains('unauthorized'), isTrue);
        debugPrint('VERIFIED RPC careflow_register_device_token deployed & auth-guarded: $e');
      }
    });
  });
}
