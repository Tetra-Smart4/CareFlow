import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/clinic_repository.dart';
import '../../../repositories/doctor_repository.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _doctorRepo = DoctorRepository();
  final _clinicRepo = ClinicRepository();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _doctors = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final cid = await _clinicRepo.getCurrentUserClinicId() ?? user?.id;

      if (cid != null) {
        final list = await _doctorRepo.getByClinic(cid);
        if (mounted) {
          setState(() {
            _doctors = list;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _doctors = [];
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load clinic doctors & staff.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Clinic Staff & Doctors'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/clinic/doctors/add').then((_) => _loadUsers());
            },
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add Doctor',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: ColorTokens.error),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: ColorTokens.muted)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadUsers, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _doctors.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.group_outlined, size: 52, color: ColorTokens.muted),
                              const SizedBox(height: 12),
                              const Text(
                                'No Doctors Added Yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: ColorTokens.navy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Add doctors to your clinic to start managing appointments and queues.',
                                style: TextStyle(color: ColorTokens.muted),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/clinic/doctors/add').then((_) => _loadUsers());
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Doctor'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) {
                          final doc = _doctors[index];
                          final name = doc['full_name'] ?? 'Doctor';
                          final spec = doc['specialization'] ?? 'Specialist';
                          final phone = doc['phone']?.toString() ?? '';
                          final isAvailable = doc['is_available'] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: ColorTokens.lightBlue,
                                child: const Icon(Icons.medical_services_rounded, color: ColorTokens.primaryBlue),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.navy),
                              ),
                              subtitle: Text('$spec${phone.isNotEmpty ? " • $phone" : ""}'),
                              trailing: Chip(
                                label: Text(
                                  isAvailable ? 'Available' : 'Unavailable',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                                backgroundColor: isAvailable ? ColorTokens.lightGreen : ColorTokens.background,
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
