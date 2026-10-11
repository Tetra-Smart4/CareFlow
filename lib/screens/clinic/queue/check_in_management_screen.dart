import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/appointment_repository.dart';
import '../../../repositories/clinic_repository.dart';

class CheckInManagementScreen extends StatefulWidget {
  const CheckInManagementScreen({super.key});

  @override
  State<CheckInManagementScreen> createState() => _CheckInManagementScreenState();
}

class _CheckInManagementScreenState extends State<CheckInManagementScreen> {
  final _appointmentRepo = AppointmentRepository();
  final _clinicRepo = ClinicRepository();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _appointments = [];
  String? _clinicId;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final cid = await _clinicRepo.getCurrentUserClinicId() ?? user?.id;
      _clinicId = cid;

      if (cid != null) {
        final list = await _appointmentRepo.list(
          clinicId: cid,
          status: 'confirmed',
        );

        if (mounted) {
          setState(() {
            _appointments = list;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _appointments = [];
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load appointments for check-in.';
        });
      }
    }
  }

  Future<void> _checkIn(String apptId) async {
    try {
      final res = await _appointmentRepo.checkIn(apptId, clinicId: _clinicId);
      final token = res['token_number'] ?? res['token'];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient checked in! Token #$token assigned.'),
            backgroundColor: ColorTokens.careGreen,
          ),
        );
      }
      _loadAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: ${e.toString()}'),
            backgroundColor: ColorTokens.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Patient Check-In Desk'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadAppointments,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
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
                        ElevatedButton(onPressed: _loadAppointments, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _appointments.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.how_to_reg_outlined, size: 52, color: ColorTokens.muted),
                              SizedBox(height: 12),
                              Text(
                                'No Pending Check-Ins',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: ColorTokens.navy,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'All confirmed patients have either already checked in or no appointments are due.',
                                style: TextStyle(color: ColorTokens.muted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final appt = _appointments[index];
                          final id = appt['id'].toString();
                          final patient = appt['patient_name'] ?? 'Patient';
                          final doctor = appt['doctor_name'] ?? 'Doctor';
                          final time = appt['appointment_time']?.toString() ?? '';
                          final date = appt['appointment_date']?.toString() ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: ColorTokens.lightBlue,
                                    child: const Icon(
                                      Icons.person_pin_circle_outlined,
                                      color: ColorTokens.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          patient,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: ColorTokens.navy,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Dr. $doctor • $time',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: ColorTokens.primaryBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          date,
                                          style: const TextStyle(fontSize: 12, color: ColorTokens.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _checkIn(id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ColorTokens.careGreen,
                                    ),
                                    child: const Text('Check In'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
