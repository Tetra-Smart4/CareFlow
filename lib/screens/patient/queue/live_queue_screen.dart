import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/appointment_repository.dart';
import '../../../repositories/queue_repository.dart';
import '../../../services/realtime_service.dart';

class LiveQueueScreen extends StatefulWidget {
  final String? appointmentId;
  final String? clinicId;

  const LiveQueueScreen({
    super.key,
    this.appointmentId,
    this.clinicId,
  });

  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen> {
  final _appointmentRepo = AppointmentRepository();
  final _queueRepo = QueueRepository();
  final _realtimeService = RealtimeService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _appointment;
  int _tokenNumber = 0;
  int _nowServing = 0;
  String _doctorName = 'Doctor';
  String _clinicName = 'Clinic';
  String? _clinicId;

  StreamSubscription? _queueSub;

  @override
  void initState() {
    super.initState();
    _loadQueueData();
  }

  @override
  void dispose() {
    _queueSub?.cancel();
    super.dispose();
  }

  Future<void> _loadQueueData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'Please sign in to view your queue status.';
        });
        return;
      }

      Map<String, dynamic>? activeAppt;

      if (widget.appointmentId != null) {
        activeAppt = await _appointmentRepo.getById(widget.appointmentId!);
      } else {
        // Query current patient's active checked-in or waiting appointments
        final appts = await _appointmentRepo.list(
          patientId: user.id,
          status: 'checked_in',
        );

        if (appts.isNotEmpty) {
          activeAppt = appts.first;
        } else {
          // Check for in_consultation as well
          final inConsult = await _appointmentRepo.list(
            patientId: user.id,
            status: 'in_consultation',
          );
          if (inConsult.isNotEmpty) {
            activeAppt = inConsult.first;
          }
        }
      }

      if (activeAppt == null) {
        setState(() {
          _loading = false;
          _appointment = null;
        });
        return;
      }

      _appointment = activeAppt;
      _tokenNumber = (activeAppt['token_number'] as num?)?.toInt() ?? 1;
      _clinicId = widget.clinicId ?? activeAppt['clinic_id']?.toString();
      _doctorName = activeAppt['doctor_name'] ?? 'Doctor';
      _clinicName = activeAppt['clinic_name'] ?? 'Clinic';

      if (_clinicId != null) {
        final counter = await _queueRepo.getCounter(_clinicId!);
        _nowServing = (counter['now_serving'] as num?)?.toInt() ?? 0;

        _queueSub?.cancel();
        _queueSub = _realtimeService.watchLiveQueue(clinicId: _clinicId!).listen((event) {
          final newNow = (event['now_serving'] as num?)?.toInt();
          if (newNow != null && mounted) {
            setState(() {
              _nowServing = newNow;
            });
          }
        });
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load queue status. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Live Queue'),
        actions: [
          IconButton(
            onPressed: _loadQueueData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
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
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: ColorTokens.muted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadQueueData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _appointment == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.confirmation_number_outlined,
                              size: 56,
                              color: ColorTokens.muted,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No Active Queue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: ColorTokens.navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'You have not checked in to any appointment yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: ColorTokens.muted),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/patient/appointments'),
                              child: const Text('View Appointments'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadQueueData,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildLiveQueueCard(),
                          const SizedBox(height: 16),
                          _buildDoctorCard(),
                          const SizedBox(height: 16),
                          _buildInstructionsCard(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildLiveQueueCard() {
    final ahead = (_tokenNumber - _nowServing).clamp(0, 999);
    final isMyTurn = _tokenNumber == _nowServing;
    final isCalled = _tokenNumber <= _nowServing;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: ColorTokens.careGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'REAL-TIME LIVE QUEUE',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: ColorTokens.careGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Token Number',
              style: TextStyle(fontSize: 13, color: ColorTokens.muted),
            ),
            const SizedBox(height: 4),
            Text(
              '#$_tokenNumber',
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: ColorTokens.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMyTurn
                    ? ColorTokens.lightGreen
                    : ColorTokens.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMyTurn ? Icons.check_circle_rounded : Icons.info_outline,
                    size: 18,
                    color: isMyTurn ? ColorTokens.careGreen : ColorTokens.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMyTurn
                        ? "It's your turn! Please enter."
                        : isCalled
                            ? 'Now in consultation'
                            : 'Now Serving: #$_nowServing',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isMyTurn ? ColorTokens.careGreen : ColorTokens.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!isCalled)
              Text(
                '$ahead ${ahead == 1 ? "patient" : "patients"} ahead of you',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ColorTokens.navy,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ColorTokens.lightBlue,
          child: const Icon(Icons.medical_services_outlined, color: ColorTokens.primaryBlue),
        ),
        title: Text(
          _doctorName,
          style: const TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.navy),
        ),
        subtitle: Text(
          _clinicName,
          style: const TextStyle(color: ColorTokens.muted),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: ColorTokens.lightGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Checked In',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ColorTokens.careGreen,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Queue Guidelines',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: ColorTokens.navy,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• Please stay nearby the consultation room when there are 2 or fewer patients ahead.',
              style: TextStyle(fontSize: 12, color: ColorTokens.muted, height: 1.4),
            ),
            SizedBox(height: 4),
            Text(
              '• Your screen updates in real-time as the clinic calls each patient.',
              style: TextStyle(fontSize: 12, color: ColorTokens.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
