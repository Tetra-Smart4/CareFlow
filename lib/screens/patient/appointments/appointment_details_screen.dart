import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/appointment_repository.dart';
import '../../../services/realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? appointment;

  const AppointmentDetailsScreen({super.key, this.appointment});

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final _appointmentRepo = AppointmentRepository();
  final _realtimeService = RealtimeService();

  Map<String, dynamic>? _appt;
  bool _loading = false;
  bool _generatingQr = false;
  StreamSubscription? _apptSub;

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
      
      _startListening();
    }
  }
  
  void _startListening() {
    if (_appt == null) return;
    
    final apptId = _appt!['id']?.toString();
    if (apptId != null) {
      _apptSub = _realtimeService.watchAppointments().listen((appts) {
        final updated = appts.where((a) => a['id'].toString() == apptId).toList();
        if (updated.isNotEmpty && mounted) {
          final newAppt = updated.first;
          if (newAppt['status'] != _appt!['status']) {
            setState(() {
              _appt = newAppt;
            });
            if (newAppt['status'] == 'checked_in') {
               // Automatically redirect to live queue screen!
               if (Navigator.canPop(context)) {
                 Navigator.pop(context); // close QR dialog if open
               }
               Navigator.pushReplacementNamed(context, '/patient/queue/live');
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _apptSub?.cancel();
    super.dispose();
  }

  Future<void> _handleCancel() async {
    if (_appt == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text('Are you sure you want to cancel this booking? This slot will be released.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorTokens.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final apptId = _appt!['id'].toString();
      await _appointmentRepo.cancel(apptId);
      setState(() {
        _appt!['status'] = 'cancelled';
        _loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment has been cancelled.'), backgroundColor: ColorTokens.error),
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
  Future<void> _ensureQrTokenAndShow(BuildContext context, String clinicName, String doctorName, String date, String time, String status) async {
    final apptId = _appt!['id'].toString();
    
    if (_appt!['qr_token'] == null) {
      setState(() => _generatingQr = true);
      try {
        final res = await Supabase.instance.client.rpc('careflow_generate_qr_token', params: {'p_appointment_id': apptId});
        if (res is Map && res['success'] == true) {
          setState(() {
             _appt!['qr_token'] = res['qr_token'];
          });
        }
      } catch (_) {
        // Fallback or missing RPC handled
      }
      setState(() => _generatingQr = false);
    }
    
    if (!mounted || !context.mounted) return;
    
    if (_appt!['qr_token'] == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Cannot generate QR code. Please try again or contact clinic.'), backgroundColor: ColorTokens.error),
       );
       return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('CareFlow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ColorTokens.primaryBlue)),
              const SizedBox(height: 8),
              const Text('Appointment Confirmed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColorTokens.careGreen)),
              const SizedBox(height: 16),
              QrImageView(
                data: _appt!['qr_token'].toString(),
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 16),
              const Text(
                'Show this QR code to clinic management when you arrive.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: ColorTokens.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildInfoRow('Clinic', clinicName),
              const SizedBox(height: 8),
              _buildInfoRow('Doctor', doctorName),
              const SizedBox(height: 8),
              _buildInfoRow('Date', date),
              const SizedBox(height: 8),
              _buildInfoRow('Time', time),
              const SizedBox(height: 8),
              _buildInfoRow('Status', status.toUpperCase()),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_appt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appointment Details')),
        body: const Center(child: Text('No appointment data received.')),
      );
    }

    final doctorName = _appt!['doctor_name'] ?? 'Doctor';
    final spec = _appt!['doctor_specialization'] ?? 'Specialist';
    final clinicName = _appt!['clinic_name'] ?? 'CareFlow Healthcare';
    final date = _appt!['appointment_date'] ?? 'N/A';
    final time = _appt!['appointment_time'] ?? 'N/A';
    final reason = _appt!['reason'] ?? 'General Consultation';
    final token = _appt!['token_number'] ?? 0;
    final status = (_appt!['status'] ?? 'pending').toString().toLowerCase();

    final isConfirmed = status == 'confirmed';
    final isCheckedIn = status == 'checked_in' || status == 'waiting';
    final isCalled = status == 'called';
    final isCompleted = status == 'completed';
    final isPending = status == 'pending';
    
    final canShowQr = isConfirmed || isCheckedIn || isPending;

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
            // Doctor Card
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
                        doctorName.isNotEmpty ? doctorName[0].toUpperCase() : 'D',
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
                            doctorName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: ColorTokens.darkNavy,
                            ),
                          ),
                          Text(spec, style: const TextStyle(fontSize: 13, color: ColorTokens.textSecondary)),
                          const SizedBox(height: 2),
                          Text(clinicName, style: const TextStyle(fontSize: 12, color: ColorTokens.textMuted)),
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
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _statusColor(status)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Token Banner if in queue
            if (token > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCalled ? ColorTokens.warning.withValues(alpha: 0.15) : ColorTokens.lightBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isCalled ? ColorTokens.warning : ColorTokens.primaryBlue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$token',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isCalled ? ColorTokens.warning : ColorTokens.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCalled ? 'Your Turn to Consult!' : 'Live Queue Token Assigned',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isCalled ? ColorTokens.warning : ColorTokens.darkNavy,
                            ),
                          ),
                          Text(
                            isCalled
                                ? 'The doctor has called you. Please proceed to the room.'
                                : 'You are checked in for today\'s consultation.',
                            style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Appointment Info Card
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
                    _buildInfoRow('Date', date),
                    const Divider(height: 18, color: ColorTokens.border),
                    _buildInfoRow('Time Slot', time),
                    const Divider(height: 18, color: ColorTokens.border),
                    _buildInfoRow('Clinic Location', clinicName),
                    const Divider(height: 18, color: ColorTokens.border),
                    _buildInfoRow('Reason for Visit', reason),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Contextual Actions
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (canShowQr) ...[
                ElevatedButton.icon(
                  onPressed: _generatingQr ? null : () => _ensureQrTokenAndShow(context, clinicName, doctorName, date, time, status),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorTokens.careGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _generatingQr 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(_generatingQr ? 'Generating QR...' : 'Show Check-in QR Code', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
              ],

              if (isCheckedIn || isCalled)
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/patient/queue/live'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.confirmation_number_outlined),
                  label: const Text('View Live Queue Screen', style: TextStyle(fontWeight: FontWeight.w700)),
                ),

              if (isCompleted)
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/patient/records'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.folder_shared_outlined),
                  label: const Text('View Consultation Summary in Health', style: TextStyle(fontWeight: FontWeight.w700)),
                ),

              if (status == 'pending' || status == 'confirmed') ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _handleCancel,
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
