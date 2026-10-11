import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AuthGuardWidget extends StatefulWidget {
  final Widget child;
  final List<String> allowedRoles;

  const AuthGuardWidget({
    required this.child,
    required this.allowedRoles,
    super.key,
  });

  @override
  State<AuthGuardWidget> createState() => _AuthGuardWidgetState();
}

class _AuthGuardWidgetState extends State<AuthGuardWidget> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  Future<void> _checkAuthorization() async {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      _redirect('/auth/login');
      return;
    }

    final profile = await authService.getCurrentProfile();
    if (profile == null) {
      await authService.signOut();
      _redirect('/auth/login');
      return;
    }

    final role = profile.role.toLowerCase();
    String effectiveRole = role;

    // Determine specific platform admin
    if (role == 'platform_admin' || (role == 'admin' && profile.clinicName == null && (user.email ?? '').contains('admin'))) {
      effectiveRole = 'platform_admin';
    } 
    // Determine clinic status
    else if (role == 'clinic' || role == 'admin') {
      final status = await authService.getClinicApprovalStatus(user.id);
      if (status.toLowerCase() == 'pending') {
        effectiveRole = 'clinic_pending';
      } else if (status.toLowerCase() == 'rejected') {
        effectiveRole = 'clinic_rejected';
      } else if (status.toLowerCase() == 'suspended') {
        await authService.signOut();
        _redirect('/auth/login');
        return;
      } else {
        effectiveRole = 'clinic';
      }
    }

    if (widget.allowedRoles.contains(effectiveRole)) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } else {
      // Unauthorized for this route. Boot them to their proper dashboard.
      final fallbackRoute = await authService.getInitialRoute();
      _redirect(fallbackRoute);
    }
  }

  void _redirect(String route) {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.child;
  }
}
