import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/profile.dart';
import 'realtime_service.dart';
import 'push_notification_service.dart';

class AuthResult {
  final bool success;
  final String? error;
  final String? role;
  final String? destinationRoute;
  final String? clinicStatus;
  final Profile? profile;

  const AuthResult({
    required this.success,
    this.error,
    this.role,
    this.destinationRoute,
    this.clinicStatus,
    this.profile,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return _client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Patient Registration:
  /// Creates Auth account -> Inserts into profiles -> Inserts into patients -> Ready for dashboard
  Future<AuthResult> registerPatient({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    DateTime? dateOfBirth,
    int? age,
    String? gender,
    String? address,
    String? city,
    String? state,
    String? pincode,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return const AuthResult(
        success: true,
        role: 'patient',
        destinationRoute: '/patient/dashboard',
      );
    }

    try {
      final calculatedAge = age ??
          (dateOfBirth != null
              ? (DateTime.now().difference(dateOfBirth).inDays ~/ 365)
              : null);

      final fullAddress = [address, city, state, pincode]
          .where((part) => part != null && part.trim().isNotEmpty)
          .join(', ');

      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': 'patient',
          'phone': phone,
        },
      );

      final user = authResponse.user;
      if (user == null) {
        return const AuthResult(
          success: false,
          error: 'Registration failed. No user was created.',
        );
      }

      // Create profile record in PostgreSQL
      try {
        final profilePayload = <String, dynamic>{
          'id': user.id,
          'full_name': fullName,
          'role': 'patient',
          'phone': phone,
          'age': calculatedAge,
          'gender': gender,
          'address': fullAddress.isNotEmpty ? fullAddress : address,
          'status': 'active',
        };

        if (dateOfBirth != null) {
          profilePayload['date_of_birth'] = dateOfBirth.toIso8601String().split('T').first;
        }
        if (city != null) profilePayload['city'] = city;
        if (state != null) profilePayload['state'] = state;
        if (pincode != null) profilePayload['pincode'] = pincode;

        await _client.from('profiles').upsert(profilePayload);
      } catch (e) {
        // Fallback to core columns if extra columns not yet in DB
        try {
          await _client.from('profiles').upsert({
            'id': user.id,
            'full_name': fullName,
            'role': 'patient',
            'phone': phone,
            'age': calculatedAge,
            'gender': gender,
            'address': fullAddress.isNotEmpty ? fullAddress : address,
            'status': 'active',
          });
        } catch (inner) {
          return AuthResult(
            success: false,
            error: 'Failed to create patient profile: $inner',
          );
        }
      }

      // Create patient-specific record
      try {
        await _client.from('patients').upsert({
          'id': user.id,
        });
      } catch (_) {}

      return const AuthResult(
        success: true,
        role: 'patient',
        destinationRoute: '/patient/dashboard',
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('user already exists')) {
        return const AuthResult(
          success: false,
          error: 'An account already exists with this email. Please log in instead.',
        );
      }
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return AuthResult(success: false, error: 'Registration error: $e');
    }
  }

  /// Clinic Registration:
  /// Creates Auth account -> Inserts into profiles -> Inserts into clinics with status = 'pending'
  Future<AuthResult> registerClinic({
    required String email,
    required String password,
    required String clinicName,
    required String contactName,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? clinicType,
    String? about,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return const AuthResult(
        success: true,
        role: 'clinic',
        clinicStatus: 'pending',
        destinationRoute: '/clinic/pending',
      );
    }

    try {
      final fullAddress = [address, city, state, pincode]
          .where((part) => part != null && part.trim().isNotEmpty)
          .join(', ');

      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': contactName,
          'clinic_name': clinicName,
          'role': 'clinic',
          'phone': phone,
        },
      );

      final user = authResponse.user;
      if (user == null) {
        return const AuthResult(
          success: false,
          error: 'Registration failed. No user was created.',
        );
      }

      // Create clinic profile in PostgreSQL
      try {
        final profilePayload = <String, dynamic>{
          'id': user.id,
          'full_name': contactName,
          'clinic_name': clinicName,
          'role': 'clinic',
          'phone': phone,
          'address': fullAddress.isNotEmpty ? fullAddress : address,
          'status': 'pending',
        };
        if (city != null) profilePayload['city'] = city;
        if (state != null) profilePayload['state'] = state;
        if (pincode != null) profilePayload['pincode'] = pincode;

        await _client.from('profiles').upsert(profilePayload);
      } catch (e) {
        try {
          await _client.from('profiles').upsert({
            'id': user.id,
            'full_name': contactName,
            'clinic_name': clinicName,
            'role': 'clinic',
            'phone': phone,
            'address': fullAddress.isNotEmpty ? fullAddress : address,
            'status': 'pending',
          });
        } catch (inner) {
          return AuthResult(
            success: false,
            error: 'Failed to create clinic profile: $inner',
          );
        }
      }

