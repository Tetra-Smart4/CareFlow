import 'package:supabase_flutter/supabase_flutter.dart';

class ClinicRepository {
  SupabaseClient get client => Supabase.instance.client;

  /// Returns current user's clinic ID or user ID
  Future<String?> getCurrentUserClinicId() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    try {
      final clinic = await client
          .from('clinics')
          .select('id, clinic_id')
          .or('id.eq.${user.id},clinic_id.eq.${user.id}')
          .maybeSingle();
      if (clinic != null) {
        return clinic['id']?.toString() ?? clinic['clinic_id']?.toString() ?? user.id;
      }
    } catch (_) {}
    return user.id;
  }

  /// Returns approved clinics available for patient booking and discovery.
  Future<List<Map<String, dynamic>>> list({String? orderBy}) async {
    // 1. Try RPC careflow_list_clinics
    try {
      final rpcData = await client.rpc('careflow_list_clinics');
      if (rpcData is List && rpcData.isNotEmpty) {
        return List<Map<String, dynamic>>.from(rpcData);
      }
    } catch (_) {}

    // 2. Query clinics table join profiles
    try {
      final data = await client
          .from('clinics')
          .select('id, clinic_id, created_at, status')
          .neq('status', 'rejected');

      final results = List<Map<String, dynamic>>.from(data);
      return await _attachClinicProfiles(results);
    } catch (_) {
      // 3. Fallback: query profiles where role is 'clinic' or 'admin'
      try {
        final profiles = await client
            .from('profiles')
            .select()
            .inFilter('role', ['clinic', 'admin']);
        return List<Map<String, dynamic>>.from(profiles);
      } catch (_) {
        return [];
      }
    }
  }

  /// Returns all clinics for Platform Admin management (pending, approved, rejected, suspended).
  Future<List<Map<String, dynamic>>> listAll() async {
    try {
      final data = await client.from('clinics').select();
      final results = List<Map<String, dynamic>>.from(data);
      return await _attachClinicProfiles(results);
    } catch (_) {
      try {
        final profiles = await client
            .from('profiles')
            .select()
            .inFilter('role', ['clinic', 'admin']);
        return List<Map<String, dynamic>>.from(profiles);
      } catch (_) {
        return [];
      }
    }
  }

  /// Returns clinics awaiting platform admin approval.
  Future<List<Map<String, dynamic>>> getPendingClinics() async {
    try {
      final data = await client
          .from('clinics')
          .select()
          .eq('status', 'pending');
      final results = List<Map<String, dynamic>>.from(data);
      return await _attachClinicProfiles(results);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getById(String clinicId) async {
    try {
      final data = await client
          .from('clinics')
          .select()
          .eq('id', clinicId)
          .maybeSingle();

      if (data != null) {
        final enhanced = await _attachClinicProfiles([Map<String, dynamic>.from(data)]);
        return enhanced.isNotEmpty ? enhanced.first : null;
      }
    } catch (_) {}

    try {
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', clinicId)
          .maybeSingle();
      return profile;
    } catch (_) {
      return null;
    }
  }

  /// Platform Admin approves clinic registration.
  Future<void> approveClinic(String clinicId) async {
    try {
      await client.rpc('careflow_admin_approve_clinic', params: {'p_clinic_id': clinicId});
      return;
    } catch (_) {}

    await client
        .from('clinics')
        .update({'status': 'approved'})
        .eq('id', clinicId);
  }

  /// Platform Admin rejects clinic registration.
  Future<void> rejectClinic(String clinicId, {String reason = 'Does not meet requirements.'}) async {
    try {
      await client.rpc('careflow_admin_reject_clinic', params: {
        'p_clinic_id': clinicId,
        'p_reason': reason,
      });
      return;
    } catch (_) {}

    await client
        .from('clinics')
        .update({'status': 'rejected', 'rejection_reason': reason})
        .eq('id', clinicId);
  }

  /// Suspend clinic operations.
  Future<void> suspendClinic(String clinicId) async {
    await client
        .from('clinics')
        .update({'status': 'suspended'})
        .eq('id', clinicId);
  }

  /// Reactivate clinic operations.
  Future<void> reactivateClinic(String clinicId) async {
    await client
        .from('clinics')
        .update({'status': 'approved'})
        .eq('id', clinicId);
  }

  Future<List<Map<String, dynamic>>> _attachClinicProfiles(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return items;

    final ids = items.map((e) => e['id'].toString()).toList();
    try {
      final profiles = await client
          .from('profiles')
          .select('id, full_name, clinic_name, phone, address')
          .inFilter('id', ids);

      final map = <String, Map<String, dynamic>>{};
      for (final p in profiles) {
        map[p['id'].toString()] = p;
      }

      for (final it in items) {
        final id = it['id'].toString();
        if (map.containsKey(id)) {
          it['name'] = map[id]!['clinic_name'] ?? map[id]!['full_name'] ?? 'CareFlow Clinic';
          it['clinic_name'] = map[id]!['clinic_name'] ?? map[id]!['full_name'];
          it['phone'] = map[id]!['phone'];
          it['address'] = map[id]!['address'];
        }
      }
    } catch (_) {}

    return items;
  }
}
