import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import 'package:careflow/widgets/common/lottie_animation.dart';
import 'package:flutter_animate/flutter_animate.dart';
class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _patients = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _patients = [];
        });
        return;
      }

      // Query appointments for this doctor to identify authorized patients
      final apptData = await Supabase.instance.client
          .from('careflow_appointments')
          .select('patient_id, appointment_date, status, reason')
          .eq('doctor_id', user.id);

      final patientIds = (apptData as List)
          .map((e) => e['patient_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      if (patientIds.isEmpty) {
        setState(() {
          _patients = [];
          _loading = false;
        });
        return;
      }

      // Query patient profiles
      final profiles = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, phone, gender, age, city, address')
          .inFilter('id', patientIds);

      final List<Map<String, dynamic>> loadedList = [];
      for (final p in profiles) {
        final pId = p['id'].toString();
        final relatedAppts = (apptData as List).where((a) => a['patient_id']?.toString() == pId).toList();
        final lastVisit = relatedAppts.isNotEmpty ? relatedAppts.first['appointment_date'] : null;

        loadedList.add({
          ...p,
          'last_visit': lastVisit,
          'total_visits': relatedAppts.length,
        });
      }

      if (mounted) {
        setState(() {
          _patients = loadedList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load patients: $e';
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPatients {
    if (_searchQuery.trim().isEmpty) return _patients;
    final q = _searchQuery.toLowerCase();
    return _patients.where((p) {
      final name = (p['full_name'] ?? '').toString().toLowerCase();
      final id = (p['id'] ?? '').toString().toLowerCase();
      final phone = (p['phone'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q) || phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPatients,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by patient name or ID...',
                prefixIcon: const Icon(Icons.search, size: 20, color: ColorTokens.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ColorTokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ColorTokens.border),
                ),
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
                              ElevatedButton(
                                onPressed: _loadPatients,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredPatients.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  LottieAnimation(
                                    assetName: 'assets/animations/empty.json',
                                    width: 150,
                                    fallback: Icon(Icons.person_search_outlined, size: 48, color: ColorTokens.muted),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No Patients Found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: ColorTokens.darkNavy,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Patients scheduled or consulted by you will appear here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: ColorTokens.muted, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPatients,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredPatients.length,
                              itemBuilder: (ctx, i) {
                                final p = _filteredPatients[i];
                                final name = p['full_name'] ?? 'Patient';
                                final age = p['age']?.toString();
                                final gender = p['gender']?.toString();
                                final phone = p['phone'] ?? '';
                                final totalVisits = p['total_visits'] ?? 1;

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: ColorTokens.border),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: ColorTokens.lightBlue,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: ColorTokens.primaryBlue,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                                    ),
                                    subtitle: Text(
                                      [
                                        ?age != null ? '$age yrs' : null,
                                        ?gender,
                                        if (phone.isNotEmpty) phone,
                                        '$totalVisits visit(s)',
                                      ].join(' • '),
                                      style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                                    ),
                                    trailing: const Icon(Icons.chevron_right_rounded, color: ColorTokens.muted),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/doctor/patients/detail',
                                        arguments: p,
                                      );
                                    },
                                  ),
                                ).animate().fade(delay: (i * 50).ms, duration: 400.ms).slideX(begin: 0.1, duration: 400.ms);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
