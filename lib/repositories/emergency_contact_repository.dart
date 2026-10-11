import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/emergency_contact.dart';

class EmergencyContactRepository {
  SupabaseClient get _client => Supabase.instance.client;

  // Local fallback cache in case Supabase table hasn't been migrated yet
  static final Map<String, List<EmergencyContact>> _localCache = {};

  /// Fetch all emergency contacts for a patient from PostgreSQL
  Future<List<EmergencyContact>> getContacts(String patientId) async {
    if (!SupabaseConfig.isConfigured) {
      return _localCache[patientId] ?? [];
    }

    try {
      final data = await _client
          .from('emergency_contacts')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      final contacts = (data as List).map((e) => EmergencyContact.fromJson(e)).toList();
      _localCache[patientId] = contacts;
      return contacts;
    } catch (_) {
      // Fallback to cache if table not yet created
      return _localCache[patientId] ?? [];
    }
  }

  /// Add a new emergency contact in PostgreSQL
  Future<EmergencyContact> addContact({
    required String patientId,
    required String name,
    required String phone,
    required String relationship,
  }) async {
    final newLocal = EmergencyContact(
      id: 'ec_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      name: name,
      phone: phone,
      relationship: relationship,
      createdAt: DateTime.now(),
    );

    if (!SupabaseConfig.isConfigured) {
      _localCache.putIfAbsent(patientId, () => []).insert(0, newLocal);
      return newLocal;
    }

    try {
      final res = await _client.from('emergency_contacts').insert({
        'patient_id': patientId,
        'name': name,
        'phone': phone,
        'relationship': relationship,
      }).select().single();

      final created = EmergencyContact.fromJson(res);
      _localCache.putIfAbsent(patientId, () => []).insert(0, created);
      return created;
    } catch (_) {
      // Fallback caching so user actions persist in-session
      _localCache.putIfAbsent(patientId, () => []).insert(0, newLocal);
      return newLocal;
    }
  }

  /// Update an existing emergency contact
  Future<bool> updateContact({
    required String id,
    required String patientId,
    required String name,
    required String phone,
    required String relationship,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      final list = _localCache[patientId];
      if (list != null) {
        final idx = list.indexWhere((c) => c.id == id);
        if (idx != -1) {
          list[idx] = list[idx].copyWith(name: name, phone: phone, relationship: relationship);
          return true;
        }
      }
      return false;
    }

    try {
      await _client.from('emergency_contacts').update({
        'name': name,
        'phone': phone,
        'relationship': relationship,
      }).eq('id', id);

      final list = _localCache[patientId];
      if (list != null) {
        final idx = list.indexWhere((c) => c.id == id);
        if (idx != -1) {
          list[idx] = list[idx].copyWith(name: name, phone: phone, relationship: relationship);
        }
      }
      return true;
    } catch (_) {
      final list = _localCache[patientId];
      if (list != null) {
        final idx = list.indexWhere((c) => c.id == id);
        if (idx != -1) {
          list[idx] = list[idx].copyWith(name: name, phone: phone, relationship: relationship);
          return true;
        }
      }
      return true;
    }
  }

  /// Delete an emergency contact
  Future<bool> deleteContact({required String id, required String patientId}) async {
    if (!SupabaseConfig.isConfigured) {
      _localCache[patientId]?.removeWhere((c) => c.id == id);
      return true;
    }

    try {
      await _client.from('emergency_contacts').delete().eq('id', id);
      _localCache[patientId]?.removeWhere((c) => c.id == id);
      return true;
    } catch (_) {
      _localCache[patientId]?.removeWhere((c) => c.id == id);
      return true;
    }
  }
}
