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

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});
  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int selected = 0;
  void nav(int i) {
    if (i == 0) {
      setState(() => selected = 0);
      return;
    }
    final routes = [
      '/doctor/dashboard',
      '/doctor/appointments',
      '/doctor/patients',
      '/doctor/notifications',
      '/doctor/profile',
    ];
    Navigator.pushReplacementNamed(context, routes[i]);
  }

  @override
  Widget build(BuildContext context) {
    final modules = <Map<String, String>>[
      {
        'title': "Today's Appointments",
        'subtitle': 'Manage your day',
        'icon': 'appointments',
        'route': '/doctor/appointments',
      },
      {
        'title': 'Patient Queue',
        'subtitle': 'Next patients',
        'icon': 'queue',
        'route': '/doctor/queue',
      },
      {
        'title': 'Patients',
        'subtitle': 'Search records',
        'icon': 'patients',
        'route': '/doctor/patients',
      },
      {
        'title': 'New Consultation',
        'subtitle': 'Record visit',
        'icon': 'consultation',
        'route': '/doctor/consultation',
      },
      {
        'title': 'Medical History',
        'subtitle': 'Past visits',
        'icon': 'history',
        'route': '/doctor/medical-history',
      },
      {
        'title': 'Prescriptions',
        'subtitle': 'Prescription history',
        'icon': 'prescription',
        'route': '/doctor/prescriptions',
      },
      {
        'title': 'Medication Adherence',
        'subtitle': 'Patient adherence',
        'icon': 'adherence',
        'route': '/doctor/medication-adherence',
      },
      {
        'title': 'Follow-ups',
        'subtitle': 'Schedule reviews',
        'icon': 'followup',
        'route': '/doctor/followups',
      },
      {
        'title': 'Analytics',
        'subtitle': 'Clinic insights',
        'icon': 'analytics',
        'route': '/doctor/analytics',
      },
      {
        'title': 'Calendar',
        'subtitle': 'Availability',
        'icon': 'calendar',
        'route': '/doctor/calendar',
      },
      {
        'title': 'Notifications',
        'subtitle': 'Alerts',
        'icon': 'notification',
        'route': '/doctor/notifications',
      },
      {
        'title': 'Profile & Settings',
        'subtitle': 'Account settings',
        'icon': 'settings',
        'route': '/doctor/profile',
      },
      {
        'title': 'Quick Actions',
        'subtitle': 'Common actions',
        'icon': 'quick',
        'route': '/doctor/quick-actions',
      },
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareFlow'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/doctor/notifications'),
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
            'Dr. Priya Sharma',
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
                          '12',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Today's Appointments",
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
                          '3',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Completed',
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
                          '8',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Follow-ups',
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
                'Start the next consultation and keep the queue moving.',
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
            icon: Icon(Icons.notifications_none),
            label: 'Notifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
