import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../widgets/common/lottie_animation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../repositories/appointment_repository.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _appointmentRepo = AppointmentRepository();

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
      if (user == null) {
        setState(() {
          _loading = false;
          _appointments = [];
        });
        return;
      }

      final list = await _appointmentRepo.list(patientId: user.id);

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
          _errorMessage = 'Failed to load appointments: $e';
        });
      }
    }
  }

  List<Map<String, dynamic>> _filterByTab(int tabIndex) {
    final todayStr = DateTime.now().toIso8601String().split('T').first;

    final filteredBySearch = _appointments.where((a) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final dName = (a['doctor_name'] ?? '').toString().toLowerCase();
      final cName = (a['clinic_name'] ?? '').toString().toLowerCase();
      final reason = (a['reason'] ?? '').toString().toLowerCase();
      return dName.contains(q) || cName.contains(q) || reason.contains(q);
    });

    switch (tabIndex) {
      case 0: // Upcoming (Confirmed / Checked In / In Consultation / Today & future)
        return filteredBySearch.where((a) {
          final s = (a['status'] ?? '').toString().toLowerCase();
          final date = a['appointment_date']?.toString();
          return (s == 'confirmed' || s == 'checked_in' || s == 'called' || s == 'in_consultation') &&
              (date == null || date.compareTo(todayStr) >= 0);
        }).toList();
      case 1: // Pending
        return filteredBySearch.where((a) {
          final s = (a['status'] ?? '').toString().toLowerCase();
          return s == 'pending';
        }).toList();
      case 2: // Completed
        return filteredBySearch.where((a) {
          final s = (a['status'] ?? '').toString().toLowerCase();
          return s == 'completed';
        }).toList();
      case 3: // Cancelled
        return filteredBySearch.where((a) {
          final s = (a['status'] ?? '').toString().toLowerCase();
          return s == 'cancelled' || s == 'no_show';
        }).toList();
      default:
        return [];
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Appointments'),
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
            Tab(text: 'Upcoming'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/patient/doctors/search');
        },
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Book New'),
      ),
      body: Column(
        children: [
          // Search Field
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by doctor or clinic...',
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
                              itemBuilder: (ctx, i) => _buildAppointmentCard(items[i])
                                  .animate()
                                  .fade(delay: (i * 50).ms, duration: 400.ms)
                                  .slideY(begin: 0.1, duration: 400.ms),
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
      'No Upcoming Appointments',
      'No Pending Appointments',
      'No Completed Consultations',
      'No Cancelled Bookings',
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LottieAnimation(
              assetName: 'assets/animations/empty.json',
              width: 150,
              fallback: Icon(Icons.calendar_today_outlined, size: 48, color: ColorTokens.muted),
            ),
            const SizedBox(height: 14),
            Text(
              titles[tabIndex],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your appointments will be listed here with live status updates.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColorTokens.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/patient/doctors/search'),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Find a Doctor'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final doctorName = appt['doctor_name'] ?? 'Doctor';
    final clinicName = appt['clinic_name'] ?? 'CareFlow Clinic';
    final date = appt['appointment_date'] ?? '';
    final time = appt['appointment_time'] ?? '';
    final reason = appt['reason'] ?? 'Consultation';
    final token = (appt['token_number'] as num?)?.toInt() ?? 0;
    final status = (appt['status'] ?? 'pending').toString().toLowerCase();

    final isCheckedIn = status == 'checked_in';
    final isCalled = status == 'called';
    final isInConsult = status == 'in_consultation';

    Color statusColor = ColorTokens.primaryBlue;
    Color statusBg = ColorTokens.lightBlue;
    String statusLabel = 'Confirmed';

    if (isCheckedIn) {
      statusColor = ColorTokens.warning;
      statusBg = ColorTokens.warning.withValues(alpha: 0.12);
      statusLabel = 'Checked In (#$token)';
    } else if (isCalled) {
      statusColor = ColorTokens.warning;
      statusBg = ColorTokens.warning.withValues(alpha: 0.15);
      statusLabel = 'Your Turn (#$token)';
    } else if (isInConsult) {
      statusColor = ColorTokens.careGreen;
      statusBg = ColorTokens.lightGreen;
      statusLabel = 'In Consultation';
    } else if (status == 'completed') {
      statusColor = ColorTokens.careGreen;
      statusBg = ColorTokens.lightGreen;
      statusLabel = 'Completed';
    } else if (status == 'pending') {
      statusColor = ColorTokens.warning;
      statusBg = ColorTokens.warning.withValues(alpha: 0.12);
      statusLabel = 'Pending';
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/patient/appointments/detail',
            arguments: appt,
          ).then((_) => _loadAppointments());
        },
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
                      doctorName.isNotEmpty ? doctorName[0].toUpperCase() : 'D',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.primaryBlue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                        ),
                        Text(clinicName, style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      statusLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: ColorTokens.border),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: ColorTokens.textMuted),
                      const SizedBox(width: 5),
                      Text('$date • $time', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ColorTokens.darkNavy)),
                    ],
                  ),
                  if (token > 0)
                    Text('Token #$token', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ColorTokens.primaryBlue)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Reason: $reason', style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),

              if (isCheckedIn || isCalled) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/patient/queue/live'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorTokens.primaryBlue,
                      side: const BorderSide(color: ColorTokens.primaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                    label: const Text('View Live Queue', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
