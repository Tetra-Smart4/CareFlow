import 'dart:async';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/appointment_repository.dart';
import '../../../repositories/notification_repository.dart';
import '../../../repositories/queue_repository.dart';
import '../../../services/profile_service.dart';
import '../../../services/realtime_service.dart';
import '../appointments/appointments_screen.dart';
import '../queue/live_queue_screen.dart';
import '../medical_records/medical_records_screen.dart';
import '../profile/patient_profile_screen.dart';
import '../../../widgets/common/careflow_feature_icon.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
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
          PatientHomeTab(onTabSelected: _onTabSelected),
          const AppointmentsScreen(),
          const LiveQueueScreen(),
          const MedicalRecordsScreen(),
          const PatientProfileScreen(),
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
          NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite, color: ColorTokens.primaryBlue), label: 'Health'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: ColorTokens.primaryBlue), label: 'Profile'),
        ],
      ),
    );
  }

}

class PatientHomeTab extends StatefulWidget {
  final void Function(int) onTabSelected;
  const PatientHomeTab({super.key, required this.onTabSelected});

  @override
  State<PatientHomeTab> createState() => _PatientHomeTabState();
}



class _PatientHomeTabState extends State<PatientHomeTab> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();
  final QueueRepository _queueRepo = QueueRepository();
  final NotificationRepository _notifRepo = NotificationRepository();
  final RealtimeService _realtimeService = RealtimeService();

  bool _loading = true;
  String _patientName = 'Patient';
  Map<String, dynamic>? _upcomingAppointment;
  int _unreadNotifications = 0;
  int _tokenNumber = 0;
  int _nowServing = 0;

  StreamSubscription? _apptSub;
  StreamSubscription? _queueSub;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  @override
  void dispose() {
    _apptSub?.cancel();
    _queueSub?.cancel();
    super.dispose();
  }

  Future<void> _loadPatient() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final user = _supabase.auth.currentUser;

      if (user != null) {
        final profile = await _profileService.getCurrentProfile();

        if (profile != null) {
          final fullName = profile['full_name'];

          if (fullName is String && fullName.trim().isNotEmpty) {
            _patientName = fullName.trim();
          }
        } else {
          final metadata = user.userMetadata ?? <String, dynamic>{};
          final name = metadata['full_name'] ??
              metadata['name'] ??
              metadata['display_name'];

          if (name is String && name.trim().isNotEmpty) {
            _patientName = name.trim();
          }
        }

        // 1. Load unread notifications count
        try {
          _unreadNotifications = await _notifRepo.getUnreadCount(userId: user.id);
        } catch (_) {}

        // 2. Load real upcoming appointments from PostgreSQL
        try {
          final appts = await _appointmentRepo.list(patientId: user.id);
          final active = appts.where((a) {
            final s = (a['status'] ?? '').toString().toLowerCase();
            return s == 'confirmed' || s == 'pending' || s == 'checked_in' || s == 'in_consultation';
          }).toList();

          if (active.isNotEmpty) {
            _upcomingAppointment = active.first;
            final clinicId = _upcomingAppointment!['clinic_id']?.toString();
            _tokenNumber = (_upcomingAppointment!['token_number'] as num?)?.toInt() ?? 0;

            if (clinicId != null) {
              final counter = await _queueRepo.getCounter(clinicId);
              _nowServing = (counter['now_serving'] as num?)?.toInt() ?? 0;

              _queueSub?.cancel();
              _queueSub = _realtimeService.watchLiveQueue(clinicId: clinicId).listen((evt) {
                final newNow = (evt['now_serving'] as num?)?.toInt();
                if (newNow != null && mounted) {
                  setState(() => _nowServing = newNow);
                }
              });
            }
          } else {
            _upcomingAppointment = null;
          }
        } catch (_) {}

        _apptSub?.cancel();
        _apptSub = _realtimeService.watchAppointments(patientId: user.id).listen((_) {
          _loadPatient();
        });
      }
    } catch (_) {
      // Keep the dashboard usable if the profile cannot be loaded.
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }


  String get _firstName {

    final parts = _patientName.trim().split(RegExp(r'\s+'));



    if (parts.isEmpty || parts.first.isEmpty) {

      return 'Patient';

    }



    return parts.first;

  }



  String get _initial {

    if (_patientName.trim().isEmpty) {

      return 'P';

    }



    return _patientName.trim()[0].toUpperCase();

  }



  void _open(String route) {
    if (route == '/patient/appointments') {
      widget.onTabSelected(1);
    } else if (route == '/patient/queue/live') {
      widget.onTabSelected(2);
    } else if (route == '/patient/records') {
      widget.onTabSelected(3);
    } else if (route == '/patient/profile') {
      widget.onTabSelected(4);
    } else {
      Navigator.pushNamed(context, route);
    }
  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.background,

      body: SafeArea(

        child: RefreshIndicator(

          color: AppColors.primaryBlue,

          onRefresh: _loadPatient,

          child: CustomScrollView(

            physics: const AlwaysScrollableScrollPhysics(),

            slivers: [

              SliverToBoxAdapter(

                child: _buildHeader(),

              ),

              SliverPadding(

                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),

                sliver: SliverList(

                  delegate: SliverChildListDelegate(

                    [
                      _buildAppointmentCard().animate().fade(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms),
                      const SizedBox(height: 18),
                      _buildQuickActions().animate().fade(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, duration: 400.ms),
                      const SizedBox(height: 18),
                      _buildCareStatusCard().animate().fade(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, duration: 400.ms),
                      const SizedBox(height: 18),
                      _buildHealthOverview().animate().fade(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1, duration: 400.ms),
                      const SizedBox(height: 18),
                      _buildMedicationCard().animate().fade(duration: 400.ms, delay: 400.ms).slideY(begin: 0.1, duration: 400.ms),
                      const SizedBox(height: 18),
                      _buildEmergencyCard().animate().fade(duration: 400.ms, delay: 500.ms).slideY(begin: 0.1, duration: 400.ms),
                      const SizedBox(height: 20),
                    ],

                  ),

                ),

              ),

            ],

          ),

        ),

      ),
    );
  }

  Widget _buildHeader() {

    return Container(

      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),

      decoration: const BoxDecoration(

        color: AppColors.white,

        border: Border(

          bottom: BorderSide(

            color: AppColors.border,

            width: 0.7,

          ),

        ),

      ),

      child: Row(

        children: [

          _buildProfileAvatar(),

          const SizedBox(width: 12),

          Expanded(

            child: _loading

                ? Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      _shimmerLine(width: 110, height: 12),

                      const SizedBox(height: 7),

                      _shimmerLine(width: 160, height: 18),

                    ],

                  )

                : Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        'Welcome back',

                        style: TextStyle(

                          color: AppColors.textSecondary,

                          fontSize: 12,

                          fontWeight: FontWeight.w500,

                        ),

                      ),

                      const SizedBox(height: 2),

                      Text(

                        _firstName,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(

                          color: AppColors.textPrimary,

                          fontSize: 20,

                          fontWeight: FontWeight.w700,

                        ),

                      ),

                    ],

                  ),

          ),

          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildHeaderButton(
                icon: Icons.notifications_none_rounded,
                onTap: () => _open('/patient/notifications'),
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: ColorTokens.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Center(
                      child: Text(
                        _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 8),

          _buildHeaderButton(

            icon: Icons.person_outline_rounded,

            onTap: () => _open('/patient/profile'),

          ),

        ],

      ),

    );

  }



  Widget _buildProfileAvatar() {

    return GestureDetector(
      onTap: () => _open('/patient/profile'),
      child: Container(

        width: 48,

        height: 48,

        decoration: BoxDecoration(

          gradient: AppColors.primaryGradient,

          shape: BoxShape.circle,

          boxShadow: [

            BoxShadow(

              color: AppColors.primaryBlue.withValues(alpha: 0.18),

              blurRadius: 12,

              offset: const Offset(0, 5),

            ),

          ],

        ),

        alignment: Alignment.center,

        child: Text(

          _initial,

          style: const TextStyle(

            color: AppColors.white,

            fontSize: 18,

            fontWeight: FontWeight.w700,

          ),

        ),

      ),
    );

  }



  Widget _buildHeaderButton({

    required IconData icon,

    required VoidCallback onTap,

  }) {

    return Material(

      color: AppColors.background,

      borderRadius: BorderRadius.circular(12),

      child: InkWell(

        borderRadius: BorderRadius.circular(12),

        onTap: onTap,

        child: SizedBox(

          width: 42,

          height: 42,

          child: Icon(

            icon,

            color: AppColors.textPrimary,

            size: 22,

          ),

        ),

      ),

    );

  }



  Widget _buildAppointmentCard() {
    if (_upcomingAppointment == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF5FF), Color(0xFFF0FBF8)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ColorTokens.primaryBlue.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: ColorTokens.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: ColorTokens.primaryBlue,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Upcoming Appointment',
                    style: TextStyle(
                      color: ColorTokens.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _statusPill(
                  label: 'No booking',
                  color: ColorTokens.muted,
                  background: ColorTokens.white,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorTokens.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                children: [
                  Icon(Icons.event_available_rounded, color: ColorTokens.primaryBlue, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No upcoming appointments',
                          style: TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.navy),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Book a consultation with a doctor to get started.',
                          style: TextStyle(fontSize: 12, color: ColorTokens.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _open('/patient/doctors/search'),
                icon: const Icon(Icons.search_rounded, size: 19),
                label: const Text('Find a Doctor', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }

    final docName = _upcomingAppointment!['doctor_name'] ?? 'Doctor';
    final spec = _upcomingAppointment!['doctor_specialization'] ?? 'Specialist';
    final clinic = _upcomingAppointment!['clinic_name'] ?? 'CareFlow Clinic';
    final date = _upcomingAppointment!['appointment_date'] ?? 'Today';
    final time = _upcomingAppointment!['appointment_time'] ?? '';
    final status = (_upcomingAppointment!['status'] ?? 'confirmed').toString();
    final isCheckedIn = status == 'checked_in' || status == 'in_consultation';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF5FF), Color(0xFFF0FBF8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorTokens.primaryBlue.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ColorTokens.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: ColorTokens.primaryBlue,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Upcoming Appointment',
                  style: TextStyle(
                    color: ColorTokens.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusPill(
                label: status.toUpperCase(),
                color: isCheckedIn ? ColorTokens.careGreen : ColorTokens.primaryBlue,
                background: ColorTokens.white,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorTokens.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: ColorTokens.lightBlue,
                      child: const Icon(Icons.person, color: ColorTokens.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            docName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ColorTokens.navy,
                            ),
                          ),
                          Text(
                            '$spec • $clinic',
                            style: const TextStyle(fontSize: 12, color: ColorTokens.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: ColorTokens.primaryBlue),
                    const SizedBox(width: 6),
                    Text(
                      '$date ${time.isNotEmpty ? "at $time" : ""}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (isCheckedIn && _tokenNumber > 0) ...[
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Token: #$_tokenNumber',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: ColorTokens.primaryBlue,
                        ),
                      ),
                      Text(
                        _tokenNumber == _nowServing
                            ? "It's your turn!"
                            : 'Now Serving: #$_nowServing',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _tokenNumber == _nowServing
                              ? ColorTokens.careGreen
                              : ColorTokens.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCheckedIn
                      ? () => Navigator.pushNamed(
                            context,
                            '/patient/queue/live',
                            arguments: {
                              'appointmentId': _upcomingAppointment!['id'],
                              'clinicId': _upcomingAppointment!['clinic_id'],
                            },
                          )
                      : () => Navigator.pushNamed(
                            context,
                            '/patient/appointments/detail',
                            arguments: {'appointment': _upcomingAppointment},
                          ),
                  icon: Icon(isCheckedIn ? Icons.confirmation_number_outlined : Icons.calendar_month, size: 18),
                  label: Text(isCheckedIn ? 'View Live Queue' : 'View Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildQuickActions() {

    final actions = <_QuickAction>[

      _QuickAction(

        title: 'Book',

        subtitle: 'Appointment',

        icon: Icons.edit_calendar_rounded,

        color: AppColors.primaryBlue,

        background: AppColors.lightBlue,

        route: '/patient/doctors/search',

      ),

      _QuickAction(

        title: 'Doctors',

        subtitle: 'Find a doctor',

        icon: Icons.medical_services_outlined,

        color: AppColors.primaryGreen,

        background: AppColors.lightGreen,

        route: '/patient/doctors/search',

      ),

      _QuickAction(

        title: 'Records',

        subtitle: 'Medical history',

        icon: Icons.description_outlined,

        color: const Color(0xFF5B5BD6),

        background: const Color(0xFFF0F0FF),

        route: '/patient/records',

      ),

      _QuickAction(

        title: 'Medicines',

        subtitle: 'Your medicines',

        icon: Icons.medication_outlined,

        color: const Color(0xFFE05A75),

        background: const Color(0xFFFFEFF2),

        route: '/patient/medications/reminder',

      ),

      _QuickAction(

        title: 'Health',

        subtitle: 'Health analytics',

        icon: Icons.monitor_heart_outlined,

        color: const Color(0xFF1E9E78),

        background: const Color(0xFFEAF9F4),

        route: '/patient/health/analytics',

      ),

      _QuickAction(

        title: 'Bills',

        subtitle: 'Payments',

        icon: Icons.receipt_long_outlined,

        color: const Color(0xFF6D55C7),

        background: const Color(0xFFF1EEFF),

        route: '/patient/bills',

      ),

      _QuickAction(

        title: 'Follow-ups',

        subtitle: 'Next visit',

        icon: Icons.event_repeat_outlined,

        color: const Color(0xFFE08A26),

        background: const Color(0xFFFFF5E7),

        route: '/patient/followups',

      ),

      _QuickAction(

        title: 'Emergency',

        subtitle: 'Contact help',

        icon: Icons.emergency_outlined,

        color: AppColors.error,

        background: const Color(0xFFFFEEEE),

        route: '/patient/emergency',

      ),

    ];



    return _sectionCard(

      title: 'Quick Actions',

      icon: Icons.grid_view_rounded,

      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = 4;
          final crossAxisSpacing = 8.0;
          final mainAxisSpacing = 14.0;
          final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
          final itemHeight = 94.0; // Ensures enough height for icon, title and subtitle
          final childAspectRatio = itemWidth / itemHeight;

          return GridView.builder(
            itemCount: actions.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _quickActionItem(action);
            },
          );
        }
      ),

    );

  }



  Widget _quickActionItem(_QuickAction action) {

    return Material(

      color: Colors.transparent,

      child: InkWell(

        borderRadius: BorderRadius.circular(14),

        onTap: () => _open(action.route),

        child: Padding(

          padding: const EdgeInsets.symmetric(horizontal: 2),

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              CareFlowFeatureIcon(
                icon: action.icon,
                iconColor: action.color,
                backgroundColor: action.background,
                containerSize: 52,
                iconSize: 26,
                borderRadius: 16,
                hasShadow: true,
              ),

              const SizedBox(height: 7),

              Text(

                action.title,

                textAlign: TextAlign.center,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(

                  color: AppColors.textPrimary,

                  fontSize: 11,

                  fontWeight: FontWeight.w700,

                ),

              ),

              const SizedBox(height: 2),

              Text(

                action.subtitle,

                textAlign: TextAlign.center,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(

                  color: AppColors.textSecondary,

                  fontSize: 9.5,

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildCareStatusCard() {

    return _sectionCard(

      title: 'Your Care Status',

      icon: Icons.favorite_outline_rounded,

      child: Column(

        children: [

          Row(

            children: [

              _careStep(

                icon: Icons.person_outline_rounded,

                title: 'Profile',

                active: true,

              ),

              _careLine(),

              _careStep(

                icon: Icons.calendar_today_outlined,

                title: 'Booked',

                active: false,

              ),

              _careLine(),

              _careStep(

                icon: Icons.login_rounded,

                title: 'Check-in',

                active: false,

              ),

              _careLine(),

              _careStep(

                icon: Icons.medical_services_outlined,

                title: 'Consult',

                active: false,

              ),

            ],

          ),

          const SizedBox(height: 16),

          Container(

            width: double.infinity,

            padding: const EdgeInsets.all(13),

            decoration: BoxDecoration(

              color: AppColors.background,

              borderRadius: BorderRadius.circular(13),

            ),

            child: const Row(

              children: [

                Icon(

                  Icons.info_outline_rounded,

                  color: AppColors.primaryBlue,

                  size: 19,

                ),

                SizedBox(width: 9),

                Expanded(

                  child: Text(

                    'Your care journey will update automatically as you complete each step.',

                    style: TextStyle(

                      color: AppColors.textSecondary,

                      fontSize: 11.5,

                      height: 1.35,

                    ),

                  ),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }



  Widget _careStep({

    required IconData icon,

    required String title,

    required bool active,

  }) {

    return Expanded(

      child: Column(

        children: [

          Container(

            width: 40,

            height: 40,

            decoration: BoxDecoration(

              color: active ? AppColors.lightGreen : AppColors.background,

              shape: BoxShape.circle,

              border: Border.all(

                color: active

                    ? AppColors.primaryGreen

                    : AppColors.border,

              ),

            ),

            child: Icon(

              icon,

              color: active

                  ? AppColors.primaryGreen

                  : AppColors.textSecondary,

              size: 19,

            ),

          ),

          const SizedBox(height: 6),

          Text(

            title,

            textAlign: TextAlign.center,

            style: TextStyle(

              color: active

                  ? AppColors.textPrimary

                  : AppColors.textSecondary,

              fontSize: 10,

              fontWeight: active ? FontWeight.w700 : FontWeight.w500,

            ),

          ),

        ],

      ),

    );

  }



  Widget _careLine() {

    return Container(

      width: 12,

      height: 1.5,

      margin: const EdgeInsets.only(bottom: 22),

      color: AppColors.border,

    );

  }



  Widget _buildHealthOverview() {

    return _sectionCard(

      title: 'Health Overview',

      icon: Icons.monitor_heart_outlined,

      trailing: TextButton(

        onPressed: () => _open('/patient/health/analytics'),

        child: const Text(

          'View all',

          style: TextStyle(

            color: AppColors.primaryBlue,

            fontSize: 12,

            fontWeight: FontWeight.w700,

          ),

        ),

      ),

      child: Row(

        children: [

          _healthMetric(

            icon: Icons.favorite_outline_rounded,

            label: 'Heart Rate',

            value: '--',

            unit: 'bpm',

            color: AppColors.error,

            background: const Color(0xFFFFEFF1),

          ),

          const SizedBox(width: 8),

          _healthMetric(

            icon: Icons.water_drop_outlined,

            label: 'Blood Pressure',

            value: '--/--',

            unit: 'mmHg',

            color: AppColors.primaryBlue,

            background: AppColors.lightBlue,

          ),

          const SizedBox(width: 8),

          _healthMetric(

            icon: Icons.air_rounded,

            label: 'SpO₂',

            value: '--',

            unit: '%',

            color: AppColors.primaryGreen,

            background: AppColors.lightGreen,

          ),

        ],

      ),

    );

  }



  Widget _healthMetric({

    required IconData icon,

    required String label,

    required String value,

    required String unit,

    required Color color,

    required Color background,

  }) {

    return Expanded(

      child: Container(

        padding: const EdgeInsets.symmetric(

          horizontal: 8,

          vertical: 12,

        ),

        decoration: BoxDecoration(

          color: background,

          borderRadius: BorderRadius.circular(14),

        ),

        child: Column(

          children: [

            Icon(

              icon,

              color: color,

              size: 20,

            ),

            const SizedBox(height: 7),

            Text(

              value,

              style: const TextStyle(

                color: AppColors.textPrimary,

                fontSize: 15,

                fontWeight: FontWeight.w800,

              ),

            ),

            const SizedBox(height: 2),

            Text(

              unit,

              style: const TextStyle(

                color: AppColors.textSecondary,

                fontSize: 9,

              ),

            ),

            const SizedBox(height: 6),

            Text(

              label,

              textAlign: TextAlign.center,

              maxLines: 2,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(

                color: AppColors.textSecondary,

                fontSize: 9.5,

                fontWeight: FontWeight.w500,

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildMedicationCard() {

    return _sectionCard(

      title: 'Medication',

      icon: Icons.medication_outlined,

      trailing: TextButton(

        onPressed: () => _open('/patient/medications/history'),

        child: const Text(

          'History',

          style: TextStyle(

            color: AppColors.primaryBlue,

            fontSize: 12,

            fontWeight: FontWeight.w700,

          ),

        ),

      ),

      child: Container(

        width: double.infinity,

        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(

          color: AppColors.background,

          borderRadius: BorderRadius.circular(14),

        ),

        child: Row(

          children: [

            Container(

              width: 44,

              height: 44,

              decoration: BoxDecoration(

                color: AppColors.white,

                borderRadius: BorderRadius.circular(12),

              ),

              child: const Icon(

                Icons.medication_outlined,

                color: AppColors.primaryGreen,

                size: 23,

              ),

            ),

            const SizedBox(width: 12),

            const Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    'No medication schedule',

                    style: TextStyle(

                      color: AppColors.textPrimary,

                      fontSize: 13,

                      fontWeight: FontWeight.w700,

                    ),

                  ),

                  SizedBox(height: 4),

                  Text(

                    'Prescribed medicines and reminders will appear here.',

                    style: TextStyle(

                      color: AppColors.textSecondary,

                      fontSize: 11,

                      height: 1.3,

                    ),

                  ),

                ],

              ),

            ),

            Icon(

              Icons.chevron_right_rounded,

              color: AppColors.textSecondary,

              size: 21,

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildEmergencyCard() {

    return Container(

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(

        color: const Color(0xFFFFF3F4),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(

          color: AppColors.error.withValues(alpha: 0.12),

        ),

      ),

      child: Row(

        children: [

          Container(

            width: 44,

            height: 44,

            decoration: BoxDecoration(

              color: AppColors.white,

              borderRadius: BorderRadius.circular(13),

            ),

            child: const Icon(

              Icons.emergency_outlined,

              color: AppColors.error,

              size: 24,

            ),

          ),

          const SizedBox(width: 12),

          const Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  'Emergency Contact',

                  style: TextStyle(

                    color: AppColors.textPrimary,

                    fontSize: 14,

                    fontWeight: FontWeight.w700,

                  ),

                ),

                SizedBox(height: 4),

                Text(

                  'Keep your emergency contact information updated.',

                  style: TextStyle(

                    color: AppColors.textSecondary,

                    fontSize: 11,

                    height: 1.3,

                  ),

                ),

              ],

            ),

          ),

          IconButton(

            onPressed: () => _open('/patient/emergency'),

            icon: const Icon(

              Icons.arrow_forward_ios_rounded,

              color: AppColors.error,

              size: 17,

            ),

          ),

        ],

      ),

    );

  }



  Widget _sectionCard({

    required String title,

    required IconData icon,

    required Widget child,

    Widget? trailing,

  }) {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: AppColors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(

          color: AppColors.border,

        ),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.025),

            blurRadius: 12,

            offset: const Offset(0, 4),

          ),

        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Container(

                width: 34,

                height: 34,

                decoration: BoxDecoration(

                  color: AppColors.lightBlue,

                  borderRadius: BorderRadius.circular(10),

                ),

                child: Icon(

                  icon,

                  color: AppColors.primaryBlue,

                  size: 18,

                ),

              ),

              const SizedBox(width: 10),

              Expanded(

                child: Text(

                  title,

                  style: const TextStyle(

                    color: AppColors.textPrimary,

                    fontSize: 15,

                    fontWeight: FontWeight.w700,

                  ),

                ),

              ),
              ?trailing,

            ],

          ),

          const SizedBox(height: 15),

          child,

        ],

      ),

    );

  }






  Widget _statusPill({

    required String label,

    required Color color,

    required Color background,

  }) {

    return Container(

      padding: const EdgeInsets.symmetric(

        horizontal: 9,

        vertical: 5,

      ),

      decoration: BoxDecoration(

        color: background,

        borderRadius: BorderRadius.circular(20),

      ),

      child: Text(

        label,

        style: TextStyle(

          color: color,

          fontSize: 9.5,

          fontWeight: FontWeight.w700,

        ),

      ),

    );

  }



  Widget _shimmerLine({

    required double width,

    required double height,

  }) {

    return Container(

      width: width,

      height: height,

      decoration: BoxDecoration(

        color: AppColors.border,

        borderRadius: BorderRadius.circular(8),

      ),

    );

  }

}



class _QuickAction {

  const _QuickAction({

    required this.title,

    required this.subtitle,

    required this.icon,

    required this.color,

    required this.background,

    required this.route,

  });



  final String title;

  final String subtitle;

  final IconData icon;

  final Color color;

  final Color background;

  final String route;

}