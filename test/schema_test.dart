import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:careflow/core/config/supabase_config.dart';

void main() {
  test('Query remote schema', () async {
    final client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.publishableKey);

    try {
      final presc = await client.from('careflow_prescriptions').select().limit(1);
      debugPrint('PRESCRIPTIONS: $presc');
      
      final appts = await client.from('careflow_appointments').select('doctor_id, appointment_date, appointment_time, status');
      debugPrint('APPOINTMENTS COUNT: ${appts.length}');

      // Check careflow_medication_alert_events
      try {
        final events = await client.from('careflow_medication_alert_events').select().limit(1);
        debugPrint('CAREFLOW_MEDICATION_ALERT_EVENTS: $events');
      } catch (e) {
        debugPrint('CAREFLOW_MEDICATION_ALERT_EVENTS ERROR: $e');
      }

      // Check careflow_device_tokens
      try {
        final tokens = await client.from('careflow_device_tokens').select().limit(1);
        debugPrint('CAREFLOW_DEVICE_TOKENS: $tokens');
      } catch (e) {
        debugPrint('CAREFLOW_DEVICE_TOKENS ERROR: $e');
      }
    } catch (e) {
      debugPrint('ERROR: $e');
    }
  });
}
