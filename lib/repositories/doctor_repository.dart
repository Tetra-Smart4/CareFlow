import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorRepository {
  SupabaseClient get client => Supabase.instance.client;

  /// Returns real doctors from the database with specialization, qualifications, and clinics.
  Future<List<Map<String, dynamic>>> list({String? orderBy}) async {
    // 1. Try RPC careflow_list_doctors
    try {
      final rpcData = await client.rpc('careflow_list_doctors');
      if (rpcData is List && rpcData.isNotEmpty) {
        return List<Map<String, dynamic>>.from(rpcData);
      }
    } catch (_) {}

    // 2. Query profiles with role = 'doctor'
    try {
      final data = await client
          .from('profiles')
          .select('id, full_name, email, phone, gender, age, specialization, qualification, experience, consultation_fee, registration_number, bio, status')
          .eq('role', 'doctor');

      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Returns doctors assigned to a specific clinic with enriched status and fee proposals.
  Future<List<Map<String, dynamic>>> getByClinic(String clinicId) async {
    // 1. Try secure RPC careflow_get_clinic_doctors
    try {
      final rpcData = await client.rpc('careflow_get_clinic_doctors', params: {
        'p_clinic_id': clinicId,
      });

      if (rpcData is List) {
        return List<Map<String, dynamic>>.from(rpcData.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          map['id'] = map['doctor_id'];
          return map;
        }));
      }
    } catch (_) {}

    // 2. Fallback direct table query
    try {
      final assignments = await client
          .from('clinic_doctors')
          .select('doctor_id, is_available, active, status, consultation_fee, invited_at, activated_at')
          .eq('clinic_id', clinicId)
          .neq('status', 'removed');

      if (assignments.isEmpty) return [];

      final doctorIds = assignments.map((e) => e['doctor_id'].toString()).toList();
      final profiles = await client
          .from('profiles')
          .select()
          .inFilter('id', doctorIds);

      final map = <String, Map<String, dynamic>>{};
      for (final a in assignments) {
        map[a['doctor_id'].toString()] = a;
      }

      // Also fetch fee proposals from careflow_doctor_clinic_fees
      final feeList = await client
          .from('careflow_doctor_clinic_fees')
          .select()
          .eq('clinic_id', clinicId)
          .inFilter('doctor_id', doctorIds);

      final feeMap = <String, Map<String, dynamic>>{};
      for (final f in feeList) {
        feeMap[f['doctor_id'].toString()] = f;
      }

      final List<Map<String, dynamic>> results = [];
      for (final p in profiles) {
        final dId = p['id'].toString();
        final copy = Map<String, dynamic>.from(p);
        if (map.containsKey(dId)) {
          copy['is_available'] = map[dId]!['is_available'];
          copy['active'] = map[dId]!['active'];
          copy['status'] = map[dId]!['status'] ?? copy['status'];
          copy['consultation_fee'] = map[dId]!['consultation_fee'] ?? copy['consultation_fee'];
          copy['invited_at'] = map[dId]!['invited_at'];
          copy['activated_at'] = map[dId]!['activated_at'];
        }
        if (feeMap.containsKey(dId)) {
          final f = feeMap[dId]!;
          copy['approved_fee'] = f['approved_fee'] ?? copy['consultation_fee'];
          copy['proposed_fee'] = f['proposed_fee'];
          copy['proposal_status'] = f['proposal_status'] ?? 'none';
          copy['proposed_at'] = f['proposed_at'];
        } else {
          copy['approved_fee'] = copy['consultation_fee'];
          copy['proposal_status'] = 'none';
        }
        results.add(copy);
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  /// Returns clinic associations and fees for a doctor.
  Future<List<Map<String, dynamic>>> getDoctorClinicAssociations(String doctorId) async {
    try {
      final assocs = await client
          .from('clinic_doctors')
          .select('clinic_id, active, is_available, status, consultation_fee, clinics(*)')
          .eq('doctor_id', doctorId)
          .neq('status', 'removed');

      final List<Map<String, dynamic>> results = [];
      for (final a in assocs) {
        final copy = Map<String, dynamic>.from(a);
        final clinicId = a['clinic_id'].toString();

        // Query fee proposal for this clinic
        try {
          final feeRow = await client
              .from('careflow_doctor_clinic_fees')
              .select()
              .eq('clinic_id', clinicId)
              .eq('doctor_id', doctorId)
              .maybeSingle();

          if (feeRow != null) {
            copy['approved_fee'] = feeRow['approved_fee'] ?? a['consultation_fee'];
            copy['proposed_fee'] = feeRow['proposed_fee'];
            copy['proposal_status'] = feeRow['proposal_status'] ?? 'none';
            copy['proposed_at'] = feeRow['proposed_at'];
            copy['rejection_reason'] = feeRow['rejection_reason'];
          } else {
            copy['approved_fee'] = a['consultation_fee'];
            copy['proposal_status'] = 'none';
          }
        } catch (_) {
          copy['approved_fee'] = a['consultation_fee'];
          copy['proposal_status'] = 'none';
        }

        results.add(copy);
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Returns a single doctor by profile ID.
  Future<Map<String, dynamic>?> getById(String doctorId) async {
    try {
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', doctorId)
          .eq('role', 'doctor')
          .maybeSingle();

      if (profile == null) return null;

      // Merge data from doctors table
      try {
        final doc = await client
            .from('doctors')
            .select()
            .eq('id', doctorId)
            .maybeSingle();

        if (doc != null) {
          final merged = Map<String, dynamic>.from(profile);
          merged['specialization'] = doc['specialization'] ?? profile['specialization'];
          merged['qualification'] = doc['qualification'] ?? profile['qualification'];
          merged['experience'] = doc['experience'] ?? profile['experience'];
          merged['consultation_fee'] = doc['consultation_fee'] ?? profile['consultation_fee'];
          merged['registration_number'] = doc['registration_number'] ?? profile['registration_number'];
          merged['bio'] = doc['bio'] ?? profile['bio'];
          merged['doctor_id_code'] = doc['doctor_id'];
          return merged;
        }
      } catch (_) {}

      return profile;
    } catch (_) {
      return null;
    }
  }

  /// Toggles doctor availability.
  Future<void> setAvailability(String doctorId, bool isAvailable, {String? clinicId}) async {
    if (clinicId != null) {
      await client
          .from('clinic_doctors')
          .update({'is_available': isAvailable})
          .eq('doctor_id', doctorId)
          .eq('clinic_id', clinicId);
    }

    try {
      await client
          .from('doctors')
          .update({'is_available': isAvailable})
          .eq('id', doctorId);
    } catch (_) {}
  }

  /// Doctor proposes consultation fee for a specific clinic association.
  Future<void> proposeConsultationFee(String clinicId, double proposedFee) async {
    await client.rpc('careflow_propose_consultation_fee', params: {
      'p_clinic_id': clinicId,
      'p_proposed_fee': proposedFee,
    });
  }

  /// Clinic approves a doctor's proposed consultation fee.
  Future<void> approveConsultationFee(String doctorId, String clinicId) async {
    await client.rpc('careflow_approve_consultation_fee', params: {
      'p_doctor_id': doctorId,
      'p_clinic_id': clinicId,
    });
  }

  /// Clinic rejects a doctor's proposed consultation fee.
  Future<void> rejectConsultationFee(String doctorId, String clinicId, {String? reason}) async {
    await client.rpc('careflow_reject_consultation_fee', params: {
      'p_doctor_id': doctorId,
      'p_clinic_id': clinicId,
      'p_reason': reason ?? 'Does not align with clinic pricing.',
    });
  }

  /// Clinic deactivates a doctor at the clinic (soft deactivation).
  Future<void> deactivateDoctor(String doctorId, String clinicId, {bool cancelUpcoming = false}) async {
    await client.rpc('careflow_deactivate_clinic_doctor', params: {
      'p_doctor_id': doctorId,
      'p_clinic_id': clinicId,
      'p_cancel_upcoming': cancelUpcoming,
    });
  }

  /// Clinic reactivates a doctor at the clinic.
  Future<void> reactivateDoctor(String doctorId, String clinicId) async {
    await client.rpc('careflow_reactivate_clinic_doctor', params: {
      'p_doctor_id': doctorId,
      'p_clinic_id': clinicId,
    });
  }

  /// Clinic removes doctor association (non-destructive; preserves medical history & auth account).
  Future<void> removeDoctor(String doctorId, String clinicId) async {
    await client.rpc('careflow_remove_clinic_doctor', params: {
      'p_doctor_id': doctorId,
      'p_clinic_id': clinicId,
    });
  }

  /// Resends email invitation to doctor.
  Future<Map<String, dynamic>> resendInvitation(String email, {String? doctorId}) async {
    final response = await client.functions.invoke(
      'create-doctor',
      body: {
        'action': 'resend_invite',
        'email': email.trim().toLowerCase(),
        'doctor_id': ?doctorId,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'success': true, 'message': 'Invitation resent successfully.'};
  }

  /// Doctor updates their permitted professional details.
  Future<void> updateProfessionalProfile({
    required String doctorId,
    String? fullName,
    String? phone,
    String? specialization,
    String? qualification,
    int? experience,
    String? registrationNumber,
    String? bio,
  }) async {
    // 1. Update profiles table
    final profilePayload = <String, dynamic>{};
    if (fullName != null) profilePayload['full_name'] = fullName;
    if (phone != null) profilePayload['phone'] = phone;
    if (qualification != null) profilePayload['qualification'] = qualification;
    if (registrationNumber != null) profilePayload['registration_number'] = registrationNumber;
    if (bio != null) profilePayload['bio'] = bio;

    if (profilePayload.isNotEmpty) {
      await client
          .from('profiles')
          .update(profilePayload)
          .eq('id', doctorId);
    }

    // 2. Update doctors table
    final doctorPayload = <String, dynamic>{};
    if (specialization != null) doctorPayload['specialization'] = specialization;
    if (qualification != null) doctorPayload['qualification'] = qualification;
    if (experience != null) doctorPayload['experience'] = experience;
    if (registrationNumber != null) doctorPayload['registration_number'] = registrationNumber;
    if (bio != null) doctorPayload['bio'] = bio;

    if (doctorPayload.isNotEmpty) {
      await client
          .from('doctors')
          .upsert({
            'id': doctorId,
            ...doctorPayload,
          });
    }
  }

  /// Activates doctor account after password setup.
  Future<void> activateDoctorAccount(String doctorId) async {
    try {
      await client.rpc('careflow_activate_doctor_account', params: {
        'p_doctor_id': doctorId,
      });
    } catch (_) {
      try {
        await client
            .from('profiles')
            .update({'status': 'active'})
            .eq('id', doctorId);
        await client
            .from('clinic_doctors')
            .update({'status': 'active'})
            .eq('doctor_id', doctorId);
      } catch (_) {}
    }
  }
}
