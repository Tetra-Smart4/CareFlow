import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/appointment_repository.dart';
import '../../../repositories/clinic_repository.dart';

class ClinicCalendarScreen extends StatefulWidget {
  const ClinicCalendarScreen({super.key});

  @override
  State<ClinicCalendarScreen> createState() => _ClinicCalendarScreenState();
}

class _ClinicCalendarScreenState extends State<ClinicCalendarScreen> {
  final _appointmentRepo = AppointmentRepository();
  final _clinicRepo = ClinicRepository();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _appointments = [];

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

      if (cid != null) {
        final list = await _appointmentRepo.list(clinicId: cid);
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
          _error = 'Unable to load clinic appointment schedule.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Clinic Schedule & Calendar'),
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
                              Icon(Icons.calendar_month_outlined, size: 52, color: ColorTokens.muted),
                              SizedBox(height: 12),
                              Text(
                                'No Scheduled Appointments',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: ColorTokens.navy,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Bookings across all clinic doctors will appear here.',
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
                          final time = appt['appointment_time']?.toString() ?? '';
                          final date = appt['appointment_date']?.toString() ?? '';
                          final patient = appt['patient_name'] ?? 'Patient';
                          final doctor = appt['doctor_name'] ?? 'Doctor';
                          final reason = appt['reason']?.toString() ?? 'Consultation';
                          final status = appt['status']?.toString() ?? 'confirmed';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: ColorTokens.lightBlue,
                                child: Icon(Icons.calendar_today_rounded, color: ColorTokens.primaryBlue),
                              ),
                              title: Text(
                                '$time • $patient',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.navy),
                              ),
                              subtitle: Text('Dr. $doctor • $date • $reason'),
                              trailing: Chip(
                                label: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                                backgroundColor: status == 'completed'
                                    ? ColorTokens.lightGreen
                                    : ColorTokens.lightBlue,
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
