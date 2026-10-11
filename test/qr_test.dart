import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:careflow/core/config/supabase_config.dart';
import 'package:flutter/foundation.dart';

void main() {
  test('Check QR Tokens', () async {
    final client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.publishableKey);
    try {
      final appts = await client.from('careflow_appointments').select('id, qr_token, status');
      debugPrint('Found ${appts.length} appointments.');
      for (var a in appts) {
        debugPrint('Appt ${a['id']}: qr_token=${a['qr_token']}');
      }
    } catch(e) {
      debugPrint('Error: $e');
    }
  });
}
