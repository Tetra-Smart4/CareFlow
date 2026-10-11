import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../repositories/notification_repository.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  final Map<String, RealtimeChannel> _activeChannels = {};

  /// Realtime stream for live queue updates for a clinic or doctor.
  Stream<Map<String, dynamic>> watchLiveQueue({required String clinicId}) {
    if (!SupabaseConfig.isConfigured) return const Stream.empty();

    final channelName = 'live_queue_$clinicId';
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    // Fetch initial state
    _fetchQueueSnapshot(clinicId).then((data) {
      if (!controller.isClosed) controller.add(data);
    });

    final channel = _client.channel(channelName);
    _activeChannels[channelName] = channel;

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'careflow_queue_counters',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'clinic_id',
            value: clinicId,
          ),
          callback: (payload) async {
            final snap = await _fetchQueueSnapshot(clinicId);
            if (!controller.isClosed) controller.add(snap);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'careflow_appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'clinic_id',
            value: clinicId,
          ),
          callback: (payload) async {
            final snap = await _fetchQueueSnapshot(clinicId);
            if (!controller.isClosed) controller.add(snap);
          },
        )
        .subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      _activeChannels.remove(channelName);
    };

    return controller.stream;
  }

  /// Realtime stream for appointments changes (new bookings, check-ins, status updates).
  Stream<List<Map<String, dynamic>>> watchAppointments({
    String? clinicId,
    String? doctorId,
    String? patientId,
  }) {
    if (!SupabaseConfig.isConfigured) return const Stream.empty();

    final channelKey = 'appts_${clinicId ?? ''}_${doctorId ?? ''}_${patientId ?? ''}';
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    Future<void> emitLatest() async {
      try {
        var query = _client.from('careflow_appointments').select();
        if (clinicId != null && clinicId.isNotEmpty) query = query.eq('clinic_id', clinicId);
        if (doctorId != null && doctorId.isNotEmpty) query = query.eq('doctor_id', doctorId);
        if (patientId != null && patientId.isNotEmpty) query = query.eq('patient_id', patientId);

        final data = await query.order('appointment_date', ascending: true).order('appointment_time', ascending: true);
        if (!controller.isClosed) controller.add(List<Map<String, dynamic>>.from(data));
      } catch (_) {}
    }

    emitLatest();

    final channel = _client.channel(channelKey);
    _activeChannels[channelKey] = channel;

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'careflow_appointments',
          callback: (payload) => emitLatest(),
        )
        .subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      _activeChannels.remove(channelKey);
    };

    return controller.stream;
  }

  /// Realtime stream for user notifications.
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) {
    if (!SupabaseConfig.isConfigured) return const Stream.empty();

    final channelKey = 'notifs_$userId';
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    Future<void> emitLatest() async {
      try {
        final data = await _client
            .from('careflow_notifications')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
            
        final results = List<Map<String, dynamic>>.from(data);
        final enriched = await NotificationRepository().enrichNotifications(results);
        
        if (!controller.isClosed) controller.add(enriched);
      } catch (_) {}
    }

    emitLatest();

    final channel = _client.channel(channelKey);
    _activeChannels[channelKey] = channel;

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'careflow_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => emitLatest(),
        )
        .subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      _activeChannels.remove(channelKey);
    };

    return controller.stream;
  }

  /// Realtime stream for clinic registration status changes (for admin approval and clinic pending state).
  Stream<List<Map<String, dynamic>>> watchClinics() {
    if (!SupabaseConfig.isConfigured) return const Stream.empty();

    const channelKey = 'clinics_stream';
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    Future<void> emitLatest() async {
      try {
        final data = await _client.from('clinics').select();
        if (!controller.isClosed) controller.add(List<Map<String, dynamic>>.from(data));
      } catch (_) {}
    }

    emitLatest();

    final channel = _client.channel(channelKey);
    _activeChannels[channelKey] = channel;

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'clinics',
          callback: (payload) => emitLatest(),
        )
        .subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      _activeChannels.remove(channelKey);
    };

    return controller.stream;
  }

  Future<Map<String, dynamic>> _fetchQueueSnapshot(String clinicId) async {
    int nowServing = 0;
    int currentToken = 0;

    try {
      final counter = await _client
          .from('careflow_queue_counters')
          .select()
          .eq('clinic_id', clinicId)
          .maybeSingle();

      if (counter != null) {
        nowServing = (counter['now_serving'] as num?)?.toInt() ?? 0;
        currentToken = (counter['current_token'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}

    List<Map<String, dynamic>> queueAppointments = [];
    try {
      final appts = await _client
          .from('careflow_appointments')
          .select()
          .eq('clinic_id', clinicId)
          .inFilter('status', ['checked_in', 'waiting', 'in_consultation', 'called'])
          .order('token_number', ascending: true);

      queueAppointments = List<Map<String, dynamic>>.from(appts);
    } catch (_) {}

    return {
      'clinic_id': clinicId,
      'now_serving': nowServing,
      'current_token': currentToken,
      'queue_entries': queueAppointments,
    };
  }

  Future<void> dispose() async {
    for (final channel in _activeChannels.values) {
      await _client.removeChannel(channel);
    }
    _activeChannels.clear();
  }
}
