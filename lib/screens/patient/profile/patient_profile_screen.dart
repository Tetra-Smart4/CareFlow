import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../models/profile.dart';
import '../../../services/auth_service.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  Profile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await AuthService().getCurrentProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.darkNavy)),
        content: const Text('Are you sure you want to log out of CareFlow?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorTokens.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?.fullName.isNotEmpty == true
        ? _profile!.fullName
        : (AuthService().currentUser?.email?.split('@').first ?? 'Patient');
    final email = _profile?.email.isNotEmpty == true
        ? _profile!.email
        : (AuthService().currentUser?.email ?? 'patient@careflow.com');
    final phone = _profile?.phone ?? 'Not set';
    final address = _profile?.address ?? 'Not set';

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.darkNavy)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: ColorTokens.error),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  // Profile Card
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: ColorTokens.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: ColorTokens.primaryBlue.withValues(alpha: 0.12),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'P',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: ColorTokens.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: ColorTokens.darkNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: ColorTokens.textSecondary,
                            ),
                          ),
                          if (_profile?.phone != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              phone,
                              style: const TextStyle(
                                fontSize: 13,
                                color: ColorTokens.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Emergency Contacts Tile (Critical Section 10)
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: ColorTokens.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorTokens.lightBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.contact_emergency_rounded, color: ColorTokens.primaryBlue, size: 22),
                      ),
                      title: const Text(
                        'Emergency Contacts',
                        style: TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
                      ),
                      subtitle: const Text(
                        'Manage emergency contacts linked to your account',
                        style: TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: ColorTokens.textMuted),
                      onTap: () => Navigator.pushNamed(context, '/patient/emergency'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Account Information Tile
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: ColorTokens.border),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: ColorTokens.primaryBlue),
                          title: const Text('Address', style: TextStyle(fontSize: 13, color: ColorTokens.textSecondary)),
                          subtitle: Text(
                            address,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: ColorTokens.darkNavy),
                          ),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined, color: ColorTokens.primaryBlue),
                          title: const Text('Phone Number', style: TextStyle(fontSize: 13, color: ColorTokens.textSecondary)),
                          subtitle: Text(
                            phone,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: ColorTokens.darkNavy),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Logout Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorTokens.error,
                      side: const BorderSide(color: ColorTokens.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ],
              ),
            ),
    );
  }
}
