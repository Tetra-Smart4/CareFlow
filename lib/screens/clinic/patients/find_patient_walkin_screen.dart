import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/appointment_repository.dart';
import '../../../repositories/clinic_repository.dart';
import '../../../repositories/doctor_repository.dart';

class FindPatientWalkInScreen extends StatefulWidget {
  const FindPatientWalkInScreen({super.key});

  @override
  State<FindPatientWalkInScreen> createState() => _FindPatientWalkInScreenState();
}

class _FindPatientWalkInScreenState extends State<FindPatientWalkInScreen> {
  final _searchController = TextEditingController();
  final _clinicRepo = ClinicRepository();
  final _doctorRepo = DoctorRepository();
  final _appointmentRepo = AppointmentRepository();

  bool _isSearching = false;
  String? _clinicId;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _clinicDoctors = [];
  String? _selectedDoctorId;
  bool _hasSearched = false;
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _loadClinicData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClinicData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final cid = await _clinicRepo.getCurrentUserClinicId() ?? user?.id;
      _clinicId = cid;

      if (cid != null) {
        final docs = await _doctorRepo.getByClinic(cid);
        if (mounted) {
          setState(() {
            _clinicDoctors = docs;
            if (docs.isNotEmpty) {
              _selectedDoctorId = docs.first['id']?.toString();
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      // Search patient profiles by phone, full_name, or exact ID
      final client = Supabase.instance.client;
      var queryBuilder = client
          .from('profiles')
          .select('id, full_name, phone, date_of_birth, gender')
          .eq('role', 'patient');

      // If digits, search phone or ID
      if (RegExp(r'^[0-9+]+$').hasMatch(query)) {
        queryBuilder = queryBuilder.ilike('phone', '%$query%');
      } else {
        queryBuilder = queryBuilder.ilike('full_name', '%$query%');
      }

      final res = await queryBuilder.limit(20);
      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(res);
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: ColorTokens.error,
          ),
        );
      }
    }
  }

  Future<void> _startWalkInCheckIn(Map<String, dynamic> patient) async {
    if (_clinicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clinic session not verified.')),
      );
      return;
    }

    if (_clinicDoctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active doctors found at this clinic.')),
      );
      return;
    }

    final doctorId = _selectedDoctorId ?? _clinicDoctors.first['id']?.toString();
    if (doctorId == null) return;

    setState(() => _isProcessingAction = true);

    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final timeStr = '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $period';

      // 1. Book walk-in appointment
      final appt = await _appointmentRepo.create({
        'patient_id': patient['id'],
        'doctor_id': doctorId,
        'clinic_id': _clinicId,
        'appointment_date': dateStr,
        'appointment_time': timeStr,
        'reason': 'Walk-in Visit',
      });

      // 2. Perform check-in to allocate live queue token
      final apptId = appt['id']?.toString();
      if (apptId != null) {
        final checkInResult = await _appointmentRepo.checkIn(apptId, clinicId: _clinicId);
        final token = checkInResult['token_number'] ?? checkInResult['token'] ?? 1;

        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: ColorTokens.careGreen, size: 26),
                  SizedBox(width: 10),
                  Text('Walk-in Checked In'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient: ${patient['full_name'] ?? 'Patient'}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: ColorTokens.lightGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Queue Token Number:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '#$token',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: ColorTokens.careGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The patient has been added to the live waiting queue and is assigned to the attending doctor.',
                    style: TextStyle(fontSize: 13, color: ColorTokens.muted),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context); // back to dashboard
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check in walk-in: $e'),
            backgroundColor: ColorTokens.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final name = patient['full_name'] ?? 'Unnamed Patient';
    final phone = patient['phone'] ?? 'No phone recorded';
    final gender = patient['gender'] ?? 'Not specified';
    final dob = patient['date_of_birth'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
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
                  backgroundColor: ColorTokens.lightBlue,
                  radius: 22,
                  child: const Icon(Icons.person, color: ColorTokens.primaryBlue),
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
                      const SizedBox(height: 2),
                      Text(
                        'Phone: $phone',
                        style: const TextStyle(fontSize: 13, color: ColorTokens.muted),
                      ),
                      if (dob.isNotEmpty || gender != 'Not specified')
                        Text(
                          'Gender: $gender • DOB: $dob',
                          style: const TextStyle(fontSize: 12, color: ColorTokens.muted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: ColorTokens.border),
            const SizedBox(height: 12),

            // Attending doctor selector for walk-in
            if (_clinicDoctors.isNotEmpty) ...[
              const Text(
                'Attending Doctor for Visit:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ColorTokens.muted),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedDoctorId,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _clinicDoctors.map((doc) {
                  final dName = doc['full_name'] ?? doc['name'] ?? 'Doctor';
                  final dSpec = doc['specialization'] ?? 'General';
                  return DropdownMenuItem<String>(
                    value: doc['id'].toString(),
                    child: Text('Dr. $dName ($dSpec)', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedDoctorId = val);
                },
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('Book Appointment'),
                    onPressed: _isProcessingAction
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              '/patient/appointments/book',
                              arguments: {'patientId': patient['id']},
                            );
                          },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: ColorTokens.careGreen),
                    icon: _isProcessingAction
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.how_to_reg_rounded, size: 18),
                    label: const Text('Walk-in Check In'),
                    onPressed: _isProcessingAction ? null : () => _startWalkInCheckIn(patient),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Find Patient / Walk-in'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Healthcare Policy Notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorTokens.lightBlue,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ColorTokens.primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.shield_outlined, color: ColorTokens.primaryBlue, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'CareFlow Patient Data Sovereignty: Patients own their personal accounts and self-register. Clinics cannot create patient login credentials. Search for existing patient records below or initiate an in-person walk-in encounter.',
                    style: TextStyle(fontSize: 12.5, color: ColorTokens.darkNavy, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Search Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Phone number or Patient Name...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _hasSearched = false;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSearching ? null : _performSearch,
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Search'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Results
          if (_hasSearched && _searchResults.isEmpty && !_isSearching) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const Icon(Icons.person_search_outlined, size: 56, color: ColorTokens.muted),
                    const SizedBox(height: 14),
                    const Text(
                      'No Matching Patient Found',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'This phone number or name does not match an existing CareFlow patient account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ColorTokens.muted, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: ColorTokens.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Row(
                              children: [
                                Icon(Icons.app_registration_rounded, color: ColorTokens.careGreen, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Patient Self-Registration Required',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'To access full medical histories, digital prescriptions, and laboratory reports, patients must create their own account via the CareFlow Patient app or web portal.\n\nClinics cannot create login accounts on behalf of patients.',
                              style: TextStyle(fontSize: 12.5, color: ColorTokens.muted, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_searchResults.isNotEmpty) ...[
            Text(
              'Found ${_searchResults.length} Patient Record(s)',
              style: const TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ..._searchResults.map(_buildPatientCard),
          ],
        ],
      ),
    );
  }
}
