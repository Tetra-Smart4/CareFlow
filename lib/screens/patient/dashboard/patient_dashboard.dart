import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';



import '../../../core/theme/app_colors.dart';
import '../../../services/profile_service.dart';



class PatientDashboard extends StatefulWidget {

  const PatientDashboard({super.key});



  @override

  State<PatientDashboard> createState() => _PatientDashboardState();

}



class _PatientDashboardState extends State<PatientDashboard> {

  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();



  bool _loading = true;

  String _patientName = 'Patient';

  String _email = '';



  @override

  void initState() {

    super.initState();

    _loadPatient();

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
        _email = user.email ?? '';

        final profile = await _profileService.getCurrentProfile();

        if (profile != null) {
          final fullName = profile['full_name'];
          final profileEmail = profile['email'];

          if (fullName is String && fullName.trim().isNotEmpty) {
            _patientName = fullName.trim();
          }

          if (profileEmail is String && profileEmail.trim().isNotEmpty) {
            _email = profileEmail.trim();
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

    Navigator.pushNamed(context, route);

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

                      _buildAppointmentCard(),

                      const SizedBox(height: 18),

                      _buildQuickActions(),

                      const SizedBox(height: 18),

                      _buildCareStatusCard(),

                      const SizedBox(height: 18),

                      _buildHealthOverview(),

                      const SizedBox(height: 18),

                      _buildMedicationCard(),

                      const SizedBox(height: 18),

                      _buildEmergencyCard(),

                      const SizedBox(height: 20),

                    ],

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

      bottomNavigationBar: _buildBottomNavigation(),

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

          _buildHeaderButton(

            icon: Icons.notifications_none_rounded,

            onTap: () => _open('/patient/notifications'),

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

    return Container(

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

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        gradient: const LinearGradient(

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [

            Color(0xFFEAF5FF),

            Color(0xFFF0FBF8),

          ],

        ),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(

          color: AppColors.primaryBlue.withValues(alpha: 0.12),

        ),

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

                  color: AppColors.white,

                  borderRadius: BorderRadius.circular(11),

                ),

                child: const Icon(

                  Icons.calendar_month_rounded,

                  color: AppColors.primaryBlue,

                  size: 21,

                ),

              ),

              const SizedBox(width: 11),

              const Expanded(

                child: Text(

                  'Upcoming Appointment',

                  style: TextStyle(

                    color: AppColors.textPrimary,

                    fontSize: 16,

                    fontWeight: FontWeight.w700,

                  ),

                ),

              ),

              _statusPill(

                label: 'No booking',

                color: AppColors.textSecondary,

                background: AppColors.white,

              ),

            ],

          ),

          const SizedBox(height: 18),

          Container(

            width: double.infinity,

            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(

              color: AppColors.white.withValues(alpha: 0.82),

              borderRadius: BorderRadius.circular(15),

            ),

            child: Row(

              children: [

                Container(

                  width: 46,

                  height: 46,

                  decoration: BoxDecoration(

                    color: AppColors.lightBlue,

                    borderRadius: BorderRadius.circular(13),

                  ),

                  child: const Icon(

                    Icons.event_available_rounded,

                    color: AppColors.primaryBlue,

                    size: 23,

                  ),

                ),

                const SizedBox(width: 12),

                const Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        'No upcoming appointment',

                        style: TextStyle(

                          color: AppColors.textPrimary,

                          fontSize: 14,

                          fontWeight: FontWeight.w700,

                        ),

                      ),

                      SizedBox(height: 4),

                      Text(

                        'Book a consultation with a doctor to get started.',

                        style: TextStyle(

                          color: AppColors.textSecondary,

                          fontSize: 12,

                          height: 1.35,

                        ),

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

              icon: const Icon(

                Icons.search_rounded,

                size: 19,

              ),

              label: const Text(

                'Find a Doctor',

                style: TextStyle(

                  fontWeight: FontWeight.w700,

                ),

              ),

            ),

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

        icon: Icons.calendar_add_rounded,

        color: AppColors.primaryBlue,

        background: AppColors.lightBlue,

        route: '/patient/appointments/book',

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

      child: GridView.builder(

        itemCount: actions.length,

        shrinkWrap: true,

        physics: const NeverScrollableScrollPhysics(),

        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(

          crossAxisCount: 4,

          mainAxisSpacing: 14,

          crossAxisSpacing: 8,

          childAspectRatio: 0.82,

        ),

        itemBuilder: (context, index) {

          final action = actions[index];



          return _quickActionItem(action);

        },

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

              Container(

                width: 50,

                height: 50,

                decoration: BoxDecoration(

                  color: action.background,

                  borderRadius: BorderRadius.circular(15),

                ),

                child: Icon(

                  action.icon,

                  color: action.color,

                  size: 24,

                ),

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

              if (trailing != null) trailing,

            ],

          ),

          const SizedBox(height: 15),

          child,

        ],

      ),

    );

  }



  Widget _buildBottomNavigation() {

    return Container(

      decoration: const BoxDecoration(

        color: AppColors.white,

        border: Border(

          top: BorderSide(

            color: AppColors.border,

            width: 0.7,

          ),

        ),

      ),

      child: SafeArea(

        top: false,

        child: Padding(

          padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),

          child: Row(

            children: [

              _bottomItem(

                icon: Icons.home_rounded,

                label: 'Home',

                selected: true,

                onTap: () {},

              ),

              _bottomItem(

                icon: Icons.medical_services_outlined,

                label: 'Doctors',

                selected: false,

                onTap: () => _open('/patient/doctors/search'),

              ),

              _bottomItem(

                icon: Icons.description_outlined,

                label: 'Records',

                selected: false,

                onTap: () => _open('/patient/records'),

              ),

              _bottomItem(

                icon: Icons.notifications_none_rounded,

                label: 'Alerts',

                selected: false,

                onTap: () => _open('/patient/notifications'),

              ),

              _bottomItem(

                icon: Icons.person_outline_rounded,

                label: 'Profile',

                selected: false,

                onTap: () => _open('/patient/profile'),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _bottomItem({

    required IconData icon,

    required String label,

    required bool selected,

    required VoidCallback onTap,

  }) {

    return Expanded(

      child: InkWell(

        borderRadius: BorderRadius.circular(14),

        onTap: onTap,

        child: Padding(

          padding: const EdgeInsets.symmetric(vertical: 5),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Icon(

                icon,

                size: 22,

                color: selected

                    ? AppColors.primaryBlue

                    : AppColors.textSecondary,

              ),

              const SizedBox(height: 3),

              Text(

                label,

                style: TextStyle(

                  color: selected

                      ? AppColors.primaryBlue

                      : AppColors.textSecondary,

                  fontSize: 10,

                  fontWeight:

                      selected ? FontWeight.w700 : FontWeight.w500,

                ),

              ),

            ],

          ),

        ),

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