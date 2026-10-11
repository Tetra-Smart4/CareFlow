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

      // 1. Find patient IDs from clinic appointments
      List<String> patientIds = [];
      if (clinicId != null) {
        final appts = await Supabase.instance.client
            .from('careflow_appointments')
            .select('patient_id')
            .eq('clinic_id', clinicId);

        patientIds = appts
            .map((e) => e['patient_id']?.toString())
            .whereType<String>()
            .toSet()
            .toList();
      }

      List<dynamic> profilesData = [];
      if (patientIds.isNotEmpty) {
        profilesData = await Supabase.instance.client
            .from('profiles')
            .select()
            .inFilter('id', patientIds);
      } else {
        // Fallback: list patients if none booked yet or broad query
        profilesData = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('role', 'patient')
            .limit(20);
      }

      if (mounted) {
        setState(() {
          _patients = List<Map<String, dynamic>>.from(profilesData);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load clinic patients.';
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
      return name.contains(q) || phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPatients;

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Patient Directory'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadPatients,
            icon: const Icon(Icons.refresh_rounded),
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
                hintText: 'Search by patient name or phone',
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
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: const [
                      Icon(Icons.people_outline_rounded, size: 52, color: ColorTokens.muted),
                      SizedBox(height: 12),
                      Text(
                        'No patients found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ColorTokens.navy,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Patients who register or book appointments at your clinic will appear here.',
                        style: TextStyle(color: ColorTokens.muted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                '${filtered.length} Registered Patient${filtered.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ColorTokens.navy,
                ),
              ),
              const SizedBox(height: 12),
              ...filtered.map((patient) {
                final name = patient['full_name'] ?? 'Patient';
                final phone = patient['phone']?.toString() ?? 'No phone';
                final gender = patient['gender']?.toString() ?? '';
                final age = patient['age'];

                final details = [
                  if (gender.isNotEmpty) gender,
                  if (age != null) 'Age $age',
                  phone,
                ].join(' • ');

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: ColorTokens.lightBlue,
                      child: Text(
                        _initials(name),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ColorTokens.primaryBlue,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.navy),
                    ),
                    subtitle: Text(details, style: const TextStyle(fontSize: 13, color: ColorTokens.muted)),
                    trailing: const Icon(Icons.chevron_right, color: ColorTokens.muted),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/doctor/patients/details',
                        arguments: {'patient': patient, 'patientId': patient['id']},
                      );
                    },
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
