import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/appointment_repository.dart';
import '../../../repositories/clinic_repository.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() => _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState extends State<AppointmentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _appointmentRepo = AppointmentRepository();
  final _clinicRepo = ClinicRepository();

  bool _loading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _appointments = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final clinicId = await _clinicRepo.getCurrentUserClinicId() ?? user?.id;

      if (clinicId == null) {
        setState(() {
          _loading = false;
          _appointments = [];
        });
        return;
      }

      final list = await _appointmentRepo.list(clinicId: clinicId);

      if (mounted) {
        setState(() {
          _appointments = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load clinic appointments: $e';
        });
      }
    }
  }

  List<Map<String, dynamic>> _filterByTab(int tabIndex) {
    final todayStr = DateTime.now().toIso8601String().split('T').first;

    final filteredBySearch = _appointments.where((a) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final pName = (a['patient_name'] ?? '').toString().toLowerCase();
      final dName = (a['doctor_name'] ?? '').toString().toLowerCase();
      final reason = (a['reason'] ?? '').toString().toLowerCase();
      return pName.contains(q) || dName.contains(q) || reason.contains(q);
    });

    switch (tabIndex) {
      case 0: // Today
        return filteredBySearch.where((a) {
          final date = a['appointment_date']?.toString();
          final status = (a['status'] ?? '').toString().toLowerCase();
          return (date == todayStr || date == null) && status != 'cancelled';
        }).toList();
      case 1: // Upcoming
        return filteredBySearch.where((a) {
          final status = (a['status'] ?? '').toString().toLowerCase();
          final date = a['appointment_date']?.toString();
          return status != 'cancelled' &&
              status != 'completed' &&
              date != null &&
              date.compareTo(todayStr) > 0;
        }).toList();
      case 2: // Completed
        return filteredBySearch.where((a) {
          final status = (a['status'] ?? '').toString().toLowerCase();
          return status == 'completed';
        }).toList();
      case 3: // Cancelled
        return filteredBySearch.where((a) {
          final status = (a['status'] ?? '').toString().toLowerCase();
          return status == 'cancelled' || status == 'no_show';
        }).toList();
      default:
        return [];
    }
  }

  Future<void> _cancelAppointment(String apptId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorTokens.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _appointmentRepo.cancel(apptId);
      await _loadAppointments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled.'), backgroundColor: ColorTokens.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: ColorTokens.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clinic Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAppointments,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: ColorTokens.textSecondary,
          indicatorColor: AppColors.primaryBlue,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search patients, doctors, or reasons...',
                prefixIcon: const Icon(Icons.search, size: 20, color: ColorTokens.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColorTokens.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColorTokens.border)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: ColorTokens.error),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: ColorTokens.muted)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadAppointments, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: List.generate(4, (index) {
                          final items = _filterByTab(index);
                          if (items.isEmpty) {
                            return _buildEmptyState(index);
                          }
                          return RefreshIndicator(
                            onRefresh: _loadAppointments,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: items.length,
                              itemBuilder: (ctx, i) => _buildAppointmentCard(items[i]),
                            ),
                          );
                        }),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    final titles = [
      'No Appointments Today',
      'No Upcoming Appointments',
      'No Completed Consultations',
      'No Cancelled Bookings',
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 48, color: ColorTokens.muted),
            const SizedBox(height: 14),
            Text(
              titles[tabIndex],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
            ),
            const SizedBox(height: 6),
            const Text(
              'Real clinic appointments will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColorTokens.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final patientName = appt['patient_name'] ?? 'Patient';
    final doctorName = appt['doctor_name'] ?? 'Doctor';
    final date = appt['appointment_date'] ?? '';
    final time = appt['appointment_time'] ?? '';
    final reason = appt['reason'] ?? 'Consultation';
    final token = (appt['token_number'] as num?)?.toInt() ?? 0;
    final status = (appt['status'] ?? 'pending').toString().toLowerCase();
    final apptId = appt['id'].toString();
    final patientId = appt['patient_id']?.toString();

    Color statusColor = ColorTokens.primaryBlue;
    Color statusBg = ColorTokens.lightBlue;
    String statusLabel = 'Confirmed';

    if (status == 'checked_in' || status == 'waiting') {
      statusColor = ColorTokens.warning;
      statusBg = ColorTokens.warning.withValues(alpha: 0.12);
      statusLabel = 'Checked In';
    } else if (status == 'called') {
      statusColor = ColorTokens.warning;
      statusBg = ColorTokens.warning.withValues(alpha: 0.15);
      statusLabel = 'Called';
    } else if (status == 'in_consultation') {
      statusColor = ColorTokens.careGreen;
      statusBg = ColorTokens.lightGreen;
      statusLabel = 'In Consultation';
    } else if (status == 'completed') {
      statusColor = ColorTokens.careGreen;
      statusBg = ColorTokens.lightGreen;
      statusLabel = 'Completed';
    } else if (status == 'cancelled' || status == 'no_show') {
      statusColor = ColorTokens.error;
      statusBg = ColorTokens.error.withValues(alpha: 0.12);
      statusLabel = status == 'no_show' ? 'No-Show' : 'Cancelled';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
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
                  radius: 20,
                  backgroundColor: ColorTokens.lightBlue,
                  child: Text(
                    patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.primaryBlue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                      ),
                      Text('Assigned: $doctorName', style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: ColorTokens.border),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$date • $time', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ColorTokens.darkNavy)),
                if (token > 0)
                  Text('Token #$token', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ColorTokens.primaryBlue)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Reason: $reason', style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (patientId != null)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/clinic/reports/upload',
                        arguments: {'patientId': patientId, 'patientName': patientName},
                      );
                    },
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: const Text('Upload Report'),
                  ),
                if (status != 'completed' && status != 'cancelled') ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _cancelAppointment(apptId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorTokens.error,
                      side: const BorderSide(color: ColorTokens.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
