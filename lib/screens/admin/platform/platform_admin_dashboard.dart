import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../widgets/common/careflow_brand_title.dart';
import '../../../repositories/analytics_repository.dart';
import '../../../repositories/clinic_repository.dart';
import '../../../repositories/doctor_repository.dart';
import '../../../repositories/patient_repository.dart';
import '../../../services/auth_service.dart';

class PlatformAdminDashboard extends StatefulWidget {
  const PlatformAdminDashboard({super.key});

  @override
  State<PlatformAdminDashboard> createState() => _PlatformAdminDashboardState();
}

class _PlatformAdminDashboardState extends State<PlatformAdminDashboard>
    with SingleTickerProviderStateMixin {
  final AnalyticsRepository _analyticsRepo = AnalyticsRepository();
  final ClinicRepository _clinicRepo = ClinicRepository();
  final DoctorRepository _doctorRepo = DoctorRepository();
  final PatientRepository _patientRepo = PatientRepository();

  late TabController _tabController;

  bool _isLoading = true;
  Map<String, int> _stats = {
    'totalPatients': 0,
    'totalClinics': 0,
    'totalDoctors': 0,
    'pendingClinics': 0,
  };

  List<Map<String, dynamic>> _allClinics = [];
  List<Map<String, dynamic>> _pendingClinics = [];
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _patients = [];

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _analyticsRepo.getAdminPlatformStats();
      final allClinics = await _clinicRepo.listAll();
      final pendingClinics = await _clinicRepo.getPendingClinics();
      final doctors = await _doctorRepo.list();
      final patients = await _patientRepo.list();

      if (mounted) {
        setState(() {
          _stats = stats;
          _allClinics = allClinics;
          _pendingClinics = pendingClinics;
          _doctors = doctors;
          _patients = patients;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveClinic(String clinicId, String name) async {
    try {
      await _clinicRepo.approveClinic(clinicId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ColorTokens.careGreen,
            content: Text('Clinic "$name" approved successfully.'),
          ),
        );
      }
      _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve clinic: $e')),
        );
      }
    }
  }

  Future<void> _rejectClinic(String clinicId, String name) async {
    final reasonController = TextEditingController();
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Clinic "$name"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for the rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g. Incomplete license documentation',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorTokens.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldReject == true) {
      try {
        await _clinicRepo.rejectClinic(
          clinicId,
          reason: reasonController.text.trim().isNotEmpty
              ? reasonController.text.trim()
              : 'Documentation does not meet platform standards.',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: ColorTokens.error,
              content: Text('Clinic "$name" rejected.'),
            ),
          );
        }
        _loadAllData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reject clinic: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleClinicSuspension(String clinicId, String name, bool isSuspended) async {
    try {
      if (isSuspended) {
        await _clinicRepo.reactivateClinic(clinicId);
      } else {
        await _clinicRepo.suspendClinic(clinicId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clinic "$name" ${isSuspended ? "reactivated" : "suspended"}.'),
          ),
        );
      }
      _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/auth/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const CareFlowBrandTitle(
          subtitle: 'Platform Admin',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: ColorTokens.darkNavy),
            tooltip: 'Refresh',
            onPressed: _loadAllData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: ColorTokens.darkNavy),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorTokens.primaryBlue,
          unselectedLabelColor: ColorTokens.textSecondary,
          indicatorColor: ColorTokens.primaryBlue,
          tabs: [
            Tab(
              text: 'Overview',
              icon: Badge(
                isLabelVisible: _stats['pendingClinics']! > 0,
                label: Text('${_stats['pendingClinics']}'),
                child: const Icon(Icons.dashboard_outlined),
              ),
            ),
            const Tab(text: 'Clinics', icon: Icon(Icons.local_hospital_outlined)),
            const Tab(text: 'Doctors', icon: Icon(Icons.medical_services_outlined)),
            const Tab(text: 'Patients', icon: Icon(Icons.people_outline)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildClinicsTab(),
                _buildDoctorsTab(),
                _buildPatientsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Platform Live Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ColorTokens.darkNavy,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Patients',
                  count: _stats['totalPatients'] ?? 0,
                  icon: Icons.person_outline,
                  color: ColorTokens.primaryBlue,
                  onTap: () => _tabController.animateTo(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Clinics',
                  count: _stats['totalClinics'] ?? 0,
                  icon: Icons.local_hospital_outlined,
                  color: ColorTokens.careGreen,
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Doctors',
                  count: _stats['totalDoctors'] ?? 0,
                  icon: Icons.medical_services_outlined,
                  color: const Color(0xFF6366F1),
                  onTap: () => _tabController.animateTo(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Pending Review',
                  count: _stats['pendingClinics'] ?? 0,
                  icon: Icons.pending_actions_rounded,
                  color: ColorTokens.warning,
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Clinics Awaiting Approval',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ColorTokens.darkNavy,
                ),
              ),
              Text(
                '${_pendingClinics.length} pending',
                style: const TextStyle(
                  color: ColorTokens.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_pendingClinics.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: ColorTokens.border),
              ),
              child: const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, color: ColorTokens.careGreen, size: 44),
                      SizedBox(height: 10),
                      Text(
                        'All clinic registrations reviewed',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'No pending applications in the approval queue.',
                        style: TextStyle(color: ColorTokens.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._pendingClinics.map((clinic) => _buildPendingClinicCard(clinic)),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: ColorTokens.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: ColorTokens.textMuted),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ColorTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingClinicCard(Map<String, dynamic> clinic) {
    final name = (clinic['name'] ?? clinic['clinic_name'] ?? 'CareFlow Clinic').toString();
    final address = (clinic['address'] ?? 'Address not specified').toString();
    final phone = (clinic['phone'] ?? '').toString();
    final id = clinic['id'].toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ColorTokens.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: ColorTokens.warning),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ColorTokens.darkNavy,
                        ),
                      ),
                      if (phone.isNotEmpty)
                        Text(
                          'Phone: $phone',
                          style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorTokens.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ColorTokens.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Location: $address',
              style: const TextStyle(fontSize: 13, color: ColorTokens.textSecondary),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorTokens.error,
                    side: const BorderSide(color: ColorTokens.error),
                  ),
                  onPressed: () => _rejectClinic(id, name),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorTokens.careGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _approveClinic(id, name),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve Clinic'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicsTab() {
    final filtered = _allClinics.where((c) {
      final n = (c['name'] ?? c['clinic_name'] ?? '').toString().toLowerCase();
      return n.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildSearchField('Search clinics by name or location...'),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No clinics found matching criteria.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final c = filtered[i];
                    final name = (c['name'] ?? c['clinic_name'] ?? 'CareFlow Clinic').toString();
                    final status = (c['status'] ?? 'approved').toString().toLowerCase();
                    final id = c['id'].toString();
                    final isSuspended = status == 'suspended';
                    final isPending = status == 'pending';

                    Color statusColor = ColorTokens.careGreen;
                    if (isPending) statusColor = ColorTokens.warning;
                    if (isSuspended) statusColor = ColorTokens.error;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: ColorTokens.border),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.15),
                          child: Icon(Icons.local_hospital_rounded, color: statusColor),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          c['phone']?.toString().isNotEmpty == true
                              ? 'Phone: ${c['phone']}'
                              : 'Status: ${status.toUpperCase()}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'approve') _approveClinic(id, name);
                            if (val == 'reject') _rejectClinic(id, name);
                            if (val == 'toggle_suspend') _toggleClinicSuspension(id, name, isSuspended);
                          },
                          itemBuilder: (ctx) => [
                            if (isPending) ...[
                              const PopupMenuItem(value: 'approve', child: Text('Approve Clinic')),
                              const PopupMenuItem(value: 'reject', child: Text('Reject Clinic')),
                            ],
                            PopupMenuItem(
                              value: 'toggle_suspend',
                              child: Text(isSuspended ? 'Reactivate Clinic' : 'Suspend Clinic'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDoctorsTab() {
    final filtered = _doctors.where((d) {
      final n = (d['full_name'] ?? '').toString().toLowerCase();
      final spec = (d['specialization'] ?? '').toString().toLowerCase();
      return n.contains(_searchQuery.toLowerCase()) || spec.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildSearchField('Search doctors by name or specialization...'),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No doctors registered.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final d = filtered[i];
                    final name = (d['full_name'] ?? 'Doctor').toString();
                    final spec = (d['specialization'] ?? 'General Medicine').toString();
                    final phone = (d['phone'] ?? '').toString();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: ColorTokens.border),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: ColorTokens.lightBlue,
                          child: Icon(Icons.medical_services_outlined, color: ColorTokens.primaryBlue),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('$spec ${phone.isNotEmpty ? "• $phone" : ""}'),
                        trailing: const Chip(
                          label: Text('Active', style: TextStyle(fontSize: 11, color: ColorTokens.careGreen)),
                          backgroundColor: ColorTokens.lightGreen,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPatientsTab() {
    final filtered = _patients.where((p) {
      final n = (p['full_name'] ?? '').toString().toLowerCase();
      return n.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildSearchField('Search patients by name...'),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No registered patients found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final p = filtered[i];
                    final name = (p['full_name'] ?? 'Patient').toString();
                    final phone = (p['phone'] ?? 'No phone').toString();
                    final gender = (p['gender'] ?? '').toString();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: ColorTokens.border),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: ColorTokens.lightBlue,
                          child: Icon(Icons.person_outline, color: ColorTokens.primaryBlue),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('Phone: $phone ${gender.isNotEmpty ? "• $gender" : ""}'),
                        trailing: const Chip(
                          label: Text('Registered', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchField(String hint) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: ColorTokens.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }
}