      // Create clinic record with status = 'pending'
      final generatedClinicId = 'CLN-${user.id.replaceAll('-', '').substring(0, 8).toUpperCase()}';
      try {
        final clinicPayload = <String, dynamic>{
          'id': user.id,
          'clinic_id': generatedClinicId,
          'name': clinicName,
          'email': email,
          'phone': phone,
          'address': fullAddress.isNotEmpty ? fullAddress : address,
          'status': 'pending',
        };
        if (city != null) clinicPayload['city'] = city;
        if (state != null) clinicPayload['state'] = state;
        if (pincode != null) clinicPayload['pincode'] = pincode;
        if (clinicType != null) clinicPayload['clinic_type'] = clinicType;
        if (about != null) clinicPayload['description'] = about;

        await _client.from('clinics').upsert(clinicPayload);
      } catch (_) {
        // Fallback if extra columns not yet added to clinics
        try {
          await _client.from('clinics').upsert({
            'id': user.id,
            'clinic_id': generatedClinicId,
            'name': clinicName,
            'address': fullAddress.isNotEmpty ? fullAddress : address,
            'phone': phone,
            'status': 'pending',
          });
        } catch (_) {
          try {
            await _client.from('clinics').upsert({
              'id': user.id,
              'clinic_id': generatedClinicId,
            });
          } catch (_) {}
        }
      }

      return const AuthResult(
        success: true,
        role: 'clinic',
        clinicStatus: 'pending',
        destinationRoute: '/clinic/pending',
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('user already exists')) {
        return const AuthResult(
          success: false,
          error: 'An account already exists with this email. Please log in instead.',
        );
      }
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return AuthResult(success: false, error: 'Registration error: $e');
    }
  }

  /// Sign In with Role-Based & Approval Check
  Future<AuthResult> signIn(String email, String password, {String? expectedRole}) async {
    if (!SupabaseConfig.isConfigured) {
      return const AuthResult(
        success: true,
        role: 'patient',
        destinationRoute: '/patient/dashboard',
      );
    }

    try {
      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        return const AuthResult(
          success: false,
          error: 'Login succeeded, but no authenticated user was returned.',
        );
      }

      // Fetch user profile from PostgreSQL
      final profileData = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileData == null) {
        await _client.auth.signOut();
        return const AuthResult(
          success: false,
          error: 'Your account profile was not found. Please contact support.',
        );
      }

      final profile = Profile.fromJson(profileData);
      final role = profile.role.toLowerCase();

      // Check for Platform Admin
      if (role == 'platform_admin' || (role == 'admin' && profile.clinicName == null && email.contains('admin'))) {
        return AuthResult(
          success: true,
          role: 'admin',
          destinationRoute: '/admin/platform-dashboard',
          profile: profile,
        );
      }

      // Check for Doctor
      if (role == 'doctor') {
        return AuthResult(
          success: true,
          role: 'doctor',
          destinationRoute: '/doctor/dashboard',
          profile: profile,
        );
      }

      // Check for Clinic
      if (role == 'clinic' || role == 'admin') {
        // Check clinic approval status
        String clinicStatus = 'approved';
        try {
          final clinicRec = await _client
              .from('clinics')
              .select('status')
              .eq('id', user.id)
              .maybeSingle();

          if (clinicRec != null && clinicRec['status'] != null) {
            clinicStatus = clinicRec['status'].toString().toLowerCase();
          }
        } catch (_) {}

        if (clinicStatus == 'pending') {
          return AuthResult(
            success: true,
            role: 'clinic',
            clinicStatus: 'pending',
            destinationRoute: '/clinic/pending',
            profile: profile,
          );
        } else if (clinicStatus == 'rejected') {
          return AuthResult(
            success: true,
            role: 'clinic',
            clinicStatus: 'rejected',
            destinationRoute: '/clinic/rejected',
            profile: profile,
          );
        } else if (clinicStatus == 'suspended') {
          await _client.auth.signOut();
          return const AuthResult(
            success: false,
            error: 'This clinic account has been suspended by the platform administrator.',
          );
        }

        return AuthResult(
          success: true,
          role: 'clinic',
          clinicStatus: 'approved',
          destinationRoute: '/clinic/dashboard',
          profile: profile,
        );
      }

      // Patient default
      return AuthResult(
        success: true,
        role: 'patient',
        destinationRoute: '/patient/dashboard',
        profile: profile,
      );
    } on AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return AuthResult(success: false, error: 'Login error: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await PushNotificationService().deactivateDeviceToken();
      await RealtimeService().dispose();
      if (SupabaseConfig.isConfigured) {
        await _client.auth.signOut();
      }
    } catch (_) {}
  }

  Future<Profile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return data != null ? Profile.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  Future<String> getClinicApprovalStatus(String clinicId) async {
    try {
      final res = await _client
          .from('clinics')
          .select('status')
          .eq('id', clinicId)
          .maybeSingle();

      if (res != null && res['status'] != null) {
        return res['status'].toString();
      }
    } catch (_) {}
    return 'approved';
  }

  Future<void> resetPassword(String email) async {
    if (SupabaseConfig.isConfigured) {
      await _client.auth.resetPasswordForEmail(email.trim());
    }
  }

  Future<String> getInitialRoute() async {
    final user = currentUser;
    if (user == null) {
      return '/auth/login';
    }

    try {
      final profile = await getCurrentProfile();
      if (profile == null) {
        return '/auth/login';
      }

      final role = profile.role.toLowerCase();
      if (role == 'platform_admin' || (role == 'admin' && profile.clinicName == null && (user.email ?? '').contains('admin'))) {
        return '/admin/platform-dashboard';
      }

      if (role == 'doctor') {
        return '/doctor/dashboard';
      }

      if (role == 'clinic' || role == 'admin') {
        final clinicStatus = await getClinicApprovalStatus(user.id);
        if (clinicStatus.toLowerCase() == 'pending') {
          return '/clinic/pending';
        } else if (clinicStatus.toLowerCase() == 'rejected') {
          return '/clinic/rejected';
        }
        return '/clinic/dashboard';
      }

      return '/patient/dashboard';
    } catch (_) {
      return '/auth/login';
    }
  }
}
