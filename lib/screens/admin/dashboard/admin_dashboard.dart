import 'package:flutter/material.dart';
import 'package:careflow/core/theme/app_colors.dart';
import 'package:careflow/widgets/common/module_card.dart';

IconData iconFor(String name) {
  const map = <String, IconData>{
    'search': Icons.search,
    'calendar': Icons.calendar_month,
    'queue': Icons.people_alt_outlined,
    'records': Icons.folder_open,
    'prescription': Icons.receipt_long,
    'medication': Icons.medication_outlined,
    'health': Icons.insights,
    'bill': Icons.payments_outlined,
    'followup': Icons.event_repeat,
    'notification': Icons.notifications_none,
    'emergency': Icons.emergency,
    'profile': Icons.person_outline,
    'appointments': Icons.calendar_today,
    'patients': Icons.person_search,
    'consultation': Icons.medical_information,
    'history': Icons.history,
    'adherence': Icons.fact_check,
    'analytics': Icons.bar_chart,
    'settings': Icons.settings,
    'quick': Icons.flash_on,
    'doctors': Icons.medical_services,
    'checkin': Icons.how_to_reg,
    'reports': Icons.description,
    'revenue': Icons.trending_up,
    'inventory': Icons.inventory_2,
    'users': Icons.manage_accounts,
    'menu': Icons.menu,
    'more': Icons.more_horiz,
  };
  return map[name] ?? Icons.medical_services_outlined;
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selected = 0;
  void nav(int i) {
    if (i == 0) {
      setState(() => selected = 0);
      return;
    }
    final routes = [
      '/admin/dashboard',
      '/admin/appointments',
      '/admin/patients',
      '/admin/doctors',
      '/admin/more',
    ];
    Navigator.pushReplacementNamed(context, routes[i]);
  }

  @override
  Widget build(BuildContext context) {
    final modules = <Map<String, String>>[
      {
        'title': 'Appointments',
        'subtitle': 'Manage bookings',
        'icon': 'appointments',
        'route': '/admin/appointments',
      },
      {
        'title': 'Patients',
        'subtitle': 'Patient records',
        'icon': 'patients',
        'route': '/admin/patients',
      },
      {
        'title': 'Doctors',
        'subtitle': 'Doctor management',
        'icon': 'doctors',
        'route': '/admin/doctors',
      },
      {
        'title': 'Clinic Queue',
        'subtitle': 'Live queue',
        'icon': 'queue',
        'route': '/admin/queue',
      },
      {
        'title': 'Check-in',
        'subtitle': 'Front desk',
        'icon': 'checkin',
        'route': '/admin/checkin',
      },
      {
        'title': 'Billing & Payments',
        'subtitle': 'Invoices',
        'icon': 'bill',
        'route': '/admin/billing',
      },
      {
        'title': 'Medical Records',
        'subtitle': 'Patient records',
        'icon': 'records',
        'route': '/admin/records',
      },
      {
        'title': 'Prescriptions',
        'subtitle': 'Medication records',
        'icon': 'prescription',
        'route': '/admin/prescriptions',
      },
      {
        'title': 'Follow-ups',
        'subtitle': 'Pending reviews',
        'icon': 'followup',
        'route': '/admin/followups',
      },
      {
        'title': 'Notifications',
        'subtitle': 'Clinic alerts',
        'icon': 'notification',
        'route': '/admin/notifications',
      },
      {
        'title': 'Analytics & Reports',
        'subtitle': 'KPIs and reports',
        'icon': 'analytics',
        'route': '/admin/analytics',
      },
      {
        'title': 'Revenue Details',
        'subtitle': 'Financial view',
        'icon': 'revenue',
        'route': '/admin/revenue',
      },
      {
        'title': 'Inventory',
        'subtitle': 'Stock tracking',
        'icon': 'inventory',
        'route': '/admin/inventory',
      },
      {
        'title': 'Clinic Settings',
        'subtitle': 'Services & hours',
        'icon': 'settings',
        'route': '/admin/settings',
      },
      {
        'title': 'User Management',
        'subtitle': 'Access control',
        'icon': 'users',
        'route': '/admin/users',
      },
      {
        'title': 'Calendar',
        'subtitle': 'Clinic schedule',
        'icon': 'calendar',
        'route': '/admin/calendar',
      },
      {
        'title': 'Reports',
        'subtitle': 'Download reports',
        'icon': 'reports',
        'route': '/admin/reports',
      },
      {
        'title': 'Profile',
        'subtitle': 'Admin account',
        'icon': 'profile',
        'route': '/admin/profile',
      },
      {
        'title': 'Quick Actions',
        'subtitle': 'Shortcuts',
        'icon': 'quick',
        'route': '/admin/quick-actions',
      },
      {
        'title': 'More / Menu',
        'subtitle': 'About and support',
        'icon': 'menu',
        'route': '/admin/more',
      },
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareFlow'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/admin/notifications'),
            icon: const Icon(Icons.notifications_none),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(child: Icon(Icons.person_outline)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Good morning,',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            'Admin',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Connected care, organized for today.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '42',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Patients',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '28',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Appointments',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '4',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pending',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Quick Access',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              childAspectRatio: .86,
            ),
            itemCount: modules.length,
            itemBuilder: (context, i) => ModuleCard(
              icon: iconFor(modules[i]['icon']!),
              title: modules[i]['title']!,
              subtitle: modules[i]['subtitle']!,
              onTap: () => Navigator.pushNamed(context, modules[i]['route']!),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
              title: const Text(
                "Today's highlight",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Monitor clinic operations, billing and capacity from one place.',
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: nav,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Appointments',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Patients',
          ),
          const NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            label: 'Doctors',
          ),
          const NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }
}
