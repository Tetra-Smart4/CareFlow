import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../services/auth_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _authService = AuthService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _clinic;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'User not authenticated.';
        });
        return;
      }

      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      Map<String, dynamic>? clinicData;
      try {
        final cd = await Supabase.instance.client
            .from('clinic_doctors')
            .select('clinic_id, is_available, clinics(*)')
            .eq('doctor_id', user.id)
            .limit(1)
            .maybeSingle();

        if (cd != null && cd['clinics'] != null && cd['clinics'] is Map) {
          clinicData = Map<String, dynamic>.from(cd['clinics'] as Map);
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _profile = profileData;
          _clinic = clinicData;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load profile.';
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of CareFlow?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorTokens.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.signOut();
      } catch (_) {
        await Supabase.instance.client.auth.signOut();
      }
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth/login', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadProfile,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: ColorTokens.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: ColorTokens.muted)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 16),
                    _buildProfessionalInfoCard(),
                    const SizedBox(height: 16),
                    _buildClinicCard(),
                    const SizedBox(height: 16),
                    _buildAvailabilityCard(),
                    const SizedBox(height: 16),
                    _buildSettingsCard(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorTokens.error,
                          side: const BorderSide(color: ColorTokens.error),
                        ),
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
    );
  }

  Widget _buildHeaderCard() {
    final name = _profile?['full_name'] ?? 'Doctor';
    final spec = _profile?['specialization'] ?? 'Healthcare Specialist';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: ColorTokens.lightBlue,
              child: Text(
                _initials(name),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: ColorTokens.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: ColorTokens.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              spec,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorTokens.primaryBlue,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: ColorTokens.lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Active Doctor Account',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ColorTokens.careGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfoCard() {
    final qual = _profile?['qualification']?.toString() ?? 'MBBS';
    final regNo = _profile?['registration_number']?.toString() ?? 'CF-${_profile?['id']?.toString().substring(0, 6).toUpperCase() ?? '001'}';
    final fee = _profile?['consultation_fee'];
    final exp = _profile?['experience'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Professional Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ColorTokens.navy,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow('Qualification', qual),
            const Divider(height: 20),
            _infoRow('Registration Number', regNo),
            if (exp != null) ...[
              const Divider(height: 20),
              _infoRow('Experience', '$exp years'),
            ],
            if (fee != null) ...[
              const Divider(height: 20),
              _infoRow('Consultation Fee', '₹$fee'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClinicCard() {
    final clinicName = _clinic?['name']?.toString() ?? 'CareFlow Health Center';
    final clinicPhone = _clinic?['phone']?.toString() ?? '';
    final clinicCity = _clinic?['city']?.toString() ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Associated Clinic',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ColorTokens.navy,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow('Clinic Name', clinicName),
            if (clinicPhone.isNotEmpty) ...[
              const Divider(height: 20),
              _infoRow('Clinic Contact', clinicPhone),
            ],
            if (clinicCity.isNotEmpty) ...[
              const Divider(height: 20),
              _infoRow('Location', clinicCity),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Practice Hours & Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ColorTokens.navy,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow('Working Days', 'Monday – Saturday'),
            const Divider(height: 20),
            _infoRow('Working Hours', '09:00 AM – 05:00 PM'),
            const Divider(height: 20),
            _infoRow('Slot Duration', '30 Minutes'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: ColorTokens.primaryBlue),
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/doctor/notifications'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: ColorTokens.primaryBlue),
            title: const Text('Security & Password', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password management available in account settings.')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline, color: ColorTokens.primaryBlue),
            title: const Text('About CareFlow', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Version 1.0.0 • Professional Clinic Suite'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: ColorTokens.muted)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ColorTokens.navy),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
