import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';

class RealtimeService {
  RealtimeChannel? _queueChannel;
  Stream<List<Map<String, dynamic>>> watchQueue(String doctorId) async* {
    if (!SupabaseConfig.isConfigured) {
      yield const [];
      return;
    }
    final controller = StreamController<List<Map<String, dynamic>>>();
    final channel = Supabase.instance.client.channel('queue:$doctorId');
    _queueChannel = channel;
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'queue_entries',
          callback: (payload) async {
            final rows = await Supabase.instance.client
                .from('queue_entries')
                .select()
                .eq('doctor_id', doctorId);
            controller.add(List<Map<String, dynamic>>.from(rows));
          },
        )
        .subscribe();
    final initial = await Supabase.instance.client
        .from('queue_entries')
        .select()
        .eq('doctor_id', doctorId);
    controller.add(List<Map<String, dynamic>>.from(initial));
    yield* controller.stream;
  }

  Future<void> dispose() async {
    if (_queueChannel != null) {
      await Supabase.instance.client.removeChannel(_queueChannel!);
    }
  }
}
