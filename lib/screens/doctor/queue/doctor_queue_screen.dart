import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/queue_repository.dart';
import '../../../services/realtime_service.dart';

class DoctorQueueScreen extends StatefulWidget {
  final String? doctorId;

  const DoctorQueueScreen({super.key, this.doctorId});

  @override
  State<DoctorQueueScreen> createState() => _DoctorQueueScreenState();
}

class _DoctorQueueScreenState extends State<DoctorQueueScreen> {
  final _queueRepo = QueueRepository();
  final _realtimeService = RealtimeService();

  bool _loading = true;
  bool _actionLoading = false;
  String? _error;
  String? _doctorId;
  List<Map<String, dynamic>> _allAppointments = [];
  StreamSubscription? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _loadQueue() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final docId = widget.doctorId ?? user?.id;
      _doctorId = docId;

      if (docId != null) {
        await _fetchData(docId);

        _realtimeSub?.cancel();
        _realtimeSub = _realtimeService.watchAppointments(doctorId: docId).listen((_) {
          if (mounted) _fetchData(docId);
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load doctor queue. Please try again.';
        });
      }
    }
  }

  Future<void> _fetchData(String docId) async {
    try {
      // Query all appointments for this doctor for today/active queue
      final data = await Supabase.instance.client
          .from('careflow_appointments')
          .select()
          .eq('doctor_id', docId)
          .order('token_number', ascending: true);

      final list = List<Map<String, dynamic>>.from(data);

      // Attach patient details
      final userIds = list
          .map((e) => e['patient_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      if (userIds.isNotEmpty) {
        final profiles = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name, phone, gender, age')
            .inFilter('id', userIds);

        final pMap = <String, Map<String, dynamic>>{};
        for (final p in profiles) {
          pMap[p['id'].toString()] = p;
        }

        for (final appt in list) {
          final pId = appt['patient_id']?.toString();
          if (pId != null && pMap.containsKey(pId)) {
            appt['patient_name'] = pMap[pId]!['full_name'];
            appt['patient_phone'] = pMap[pId]!['phone'];
            appt['patient_gender'] = pMap[pId]!['gender'];
            appt['patient_age'] = pMap[pId]!['age'];
          }
        }
      }

      if (mounted) {
        setState(() {
          _allAppointments = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _waitingPatients => _allAppointments
      .where((a) =>
          a['status'] == 'checked_in' ||
          a['status'] == 'waiting')
      .toList();

  Map<String, dynamic>? get _inConsultationPatient => _allAppointments
      .cast<Map<String, dynamic>?>()
      .firstWhere((a) => a?['status'] == 'in_consultation', orElse: () => null);

  int get _completedCount =>
      _allAppointments.where((a) => a['status'] == 'completed').length;

  Future<void> _callNextPatient() async {
    if (_doctorId == null || _actionLoading) return;

    if (_inConsultationPatient != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete current consultation before calling next patient.'),
          backgroundColor: ColorTokens.warning,
        ),
      );
      return;
    }

    setState(() => _actionLoading = true);

    try {
      final res = await _queueRepo.doctorCallNext(_doctorId!);
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient #${res['token_number']} called!'),
            backgroundColor: ColorTokens.careGreen,
          ),
        );
        _openConsultationScreen({
          'id': res['appointment_id'],
          'patient_id': res['patient_id'],
          'patient_name': _allAppointments.firstWhere((a) => a['id'] == res['appointment_id'], orElse: () => {})['patient_name'] ?? 'Patient',
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'No waiting patients found.'),
            backgroundColor: ColorTokens.warning,
          ),
        );
      }
      await _fetchData(_doctorId!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to call next patient: $e'),
          backgroundColor: ColorTokens.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }



  Future<void> _markNoShow(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Patient as No-Show?'),
        content: const Text('This will remove the patient from today\'s active queue. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorTokens.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark No-Show'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _actionLoading = true);
    try {
      await _queueRepo.updateStatus(appointmentId, 'no_show');
      if (_doctorId != null) await _fetchData(_doctorId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient marked as no-show.'),
            backgroundColor: ColorTokens.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _openConsultationScreen(Map<String, dynamic> appt) {
    Navigator.pushNamed(
      context,
      '/doctor/consultation',
      arguments: {
        'appointmentId': appt['id'],
        'patientId': appt['patient_id'],
        'patientName': appt['patient_name'] ?? 'Patient',
      },
    ).then((_) {
      if (_doctorId != null) _fetchData(_doctorId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Queue Management'),
        actions: [
          IconButton(
            onPressed: () {
              if (_doctorId != null) _fetchData(_doctorId!);
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Queue',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: ColorTokens.error),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: ColorTokens.muted)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadQueue,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    if (_doctorId != null) await _fetchData(_doctorId!);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 1. TOP STATISTICS ROW
                      _buildQueueStatsRow(),
                      const SizedBox(height: 16),

                      // 2. CALL NEXT PATIENT PRIMARY ACTION
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          key: const Key('call_next_patient_button'),
                          onPressed: _actionLoading ? null : _callNextPatient,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _actionLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.campaign_rounded, size: 22),
                          label: Text(
                            _actionLoading ? 'Processing...' : 'Call Next Patient',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),



                      // 4. IN CONSULTATION PATIENT SECTION
                      if (_inConsultationPatient != null) ...[
                        const Text(
                          'In Consultation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ColorTokens.careGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInConsultationCard(_inConsultationPatient!),
                        const SizedBox(height: 20),
                      ],

                      // 5. WAITING LIST SECTION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Waiting Queue',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: ColorTokens.darkNavy,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ColorTokens.lightBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_waitingPatients.length} Waiting',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ColorTokens.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_waitingPatients.isEmpty)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: ColorTokens.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                            child: Column(
                              children: const [
                                Icon(
                                  Icons.how_to_reg_rounded,
                                  size: 44,
                                  color: ColorTokens.careGreen,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No Patients Waiting',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: ColorTokens.darkNavy,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Checked-in patients will appear here in queue order.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: ColorTokens.muted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._waitingPatients.map(_buildWaitingPatientCard),
                    ],
                  ),
                ),
    );
  }

  Widget _buildQueueStatsRow() {
    return Row(
      children: [
        _buildStatTile(
          label: 'Waiting',
          count: _waitingPatients.length,
          color: ColorTokens.warning,
          bg: ColorTokens.warning.withValues(alpha: 0.1),
        ),
        const SizedBox(width: 8),
        _buildStatTile(
          label: 'In Consult',
          count: _inConsultationPatient != null ? 1 : 0,
          color: ColorTokens.careGreen,
          bg: ColorTokens.lightGreen,
        ),
        const SizedBox(width: 8),
        _buildStatTile(
          label: 'Completed',
          count: _completedCount,
          color: ColorTokens.textSecondary,
          bg: ColorTokens.border.withValues(alpha: 0.4),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String label,
    required int count,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildInConsultationCard(Map<String, dynamic> appt) {
    final token = (appt['token_number'] as num?)?.toInt() ?? 0;
    final patientName = appt['patient_name'] ?? 'Patient';
    final reason = appt['reason'] ?? 'Consultation';
    final gender = appt['patient_gender'] ?? '';
    final age = appt['patient_age']?.toString() ?? '';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ColorTokens.careGreen, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: ColorTokens.lightGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#$token',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: ColorTokens.careGreen,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ColorTokens.darkNavy,
                        ),
                      ),
                      Text(
                        [if (age.isNotEmpty) '$age yrs', if (gender.isNotEmpty) gender, reason]
                            .join(' • '),
                        style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _actionLoading ? null : () => _markNoShow(appt['id'].toString()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorTokens.error,
                      side: const BorderSide(color: ColorTokens.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Mark No-Show'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _openConsultationScreen(appt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.medical_services_outlined, size: 18),
                    label: const Text('Consultation'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingPatientCard(Map<String, dynamic> appt) {
    final token = (appt['token_number'] as num?)?.toInt() ?? 0;
    final patientName = appt['patient_name'] ?? 'Patient';
    final reason = appt['reason'] ?? 'Consultation';
    final time = appt['appointment_time'] ?? '';

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: ColorTokens.border),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ColorTokens.lightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '#$token',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: ColorTokens.primaryBlue,
            ),
          ),
        ),
        title: Text(
          patientName,
          style: const TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
        ),
        subtitle: Text('Slot: $time • $reason', style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ColorTokens.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Waiting',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ColorTokens.warning),
          ),
        ),
      ),
    );
  }
}
