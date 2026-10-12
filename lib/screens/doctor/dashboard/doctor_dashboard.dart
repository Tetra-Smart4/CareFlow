import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:careflow/core/theme/color_tokens.dart';
import 'package:careflow/repositories/analytics_repository.dart';
import 'package:careflow/services/auth_service.dart';
import 'package:careflow/services/realtime_service.dart';
import 'package:careflow/widgets/common/module_card.dart';
import 'package:careflow/widgets/common/careflow_brand_title.dart';
import 'package:careflow/widgets/medicine/medicine_search_bar_card.dart';
import '../appointments/doctor_appointments_screen.dart';
import '../queue/doctor_queue_screen.dart';
import '../patients/patient_list_screen.dart';
import '../profile/doctor_profile_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
          DoctorHomeTab(onTabSelected: _onTabSelected),
          const DoctorAppointmentsScreen(),
          const DoctorQueueScreen(),
          const PatientListScreen(),
          const DoctorProfileScreen(),
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
          NavigationDestination(icon: Icon(Icons.person_search_outlined), selectedIcon: Icon(Icons.person_search, color: ColorTokens.primaryBlue), label: 'Patients'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: ColorTokens.primaryBlue), label: 'Profile'),
        ],
      ),
    );
  }
}

class DoctorHomeTab extends StatefulWidget {
  final void Function(int) onTabSelected;
  const DoctorHomeTab({super.key, required this.onTabSelected});
  @override
  State<DoctorHomeTab> createState() => _DoctorHomeTabState();
}

class _DoctorHomeTabState extends State<DoctorHomeTab> {
  final _analyticsRepo = AnalyticsRepository();
  final _realtimeService = RealtimeService();

  bool _loading = true;
  String _doctorName = 'Doctor';
  String? _doctorId;
  Map<String, int> _stats = {
    'todayAppointments': 0,
    'waitingPatients': 0,
    'completedConsultations': 0,
    'followUps': 0,
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
      if (user != null) {
        _doctorId = user.id;
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null) {
          _doctorName = profile['full_name'] ?? 'Doctor';
        }

        final stats = await _analyticsRepo.getDoctorStats(user.id);

        // Load current patient in consultation or called
        try {
          final cur = await Supabase.instance.client
              .from('careflow_appointments')
              .select('id, patient_id, appointment_time, reason, token_number, status')
              .eq('doctor_id', user.id)
              .inFilter('status', ['in_consultation', 'called'])
              .order('token_number', ascending: true)
              .limit(1)
              .maybeSingle();

          if (cur != null && cur['patient_id'] != null) {
            final pProf = await Supabase.instance.client
                .from('profiles')
                .select('full_name, age, gender')
                .eq('id', cur['patient_id'])
                .maybeSingle();
            if (pProf != null) {
              cur['patient_name'] = pProf['full_name'];
              cur['patient_age'] = pProf['age'];
              cur['patient_gender'] = pProf['gender'];
            }
            _currentPatient = cur;
          } else {
            _currentPatient = null;
          }
        } catch (_) {
          _currentPatient = null;
        }

        if (mounted) {
          setState(() {
            _stats = stats;
            _loading = false;
          });
        }

        _realtimeSub?.cancel();
        _realtimeSub = _realtimeService.watchAppointments(doctorId: user.id).listen((_) {
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
    if (_doctorId == null) return;
    try {
      final stats = await _analyticsRepo.getDoctorStats(_doctorId!);
      final cur = await Supabase.instance.client
          .from('careflow_appointments')
          .select('id, patient_id, appointment_time, reason, token_number, status')
          .eq('doctor_id', _doctorId!)
          .inFilter('status', ['in_consultation', 'called'])
          .order('token_number', ascending: true)
          .limit(1)
          .maybeSingle();

      if (cur != null && cur['patient_id'] != null) {
        final pProf = await Supabase.instance.client
            .from('profiles')
            .select('full_name, age, gender')
            .eq('id', cur['patient_id'])
            .maybeSingle();
        if (pProf != null) {
          cur['patient_name'] = pProf['full_name'];
          cur['patient_age'] = pProf['age'];
          cur['patient_gender'] = pProf['gender'];
        }
        _currentPatient = cur;
      } else {
        _currentPatient = null;
      }
      if (mounted) setState(() => _stats = stats);
    } catch (_) {}
  }

  int selected = 0;
  void nav(int i) {
    widget.onTabSelected(i);
  }

  Map<String, dynamic>? _currentPatient;

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
        title: const CareFlowBrandTitle(),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/doctor/notifications'),
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
            'Good morning,',
            style: TextStyle(fontSize: 13, color: ColorTokens.muted),
          ),
          const SizedBox(height: 2),
          Text(
            _doctorName,
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
          const MedicineSearchBarCard(role: MedicineCardRole.doctor)
              .animate()
              .fade(duration: 400.ms)
              .slideY(begin: 0.1, duration: 400.ms),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pushNamed(context, '/doctor/appointments'),
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
                  ).animate().fade(duration: 400.ms).slideX(begin: -0.1, duration: 400.ms),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pushNamed(context, '/doctor/queue'),
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
                  ).animate().fade(duration: 400.ms, delay: 100.ms).slideX(begin: 0.1, duration: 400.ms),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pushNamed(context, '/doctor/medical-history'),
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
                              'Completed Visits',
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
                    onTap: () => Navigator.pushNamed(context, '/doctor/followups'),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_stats['followUps'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: ColorTokens.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Follow-ups',
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
          if (_currentPatient != null) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Patient',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ColorTokens.lightGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (_currentPatient!['status'] ?? '').toString().toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ColorTokens.careGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: ColorTokens.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: ColorTokens.lightBlue,
                          child: Text(
                            (_currentPatient!['patient_name'] ?? 'P')[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w900, color: ColorTokens.primaryBlue),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentPatient!['patient_name'] ?? 'Patient',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                              ),
                              Text(
                                'Token #${_currentPatient!['token_number'] ?? 0} • Slot: ${_currentPatient!['appointment_time'] ?? ""}',
                                style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Reason: ${_currentPatient!['reason'] ?? "Consultation"}',
                      style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/doctor/consultation',
                            arguments: {
                              'appointmentId': _currentPatient!['id'],
                              'patientId': _currentPatient!['patient_id'],
                              'patientName': _currentPatient!['patient_name'],
                            },
                          ).then((_) => _refreshStats());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorTokens.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Open Consultation', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Quick Access',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = 3;
              final crossAxisSpacing = 9.0;
              final mainAxisSpacing = 9.0;
              final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
              final itemHeight = 118.0;
              final childAspectRatio = itemWidth / itemHeight;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: modules.length,
                itemBuilder: (context, i) => ModuleCard(
                  icon: iconFor(modules[i]['icon']!),
                  title: modules[i]['title']!,
                  subtitle: modules[i]['subtitle']!,
                  onTap: () => Navigator.pushNamed(context, modules[i]['route']!),
                ).animate().fade(delay: (i * 30).ms, duration: 300.ms).scaleXY(begin: 0.9, duration: 300.ms),
              );
            }
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
      ),
    );
  }
}
