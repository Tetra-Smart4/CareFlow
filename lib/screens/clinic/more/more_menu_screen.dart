import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../services/auth_service.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: ColorTokens.muted,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    Color iconColor = ColorTokens.primaryBlue,
    Color iconBgColor = ColorTokens.lightBlue,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ColorTokens.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ColorTokens.darkNavy,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: ColorTokens.muted),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: ColorTokens.muted, size: 20),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('More Modules & Settings'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: ColorTokens.error),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/auth/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // PATIENT CARE
          _buildSectionHeader('PATIENT CARE'),
          _buildMenuItem(
            context: context,
            icon: Icons.folder_shared_outlined,
            title: 'Medical Records',
            subtitle: 'Encounter histories, past visits & summaries',
            route: '/clinic/records',
            iconColor: ColorTokens.primaryBlue,
            iconBgColor: ColorTokens.lightBlue,
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.description_outlined,
            title: 'Medical Reports',
            subtitle: 'Lab, imaging, diagnostic & clinical documents',
            route: '/clinic/reports',
            iconColor: ColorTokens.careGreen,
            iconBgColor: ColorTokens.lightGreen,
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.receipt_long_outlined,
            title: 'Prescriptions & Medications',
            subtitle: 'Doctor-issued prescriptions and adherence',
            route: '/clinic/prescriptions',
            iconColor: ColorTokens.navy,
            iconBgColor: ColorTokens.lightBlue,
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.event_repeat_rounded,
            title: 'Follow-ups',
            subtitle: 'Scheduled post-consultation follow-up appointments',
            route: '/clinic/followups',
            iconColor: ColorTokens.warning,
            iconBgColor: ColorTokens.lightWarning,
          ),

          // CLINIC OPERATIONS
          _buildSectionHeader('CLINIC OPERATIONS'),
          _buildMenuItem(
            context: context,
            icon: Icons.medical_services_outlined,
            title: 'Doctors & Staff',
            subtitle: 'Onboarding, associations, fee approval & roster',
            route: '/clinic/doctors',
            iconColor: ColorTokens.primaryBlue,
            iconBgColor: ColorTokens.lightBlue,
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.calendar_month_outlined,
            title: 'Clinic Calendar & Availability',
            subtitle: 'Clinic schedule, operating hours & doctor slots',
            route: '/clinic/calendar',
            iconColor: ColorTokens.careGreen,
            iconBgColor: ColorTokens.lightGreen,
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.payments_outlined,
            title: 'Billing & Payments',
            subtitle: 'Invoices, payments collected & receipts',
            route: '/clinic/billing',
            iconColor: ColorTokens.navy,
            iconBgColor: ColorTokens.lightBlue,
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.inventory_2_outlined,
            title: 'Medicine Inventory',
            subtitle: 'Clinic stock levels, batches, dispensing & alerts',
            route: '/clinic/inventory',
            iconColor: ColorTokens.warning,
            iconBgColor: ColorTokens.lightWarning,
          ),

          // MANAGEMENT
          _buildSectionHeader('MANAGEMENT'),
          _buildMenuItem(
            context: context,
            icon: Icons.bar_chart_rounded,
            title: 'Analytics & Reports',
            subtitle: 'Operational KPIs, clinical volume & revenue',
            route: '/clinic/analytics',
            iconColor: ColorTokens.primaryBlue,
            iconBgColor: ColorTokens.lightBlue,
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Operational alerts, check-ins & fee requests',
            route: '/clinic/notifications',
            iconColor: ColorTokens.navy,
            iconBgColor: ColorTokens.lightBlue,
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.manage_accounts_outlined,
            title: 'User Management',
            subtitle: 'Clinic staff access & role permissions',
            route: '/clinic/users',
            iconColor: ColorTokens.careGreen,
            iconBgColor: ColorTokens.lightGreen,
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.tune_rounded,
            title: 'Clinic Settings',
            subtitle: 'Clinic profile, contact, address & services',
            route: '/clinic/settings',
            iconColor: ColorTokens.muted,
            iconBgColor: ColorTokens.border,
          ),
        ],
      ),
    );
  }
}
