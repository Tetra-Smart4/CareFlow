import 'package:flutter/material.dart';

import 'config/supabase_config.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/push_notification_service.dart';
import '../widgets/common/careflow_brand_title.dart';

class CareFlowApp extends StatefulWidget {
  const CareFlowApp({super.key});

  @override
  State<CareFlowApp> createState() => _CareFlowAppState();
}

class _CareFlowAppState extends State<CareFlowApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<AuthState>? _authStateSubscription;
  StreamSubscription<PushNotificationEvent>? _pushSubscription;

  @override
  void initState() {
    super.initState();
    PushNotificationService.navigatorKey = _navigatorKey;

    _pushSubscription = PushNotificationService().onNotificationReceived.listen((event) {
      _showInAppNotificationBanner(event);
    });

    if (SupabaseConfig.isConfigured) {
      try {
        _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          final AuthChangeEvent event = data.event;
          
          switch (event) {
            case AuthChangeEvent.signedOut:
              // Explicitly logged out or session expired/invalid
              _navigatorKey.currentState?.pushNamedAndRemoveUntil('/auth/login', (route) => false);
              break;
            case AuthChangeEvent.passwordRecovery:
              _navigatorKey.currentState?.pushNamed('/auth/reset-password');
              break;
            case AuthChangeEvent.signedIn:
            case AuthChangeEvent.initialSession:
            case AuthChangeEvent.tokenRefreshed:
            case AuthChangeEvent.userUpdated:
            case AuthChangeEvent.mfaChallengeVerified:
              // Handled globally or by specific screens
            default:
              break;
          }
        });
      } catch (_) {}
    }
  }

  void _showInAppNotificationBanner(PushNotificationEvent event) {
    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Color(0xFF38BDF8), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                  ),
                  if (event.body.isNotEmpty)
                    Text(
                      event.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: const Color(0xFF38BDF8),
          onPressed: () {
            final type = event.type;
            final doseId = event.doseId;
            final nav = _navigatorKey.currentState;
            if (nav != null) {
              if (type == 'caregiver_escalation' || type == 'caregiver_alert') {
                nav.pushNamed('/family/dashboard');
              } else if (type == 'patient_reminder' || type == 'medication_reminder' || doseId != null) {
                nav.pushNamed('/patient/medications/reminder');
              } else if (type == 'appointment') {
                nav.pushNamed('/patient/appointments');
              } else if (type == 'queue') {
                nav.pushNamed('/patient/queue');
              } else if (type == 'report') {
                nav.pushNamed('/patient/reports');
              } else if (type == 'prescription') {
                nav.pushNamed('/patient/prescriptions');
              } else {
                nav.pushNamed('/notifications');
              }
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pushSubscription?.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'CareFlow',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.light(),

      // ------------------------------------------------------------
      // IMPORTANT:
      // The application MUST start with the common splash screen.
      // Do NOT use:
      // initialRoute: '/splash/patient'
      //
      // The flow is:
      // Splash → Role Selection → Selected Login → Dashboard
      // ------------------------------------------------------------
      initialRoute: AppRouter.splash,

      routes: AppRouter.routes,

      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) {
            return Scaffold(
              appBar: AppBar(title: const CareFlowBrandTitle()),
              body: Center(child: Text('Route not found: ${settings.name}')),
            );
          },
        );
      },

      builder: (context, child) {
        // ----------------------------------------------------------
        // DEMO banner when Supabase configuration is unavailable.
        // ----------------------------------------------------------
        if (!SupabaseConfig.isConfigured) {
          return Banner(
            message: 'DEMO',
            location: BannerLocation.topEnd,
            child: child ?? const SizedBox.shrink(),
          );
        }

        return child ?? const SizedBox.shrink();
      },
    );
  }
}
