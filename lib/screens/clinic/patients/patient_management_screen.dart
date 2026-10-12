import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/clinic_repository.dart';

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  final _clinicRepo = ClinicRepository();
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final clinicId = await _clinicRepo.getCurrentUserClinicId() ?? user?.id;

      if (clinicId == null) {
        setState(() {
          _patients = [];
          _loading = false;
        });
        return;
      }

      // 1. Try secure RPC careflow_get_clinic_patients
      try {
        final rpcData = await Supabase.instance.client.rpc(
          'careflow_get_clinic_patients',
          params: {'p_clinic_id': clinicId},
        );

        if (rpcData is List) {
          if (mounted) {
            setState(() {
              _patients = List<Map<String, dynamic>>.from(rpcData);
              _loading = false;
            });
          }
          return;
        }
      } catch (_) {}

      // 2. Fallback: strictly query appointments belonging to THIS clinic
      final appts = await Supabase.instance.client
          .from('careflow_appointments')
          .select('patient_id')
          .eq('clinic_id', clinicId);

      final patientIds = appts
          .map((e) => e['patient_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      List<Map<String, dynamic>> profilesData = [];
      if (patientIds.isNotEmpty) {
        final raw = await Supabase.instance.client
            .from('profiles')
            .select()
            .inFilter('id', patientIds);

        profilesData = List<Map<String, dynamic>>.from(raw);
      }

      if (mounted) {
        setState(() {
          _patients = profilesData;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load clinic patients: $e';
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPatients {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _patients;
    return _patients.where((p) {
      final name = (p['full_name'] ?? '').toString().toLowerCase();
      final phone = (p['phone'] ?? '').toString().toLowerCase();
      final email = (p['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q) || email.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPatients;

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Clinic Patient Directory'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadPatients,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPatients,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search patients by name, phone, or email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: ColorTokens.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: ColorTokens.muted)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadPatients, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline, size: 54, color: ColorTokens.muted),
                      const SizedBox(height: 16),
                      const Text(
                        'No Clinic Patients Found',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: ColorTokens.darkNavy),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This directory only displays patients who have scheduled appointments with doctors at this clinic.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: ColorTokens.muted),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filtered.map((p) {
                final name = p['full_name'] ?? 'Patient';
                final phone = p['phone'] ?? '';
                final email = p['email'] ?? '';
                final gender = p['gender'] ?? '';
                final age = p['age'];
                final apptCount = p['total_appointments'];
                final lastDate = p['last_appointment_date'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: ColorTokens.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: ColorTokens.lightGreen,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'P',
                            style: const TextStyle(
                              color: ColorTokens.careGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ColorTokens.darkNavy),
                              ),
                              const SizedBox(height: 4),
                              if (phone.isNotEmpty)
                                Text('Phone: $phone', style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
                              if (email.isNotEmpty)
                                Text('Email: $email', style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
                              if (gender.isNotEmpty || age != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  [if (gender.isNotEmpty) gender, if (age != null) '$age yrs'].join(', '),
                                  style: const TextStyle(fontSize: 11, color: ColorTokens.textMuted),
                                ),
                              ],
                              if (apptCount != null || lastDate != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: ColorTokens.lightBlue,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${apptCount ?? 1} Appointments • Last: ${lastDate ?? 'Recent'}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ColorTokens.primaryBlue),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
