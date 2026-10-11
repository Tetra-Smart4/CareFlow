import 'package:flutter/material.dart';
import '../../core/theme/color_tokens.dart';
import '../../services/auth_service.dart';

class ClinicPendingScreen extends StatefulWidget {
  const ClinicPendingScreen({super.key});

  @override
  State<ClinicPendingScreen> createState() => _ClinicPendingScreenState();
}

class _ClinicPendingScreenState extends State<ClinicPendingScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    final user = AuthService().currentUser;
    if (user != null) {
      final status = await AuthService().getClinicApprovalStatus(user.id);
      if (mounted) {
        if (status.toLowerCase() == 'approved') {
          Navigator.pushReplacementNamed(context, '/clinic/dashboard');
          return;
        } else if (status.toLowerCase() == 'rejected') {
          Navigator.pushReplacementNamed(context, '/clinic/rejected');
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your application is still under review by the administrator.'),
            ),
          );
        }
      }
    }
    if (mounted) setState(() => _isChecking = false);
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/auth/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text(
          'Registration Status',
          style: TextStyle(fontWeight: FontWeight.bold, color: ColorTokens.darkNavy),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: ColorTokens.darkNavy),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: ColorTokens.border),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: ColorTokens.warning.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        color: ColorTokens.warning,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Clinic Registration Submitted',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: ColorTokens.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: ColorTokens.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: ColorTokens.warning),
                          SizedBox(width: 6),
                          Text(
                            'Status: Pending Admin Approval',
                            style: TextStyle(
                              color: ColorTokens.warning,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Your clinic registration is under review.\nOnce our platform administrator verifies and approves your clinic, full clinical and scheduling capabilities will become active.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorTokens.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorTokens.primaryBlue,
                          foregroundColor: ColorTokens.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isChecking ? null : _checkStatus,
                        icon: _isChecking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(_isChecking ? 'Checking...' : 'Check Approval Status'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, size: 18, color: ColorTokens.textSecondary),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: ColorTokens.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
