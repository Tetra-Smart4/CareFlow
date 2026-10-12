import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:careflow/core/theme/color_tokens.dart';
import 'package:careflow/repositories/analytics_repository.dart';
import 'package:careflow/repositories/appointment_repository.dart';
import 'package:careflow/repositories/clinic_repository.dart';
import 'package:careflow/repositories/queue_repository.dart';
import 'package:careflow/services/auth_service.dart';
import 'package:careflow/services/realtime_service.dart';
import 'package:careflow/widgets/common/careflow_brand_title.dart';
import '../appointments/appointment_management_screen.dart';
import '../queue/clinic_queue_screen.dart';
import '../queue/scanner_screen.dart';
import '../queue/check_in_management_screen.dart';
import '../patients/patient_management_screen.dart';
import '../more/more_menu_screen.dart';
import 'package:careflow/widgets/medicine/medicine_search_bar_card.dart';
import 'package:careflow/screens/shared/medicine/medicine_search_screen.dart';

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
          const PatientManagementScreen(),
          const MoreMenuScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor: Colors.white,
        indicatorColor: ColorTokens.lightBlue,
        elevation: 3,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: ColorTokens.primaryBlue),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: ColorTokens.primaryBlue),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt, color: ColorTokens.primaryBlue),
            label: 'Queue',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_search_outlined),
            selectedIcon: Icon(Icons.person_search, color: ColorTokens.primaryBlue),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded, color: ColorTokens.primaryBlue),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class AdminHomeTab extends StatefulWidget {
  final void Function(int) onTabSelected;
  final bool? initialLoadingForTesting;
  final Map<String, int>? initialStatsForTesting;

  const AdminHomeTab({
    super.key,
    required this.onTabSelected,
    this.initialLoadingForTesting,
    this.initialStatsForTesting,
  });

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  final _analyticsRepo = AnalyticsRepository();
  final _clinicRepo = ClinicRepository();
  final _appointmentRepo = AppointmentRepository();
  final _queueRepo = QueueRepository();
  final _realtimeService = RealtimeService();

  late bool _loading;
  String? _error;
  String _clinicName = 'Clinic';
  String? _clinicId;
  late Map<String, int> _stats;
  List<Map<String, dynamic>> _upcomingAppointments = [];
  StreamSubscription? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _loading = widget.initialLoadingForTesting ?? true;
    _stats = widget.initialStatsForTesting ?? {
      'todayAppointments': 0,
      'activeDoctors': 0,
      'waitingPatients': 0,
      'completedConsultations': 0,
      'pendingRequests': 0,
    };
    if (widget.initialLoadingForTesting == false) {
      // In test mode with preloaded stats, skip network call
    } else {
      _loadData();
    }
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return '$weekday, ${now.day} $month ${now.year}';
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

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
          _clinicName = profile['clinic_name'] ?? profile['full_name'] ?? 'CareFlow Clinic';
        }
      }

      if (clinicId != null) {
        final stats = await _analyticsRepo.getClinicStats(clinicId);
        final appts = await _appointmentRepo.list(
          clinicId: clinicId,
          status: 'confirmed',
        );

        if (mounted) {
          setState(() {
            _stats = stats;
            _upcomingAppointments = appts.take(5).toList();
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to refresh dashboard metrics: $e';
        });
      }
    }
  }

  Future<void> _refreshStats() async {
    if (_clinicId == null) return;
    try {
      final stats = await _analyticsRepo.getClinicStats(_clinicId!);
      final appts = await _appointmentRepo.list(
        clinicId: _clinicId!,
        status: 'confirmed',
      );
      if (mounted) {
        setState(() {
          _stats = stats;
          _upcomingAppointments = appts.take(5).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _handleScanQr() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );

    if (scannedCode == null || scannedCode.trim().isEmpty) return;

    if (!mounted) return;

    if (_clinicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clinic session not verified. Please reload.'),
          backgroundColor: ColorTokens.warning,
        ),
      );
      return;
    }

    // Call server-side atomic QR check-in RPC
    try {
      final result = await _queueRepo.checkIn({
        'qr_token': scannedCode.trim(),
        'clinic_id': _clinicId!,
      });

      if (!mounted) return;

      final success = result['success'] == true;
      if (success) {
        final token = result['token_number'] ?? result['token'] ?? 1;
        final patientName = result['patient_name'] ?? 'Patient';

        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: ColorTokens.careGreen, size: 28),
                SizedBox(width: 10),
                Text('Check-In Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient: $patientName',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: ColorTokens.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Assigned Token:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      Text(
                        '#$token',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: ColorTokens.careGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Appointment marked as checked-in and added to live queue.',
                  style: TextStyle(fontSize: 13, color: ColorTokens.muted),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onTabSelected(2); // Jump to Queue tab
                },
                child: const Text('View Queue'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        );

        _refreshStats();
      } else {
        final message = result['message']?.toString() ?? 'Unable to validate QR token.';
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.error_outline_rounded, color: ColorTokens.error, size: 28),
                SizedBox(width: 10),
                Text('Check-In Notice'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckInManagementScreen()),
                  );
                },
                child: const Text('Manual Lookup'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR validation error: $e'),
            backgroundColor: ColorTokens.error,
          ),
        );
      }
    }
  }

  Widget _buildSummaryCard({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ColorTokens.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: ColorTokens.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = ColorTokens.primaryBlue,
    Color bgColor = ColorTokens.lightBlue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ColorTokens.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: ColorTokens.darkNavy,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicMedicineShortcuts() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMedicineShortcutTile(
                icon: Icons.inventory_2_outlined,
                title: 'Clinic Inventory',
                subtitle: 'Manage local stock & reorders',
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                onTap: () => Navigator.pushNamed(context, '/clinic/inventory'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMedicineShortcutTile(
                icon: Icons.local_shipping_outlined,
                title: 'Supplier Info',
                subtitle: 'Verified distributors & licenses',
                color: ColorTokens.primaryBlue,
                bgColor: ColorTokens.lightBlue,
                onTap: _showSupplierInfoDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMedicineShortcutTile(
                icon: Icons.notifications_active_outlined,
                title: 'Regulatory Alerts',
                subtitle: 'CDSCO & safety advisories',
                color: ColorTokens.error,
                bgColor: const Color(0xFFFEF2F2),
                onTap: _showRegulatoryAlertsDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMedicineShortcutTile(
                icon: Icons.menu_book_rounded,
                title: 'Medicine Catalogue',
                subtitle: 'National reference database',
                color: const Color(0xFF0D9488),
                bgColor: const Color(0xFFCCFBF1),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MedicineSearchScreen(role: 'clinic'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicineShortcutTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ColorTokens.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: ColorTokens.darkNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: ColorTokens.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupplierInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.local_shipping_rounded, color: ColorTokens.primaryBlue, size: 24),
            SizedBox(width: 10),
            Text('Supplier Information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Authorized Pharmaceutical Distribution',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: ColorTokens.darkNavy),
            ),
            SizedBox(height: 6),
            Text(
              'Clinic procurement must be sourced exclusively through licensed wholesale distributors registered with State Drug Control Administration (Form 20B/21B).',
              style: TextStyle(fontSize: 12.5, color: ColorTokens.textSecondary, height: 1.35),
            ),
            SizedBox(height: 12),
            Text(
              'Quality Assurance Policy:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ColorTokens.darkNavy),
            ),
            SizedBox(height: 4),
            Text(
              '• Maintain cold-chain verification records for biologicals and vaccines.\n• Retain batch analysis certificates for all antibiotic consignments.\n• Perform physical pack integrity check upon goods receipt.',
              style: TextStyle(fontSize: 12, color: ColorTokens.darkNavy, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRegulatoryAlertsDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: ColorTokens.error, size: 24),
            SizedBox(width: 10),
            Text('Regulatory Alerts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'CDSCO / National Pharmacovigilance Advisories',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: ColorTokens.darkNavy),
            ),
            SizedBox(height: 6),
            Text(
              '• Schedule H1 Audit: Antibacterial and anti-TB medicines require dedicated carbon-copy registers.\n• Fixed-Dose Combination Compliance: Dispense only CDSCO-notified compliant formulations.\n• Adverse Drug Reaction (ADR) Reporting: Suspected adverse events should be reported to PvPI (1800-180-3024).',
              style: TextStyle(fontSize: 12, color: ColorTokens.darkNavy, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Acknowledged'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const CareFlowBrandTitle(),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.pushNamed(context, '/clinic/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
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
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Clinic Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _clinicName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: ColorTokens.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 13, color: ColorTokens.muted),
                          const SizedBox(width: 5),
                          Text(
                            _formatCurrentDate(),
                            style: const TextStyle(fontSize: 12.5, color: ColorTokens.muted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorTokens.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified_rounded, size: 14, color: ColorTokens.careGreen),
                      SizedBox(width: 4),
                      Text(
                        'Verified Clinic',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ColorTokens.careGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Medicine Intelligence Card (Clinic amber/orange)
            const MedicineSearchBarCard(role: MedicineCardRole.clinic),
            const SizedBox(height: 12),
            _buildClinicMedicineShortcuts(),
            const SizedBox(height: 18),

            // PRIMARY HERO ACTION: QR CHECK-IN
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: ColorTokens.primaryBlue.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Rapid QR Check-in',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Scan patient appointment pass for automatic token allocation',
                                  style: TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: _handleScanQr,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: ColorTokens.primaryBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.camera_alt_outlined, size: 19),
                              label: const Text(
                                'Scan Patient QR',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CheckInManagementScreen()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white60),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Manual Entry',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // LIVE DASHBOARD SUMMARY
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Today's Overview",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorTokens.lightWarning,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: ColorTokens.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(fontSize: 12, color: ColorTokens.darkNavy),
                      ),
                    ),
                    TextButton(onPressed: _loadData, child: const Text('Retry')),
                  ],
                ),
              )
            else ...[
              Row(
                children: [
                  _buildSummaryCard(
                    value: '${_stats['todayAppointments'] ?? 0}',
                    label: "Scheduled Today",
                    color: ColorTokens.primaryBlue,
                    icon: Icons.calendar_today_rounded,
                    onTap: () => widget.onTabSelected(1),
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryCard(
                    value: '${_stats['waitingPatients'] ?? 0}',
                    label: "Waiting in Queue",
                    color: ColorTokens.warning,
                    icon: Icons.hourglass_top_rounded,
                    onTap: () => widget.onTabSelected(2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSummaryCard(
                    value: '${_stats['completedConsultations'] ?? 0}',
                    label: "Completed Visits",
                    color: ColorTokens.careGreen,
                    icon: Icons.check_circle_outline_rounded,
                    onTap: () => widget.onTabSelected(1),
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryCard(
                    value: '${_stats['pendingRequests'] ?? 0}',
                    label: "Pending Actions",
                    color: ColorTokens.navy,
                    icon: Icons.pending_actions_rounded,
                    onTap: () => widget.onTabSelected(1),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),

            // QUICK ACTIONS (8 Prioritized Actions)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                ),
                TextButton(
                  onPressed: () => widget.onTabSelected(4), // More tab
                  child: const Text('View All Modules'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.78,
              children: [
                _buildQuickActionItem(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'QR Check-in',
                  color: ColorTokens.primaryBlue,
                  bgColor: ColorTokens.lightBlue,
                  onTap: _handleScanQr,
                ),
                _buildQuickActionItem(
                  icon: Icons.person_search_rounded,
                  label: 'Find / Walk-in',
                  color: ColorTokens.careGreen,
                  bgColor: ColorTokens.lightGreen,
                  onTap: () => Navigator.pushNamed(context, '/clinic/patients/find'),
                ),
                _buildQuickActionItem(
                  icon: Icons.edit_calendar_rounded,
                  label: 'Book Appt',
                  color: ColorTokens.primaryBlue,
                  bgColor: ColorTokens.lightBlue,
                  onTap: () => Navigator.pushNamed(context, '/patient/appointments/book'),
                ),
                _buildQuickActionItem(
                  icon: Icons.upload_file_rounded,
                  label: 'Upload Report',
                  color: ColorTokens.careGreen,
                  bgColor: ColorTokens.lightGreen,
                  onTap: () => Navigator.pushNamed(context, '/clinic/reports/upload'),
                ),
                _buildQuickActionItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Create Bill',
                  color: ColorTokens.navy,
                  bgColor: ColorTokens.lightBlue,
                  onTap: () => Navigator.pushNamed(context, '/clinic/billing/create'),
                ),
                _buildQuickActionItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Inventory',
                  color: ColorTokens.warning,
                  bgColor: ColorTokens.lightWarning,
                  onTap: () => Navigator.pushNamed(context, '/clinic/inventory'),
                ),
                _buildQuickActionItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                  color: ColorTokens.primaryBlue,
                  bgColor: ColorTokens.lightBlue,
                  onTap: () => Navigator.pushNamed(context, '/clinic/analytics'),
                ),
                _buildQuickActionItem(
                  icon: Icons.medical_services_rounded,
                  label: 'Doctors',
                  color: ColorTokens.navy,
                  bgColor: ColorTokens.lightBlue,
                  onTap: () => Navigator.pushNamed(context, '/clinic/doctors'),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // TODAY'S WORK SECTIONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Work & Appointments",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                ),
                TextButton(
                  onPressed: () => widget.onTabSelected(1),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_upcomingAppointments.isEmpty && !_loading)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: ColorTokens.border),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.event_available_rounded, size: 40, color: ColorTokens.careGreen),
                        SizedBox(height: 10),
                        Text(
                          'No More Appointments Scheduled Today',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'All confirmed appointments for today have been checked in or completed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: ColorTokens.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._upcomingAppointments.map((appt) {
                final patientName = appt['patient_name'] ?? 'Patient';
                final doctorName = appt['doctor_name'] ?? 'Doctor';
                final time = appt['appointment_time']?.toString() ?? '';
                final status = appt['status']?.toString() ?? 'confirmed';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: ColorTokens.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: ColorTokens.lightBlue,
                      child: const Icon(Icons.person_outline_rounded, color: ColorTokens.primaryBlue),
                    ),
                    title: Text(
                      patientName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    subtitle: Text(
                      'Dr. $doctorName • $time',
                      style: const TextStyle(fontSize: 12, color: ColorTokens.muted),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'checked_in'
                            ? ColorTokens.lightGreen
                            : ColorTokens.lightBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: status == 'checked_in'
                              ? ColorTokens.careGreen
                              : ColorTokens.primaryBlue,
                        ),
                      ),
                    ),
                    onTap: () => widget.onTabSelected(1),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
