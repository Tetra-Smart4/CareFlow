import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/queue_repository.dart';

class DoctorAppointmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? appointment;

  const DoctorAppointmentDetailsScreen({super.key, this.appointment});

  @override
  State<DoctorAppointmentDetailsScreen> createState() => _DoctorAppointmentDetailsScreenState();
}

class _DoctorAppointmentDetailsScreenState extends State<DoctorAppointmentDetailsScreen> {
  final _queueRepo = QueueRepository();

  Map<String, dynamic>? _appt;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appt == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _appt = Map<String, dynamic>.from(args);
      } else if (widget.appointment != null) {
        _appt = Map<String, dynamic>.from(widget.appointment!);
      }
      
      // If we only have an ID (e.g. navigated from a notification), fetch full details
      final idToFetch = _appt?['appointment_id'] ?? _appt?['id'];
      if (idToFetch != null && _appt!.keys.length <= 2) {
        _fetchAppointmentDetails(idToFetch.toString());
      }
    }
  }

  Future<void> _fetchAppointmentDetails(String apptId) async {
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('careflow_appointments')
          .select()
          .eq('id', apptId)
          .maybeSingle();
          
      if (data != null) {
        final Map<String, dynamic> fullAppt = Map<String, dynamic>.from(data);
        
        // Try fetching patient profile
        final pId = data['patient_id'];
        if (pId != null) {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('full_name, phone')
              .eq('id', pId)
              .maybeSingle();
          if (profile != null) {
            fullAppt['patient_name'] = profile['full_name'];
            fullAppt['patient_phone'] = profile['phone'];
          }
        }
        
        if (mounted) {
          setState(() {
            _appt = fullAppt;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_appt == null) return;
    setState(() => _loading = true);

    try {
      final apptId = _appt!['id'].toString();
      await _queueRepo.updateStatus(apptId, newStatus);
      setState(() {
        _appt!['status'] = newStatus;
        _loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment updated to $newStatus.'),
            backgroundColor: ColorTokens.careGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating appointment: $e'),
            backgroundColor: ColorTokens.error,
          ),
        );
      }
    }
  }

  Future<void> _callPatient() async {
    if (_appt == null) return;
    setState(() => _loading = true);

    try {
      final apptId = _appt!['id'].toString();
      final pId = _appt!['patient_id']?.toString();
      final token = _appt!['token_number'];

      await Supabase.instance.client.from('careflow_appointments').update({
        'status': 'called',
        'called_at': DateTime.now().toIso8601String(),
      }).eq('id', apptId);

      if (pId != null) {
        try {
          await Supabase.instance.client.from('careflow_notifications').insert({
            'user_id': pId,
            'title': 'Your Turn: Now Calling #$token',
            'body': 'Doctor is ready for your consultation. Please enter the room.',
            'type': 'queue',
            'is_read': false,
          });
        } catch (_) {}
      }

      setState(() {
        _appt!['status'] = 'called';
        _loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient called successfully!'),
            backgroundColor: ColorTokens.careGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: ColorTokens.error),
        );
      }
    }
  }

  Future<void> _startConsultation() async {
    if (_appt == null) return;
    setState(() => _loading = true);

    try {
      final apptId = _appt!['id'].toString();
      await _queueRepo.startConsultation(apptId);
      setState(() {
        _appt!['status'] = 'in_consultation';
        _loading = false;
      });

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/doctor/consultation',
          arguments: {
            'appointmentId': apptId,
            'patientId': _appt!['patient_id'],
            'patientName': _appt!['patient_name'] ?? 'Patient',
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: ColorTokens.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_appt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appointment Details')),
        body: const Center(child: Text('No appointment data received.')),
      );
    }

    final patientName = _appt!['patient_name'] ?? 'Patient';
    final patientId = _appt!['patient_id']?.toString() ?? 'N/A';
    final phone = _appt!['patient_phone'] ?? 'Protected / Not shared';
    final apptId = _appt!['id']?.toString() ?? 'N/A';
    final date = _appt!['appointment_date'] ?? 'N/A';
    final time = _appt!['appointment_time'] ?? 'N/A';
    final clinic = _appt!['clinic_name'] ?? 'CareFlow Clinic';
    final reason = _appt!['reason'] ?? 'Consultation';
    final token = _appt!['token_number'] ?? 0;
    final status = (_appt!['status'] ?? 'pending').toString().toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Appointment Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient Header Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: ColorTokens.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: ColorTokens.lightBlue,
                      child: Text(
                        patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: ColorTokens.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: ColorTokens.darkNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: $patientId',
                            style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                          ),
                          Text(
                            'Phone: $phone',
                            style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusBg(status),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _statusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Clinical & Appointment Info Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: ColorTokens.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Appointment ID', apptId),
                    const Divider(height: 18, color: ColorTokens.border),
                    _buildInfoRow('Date & Time', '$date at $time'),
                    const Divider(height: 18, color: ColorTokens.border),
                    _buildInfoRow('Queue Token', token > 0 ? '#$token' : 'Not generated'),
                    const Divider(height: 18, color: ColorTokens.border),
                    _buildInfoRow('Clinic Location', clinic),
                    const Divider(height: 18, color: ColorTokens.border),
                    _buildInfoRow('Chief Complaint', reason),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // View Medical History Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/doctor/patients/detail',
                  arguments: {
                    'id': _appt!['patient_id'],
                    'full_name': patientName,
                    'phone': phone,
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.history_edu_rounded),
              label: const Text('View Full Medical History', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 24),

            // Contextual Actions based on Appointment State
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (status == 'checked_in' || status == 'waiting')
                ElevatedButton.icon(
                  onPressed: _callPatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.campaign_rounded),
                  label: const Text('Call Patient (Step into Room)', style: TextStyle(fontWeight: FontWeight.w700)),
                ),

              if (status == 'called') ...[
                ElevatedButton.icon(
                  onPressed: _startConsultation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorTokens.careGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Consultation', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _updateStatus('no_show'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorTokens.error,
                    side: const BorderSide(color: ColorTokens.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Mark Patient as No-Show'),
                ),
              ],

              if (status == 'in_consultation')
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/doctor/consultation',
                      arguments: {
                        'appointmentId': apptId,
                        'patientId': _appt!['patient_id'],
                        'patientName': patientName,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.medical_services_outlined),
                  label: const Text('Resume Active Consultation', style: TextStyle(fontWeight: FontWeight.w700)),
                ),

              if (status == 'pending' || status == 'confirmed') ...[
                OutlinedButton(
                  onPressed: () => _updateStatus('cancelled'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorTokens.error,
                    side: const BorderSide(color: ColorTokens.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel Appointment'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: ColorTokens.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'checked_in':
      case 'waiting':
      case 'called':
        return ColorTokens.warning;
      case 'in_consultation':
      case 'completed':
        return ColorTokens.careGreen;
      case 'cancelled':
      case 'no_show':
        return ColorTokens.error;
      default:
        return ColorTokens.primaryBlue;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'checked_in':
      case 'waiting':
      case 'called':
        return ColorTokens.warning.withValues(alpha: 0.15);
      case 'in_consultation':
      case 'completed':
        return ColorTokens.lightGreen;
      case 'cancelled':
      case 'no_show':
        return ColorTokens.error.withValues(alpha: 0.12);
      default:
        return ColorTokens.lightBlue;
    }
  }
}
