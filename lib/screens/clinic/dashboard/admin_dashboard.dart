import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:careflow/core/theme/color_tokens.dart';
import 'package:careflow/repositories/analytics_repository.dart';
import 'package:careflow/repositories/clinic_repository.dart';
import 'package:careflow/services/auth_service.dart';
import 'package:careflow/services/realtime_service.dart';
import 'package:careflow/widgets/common/module_card.dart';
import 'package:careflow/widgets/common/careflow_brand_title.dart';
import '../appointments/appointment_management_screen.dart';
import '../queue/clinic_queue_screen.dart';
import '../doctors/doctor_management_screen.dart';
import '../profile/admin_profile_screen.dart';

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
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AdminHomeTab(onTabSelected: _onTabSelected),
          const AppointmentManagementScreen(),
          const ClinicQueueScreen(),
          const DoctorManagementScreen(),
          const AdminProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor: Colors.white,
        indicatorColor: ColorTokens.lightBlue,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: ColorTokens.primaryBlue), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month, color: ColorTokens.primaryBlue), label: 'Appointments'),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt, color: ColorTokens.primaryBlue), label: 'Queue'),
          NavigationDestination(icon: Icon(Icons.medical_services_outlined), selectedIcon: Icon(Icons.medical_services, color: ColorTokens.primaryBlue), label: 'Doctors'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: ColorTokens.primaryBlue), label: 'Profile'),
        ],
      ),
    );
  }
}

class AdminHomeTab extends StatefulWidget {
  final void Function(int) onTabSelected;
  const AdminHomeTab({super.key, required this.onTabSelected});
  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  final _analyticsRepo = AnalyticsRepository();
  final _clinicRepo = ClinicRepository();
  final _realtimeService = RealtimeService();

  bool _loading = true;
  String _clinicName = 'Clinic';
  String? _clinicId;
  Map<String, int> _stats = {
    'todayAppointments': 0,
    'activeDoctors': 0,
    'waitingPatients': 0,
    'completedConsultations': 0,
    'pendingRequests': 0,
  };
  StreamSubscription? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final clinicId = await _clinicRepo.getCurrentUserClinicId() ?? user?.id;
      _clinicId = clinicId;

      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('clinic_name, full_name')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null) {
          _clinicName = profile['clinic_name'] ?? profile['full_name'] ?? 'Clinic';
        }
      }

      if (clinicId != null) {
        final stats = await _analyticsRepo.getClinicStats(clinicId);
        if (mounted) {
          setState(() {
            _stats = stats;
            _loading = false;
          });
        }

        _realtimeSub?.cancel();
        _realtimeSub = _realtimeService.watchAppointments(clinicId: clinicId).listen((_) {
          _refreshStats();
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshStats() async {
    if (_clinicId == null) return;
    try {
      final stats = await _analyticsRepo.getClinicStats(_clinicId!);
      if (mounted) setState(() => _stats = stats);
    } catch (_) {}
  }

  int selected = 0;
  void nav(int i) {
    widget.onTabSelected(i);
  }

  @override
  Widget build(BuildContext context) {
    final modules = <Map<String, String>>[
      {
        'title': 'Appointments',
        'subtitle': 'Manage bookings',
        'icon': 'appointments',
        'route': '/clinic/appointments',
      },
      {
        'title': 'Patients',
        'subtitle': 'Patient records',
        'icon': 'patients',
        'route': '/clinic/patients',
      },
      {
        'title': 'Doctors',
        'subtitle': 'Doctor management',
        'icon': 'doctors',
        'route': '/clinic/doctors',
      },
      {
        'title': 'Clinic Queue',
        'subtitle': 'Live queue',
        'icon': 'queue',
        'route': '/clinic/queue',
      },
      {
        'title': 'Check-in',
        'subtitle': 'Front desk',
        'icon': 'checkin',
        'route': '/clinic/checkin',
      },
      {
        'title': 'Billing & Payments',
        'subtitle': 'Invoices',
        'icon': 'bill',
        'route': '/clinic/billing',
      },
      {
        'title': 'Medical Records',
        'subtitle': 'Patient records',
        'icon': 'records',
        'route': '/clinic/records',
      },
      {
        'title': 'Prescriptions',
        'subtitle': 'Medication records',
        'icon': 'prescription',
        'route': '/clinic/prescriptions',
      },
      {
        'title': 'Follow-ups',
        'subtitle': 'Pending reviews',
        'icon': 'followup',
        'route': '/clinic/followups',
      },
      {
        'title': 'Notifications',
        'subtitle': 'Clinic alerts',
        'icon': 'notification',
        'route': '/clinic/notifications',
      },
      {
        'title': 'Analytics & Reports',
        'subtitle': 'KPIs and reports',
        'icon': 'analytics',
        'route': '/clinic/analytics',
      },
      {
        'title': 'Revenue Details',
        'subtitle': 'Financial view',
        'icon': 'revenue',
        'route': '/clinic/revenue',
      },
      {
        'title': 'Inventory',
        'subtitle': 'Stock tracking',
        'icon': 'inventory',
        'route': '/clinic/inventory',
      },
      {
        'title': 'Clinic Settings',
        'subtitle': 'Services & hours',
        'icon': 'settings',
        'route': '/clinic/settings',
      },
      {
        'title': 'User Management',
        'subtitle': 'Access control',
        'icon': 'users',
        'route': '/clinic/users',
      },
      {
        'title': 'Calendar',
        'subtitle': 'Clinic schedule',
        'icon': 'calendar',
        'route': '/clinic/calendar',
      },
      {
        'title': 'Reports',
        'subtitle': 'Download reports',
        'icon': 'reports',
        'route': '/clinic/reports',
      },
      {
        'title': 'Profile',
        'subtitle': 'Admin account',
        'icon': 'profile',
        'route': '/clinic/profile',
      },
      {
        'title': 'Quick Actions',
        'subtitle': 'Shortcuts',
        'icon': 'quick',
        'route': '/clinic/quick-actions',
      },
      {
        'title': 'More / Menu',
        'subtitle': 'About and support',
        'icon': 'menu',
        'route': '/clinic/more',
      },
    ];
    return Scaffold(
      appBar: AppBar(
        title: const CareFlowBrandTitle(),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/clinic/notifications'),
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/auth/login', (route) => false);
              }
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(child: Icon(Icons.person_outline)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'Welcome back,',
            style: TextStyle(fontSize: 13, color: ColorTokens.muted),
          ),
          const SizedBox(height: 2),
          Text(
            _clinicName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: ColorTokens.navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Connected care, organized for today.',
            style: TextStyle(color: ColorTokens.muted),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            // Today's Operations KPI Cards
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pushNamed(context, '/clinic/appointments'),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_stats['todayAppointments'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: ColorTokens.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Today's Appts",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ColorTokens.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pushNamed(context, '/clinic/doctors'),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_stats['activeDoctors'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: ColorTokens.careGreen,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Active Doctors',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ColorTokens.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pushNamed(context, '/clinic/queue'),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_stats['waitingPatients'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: ColorTokens.warning,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Waiting Queue',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ColorTokens.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pushNamed(context, '/clinic/records'),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_stats['completedConsultations'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: ColorTokens.careGreen,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Completed Consultations',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ColorTokens.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pushNamed(context, '/clinic/appointments'),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_stats['pendingRequests'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: ColorTokens.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Pending Requests',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ColorTokens.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      ),
    );
  }
}
