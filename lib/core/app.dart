import 'package:flutter/material.dart';

import 'config/supabase_config.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class CareFlowApp extends StatelessWidget {
  const CareFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
              appBar: AppBar(title: const Text('CareFlow')),
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
