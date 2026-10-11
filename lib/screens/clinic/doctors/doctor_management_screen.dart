import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/clinic_repository.dart';
import '../../../repositories/doctor_repository.dart';
import '../../../widgets/common/careflow_feature_icon.dart';

class DoctorManagementScreen extends StatefulWidget {
  const DoctorManagementScreen({super.key});

  @override
  State<DoctorManagementScreen> createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends State<DoctorManagementScreen> {
  final _doctorRepo = DoctorRepository();
  final _clinicRepo = ClinicRepository();

  bool _loading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _doctors = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
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
          _doctors = [];
        });
        return;
      }

      final list = await _doctorRepo.getByClinic(clinicId);

      if (mounted) {
        setState(() {
          _doctors = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load clinic doctors: $e';
        });
      }
    }
  }

  Future<void> _toggleAvailability(String doctorId, bool current) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final clinicId = await _clinicRepo.getCurrentUserClinicId() ?? user?.id;

      await _doctorRepo.setAvailability(doctorId, !current, clinicId: clinicId);
      await _loadDoctors();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Doctor availability updated to ${!current ? "Available" : "Unavailable"}.'),
            backgroundColor: ColorTokens.careGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update availability: $e'), backgroundColor: ColorTokens.error),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredDoctors {
    if (_searchQuery.trim().isEmpty) return _doctors;
    final q = _searchQuery.toLowerCase();
    return _doctors.where((d) {
      final name = (d['full_name'] ?? '').toLowerCase();
      final spec = (d['specialization'] ?? '').toLowerCase();
      final phone = (d['phone'] ?? '').toLowerCase();
      return name.contains(q) || spec.contains(q) || phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Clinic Doctors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDoctors,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/clinic/doctors/add').then((_) => _loadDoctors());
        },
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Doctor'),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search doctors by name or specialty...',
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
                              ElevatedButton(onPressed: _loadDoctors, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _filteredDoctors.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CareFlowFeatureIcon(
                                    icon: Icons.search_rounded,
                                    iconColor: ColorTokens.careGreen,
                                    backgroundColor: ColorTokens.lightGreen,
                                    containerSize: 84,
                                    iconSize: 42,
                                    borderRadius: 24,
                                    hasShadow: true,
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'No Doctors Added Yet',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Approved clinics can register doctor accounts to manage consultations.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: ColorTokens.muted, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/clinic/doctors/add').then((_) => _loadDoctors());
                                    },
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Add Doctor'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadDoctors,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredDoctors.length,
                              itemBuilder: (ctx, i) {
                                final d = _filteredDoctors[i];
                                final name = d['full_name'] ?? 'Doctor';
                                final spec = d['specialization'] ?? 'General Physician';
                                final qual = d['qualification'] ?? '';
                                final fee = d['consultation_fee'];
                                final phone = d['phone'] ?? '';
                                final isAvailable = d['is_available'] == true;
                                final dId = d['id'].toString();

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
                                              radius: 24,
                                              backgroundColor: ColorTokens.lightBlue,
                                              child: Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : 'D',
                                                style: const TextStyle(fontWeight: FontWeight.w900, color: ColorTokens.primaryBlue),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                                                  ),
                                                  Text(
                                                    [spec, if (qual.isNotEmpty) qual].join(' • '),
                                                    style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                                                  ),
                                                  if (phone.isNotEmpty)
                                                    Text(phone, style: const TextStyle(fontSize: 11, color: ColorTokens.textMuted)),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isAvailable ? ColorTokens.lightGreen : ColorTokens.border.withValues(alpha: 0.5),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    isAvailable ? 'Available' : 'Off-duty',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: isAvailable ? ColorTokens.careGreen : ColorTokens.muted,
                                                    ),
                                                  ),
                                                ),
                                                if (fee != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text('₹$fee', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy)),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1, color: ColorTokens.border),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Duty Availability', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ColorTokens.darkNavy)),
                                            Switch(
                                              value: isAvailable,
                                              activeThumbColor: ColorTokens.careGreen,
                                              onChanged: (_) => _toggleAvailability(dId, isAvailable),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
