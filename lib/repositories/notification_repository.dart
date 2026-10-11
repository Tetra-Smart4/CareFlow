import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  SupabaseClient get client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> list({String? userId}) async {
    try {
      final currentUid = userId ?? client.auth.currentUser?.id;
      if (currentUid == null) return [];

      final data = await client
          .from('careflow_notifications')
          .select()
          .eq('user_id', currentUid)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(data);
      return await enrichNotifications(results);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> enrichNotifications(List<Map<String, dynamic>> notifications) async {
    if (notifications.isEmpty) return notifications;

    final refIds = <String>{};
    for (final n in notifications) {
      if (n['reference_id'] != null && (n['type'] == 'appointment' || n['type'] == 'queue')) {
        refIds.add(n['reference_id'].toString());
      }
    }

    if (refIds.isEmpty) return notifications;

    try {
      // Fetch appointments
      final apptsData = await client
          .from('careflow_appointments')
          .select()
          .inFilter('id', refIds.toList());
          
      final apptsMap = <String, Map<String, dynamic>>{};
      final patientIds = <String>{};
      
      for (final a in apptsData) {
        final id = a['id'].toString();
        apptsMap[id] = Map<String, dynamic>.from(a);
        if (a['patient_id'] != null) {
          patientIds.add(a['patient_id'].toString());
        }
      }

      // Fetch patient profiles
      final profilesMap = <String, Map<String, dynamic>>{};
      if (patientIds.isNotEmpty) {
        final profilesData = await client
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', patientIds.toList());
        for (final p in profilesData) {
          profilesMap[p['id'].toString()] = Map<String, dynamic>.from(p);
        }
      }

      // Enrich
      for (final n in notifications) {
        final ref = n['reference_id']?.toString();
        if (ref != null && apptsMap.containsKey(ref)) {
          final appt = apptsMap[ref]!;
          n['appointment_date'] = appt['appointment_date'];
          n['appointment_time'] = appt['appointment_time'];
          n['appointment_status'] = appt['status'];
          
          final pId = appt['patient_id']?.toString();
          if (pId != null && profilesMap.containsKey(pId)) {
            n['patient_name'] = profilesMap[pId]!['full_name'];
          }
        }
      }
    } catch (_) {}

    return notifications;
  }

  Future<int> getUnreadCount({String? userId}) async {
    try {
      final currentUid = userId ?? client.auth.currentUser?.id;
      if (currentUid == null) return 0;

      final res = await client
          .from('careflow_notifications')
          .select('id')
          .eq('user_id', currentUid)
          .eq('is_read', false);

      return res.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await client
          .from('careflow_notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (_) {}
  }

  Future<void> markRead(String id) => markAsRead(id);

  Future<Map<String, dynamic>> create(Map<String, dynamic> values) async {
    final data = await client
        .from('careflow_notifications')
        .insert(values)
        .select()
        .single();
    return Map<String, dynamic>.from(data);
  }

  Future<void> markAllAsRead({String? userId}) async {
    try {
      final currentUid = userId ?? client.auth.currentUser?.id;
      if (currentUid == null) return;

      await client
          .from('careflow_notifications')
          .update({'is_read': true})
          .eq('user_id', currentUid);
    } catch (_) {}
  }
}
