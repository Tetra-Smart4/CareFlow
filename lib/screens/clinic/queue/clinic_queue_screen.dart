import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/clinic_repository.dart';
import '../../../repositories/queue_repository.dart';
import '../../../services/realtime_service.dart';
import 'scanner_screen.dart';

class ClinicQueueScreen extends StatefulWidget {
  final String? clinicId;

  const ClinicQueueScreen({super.key, this.clinicId});

  @override
  State<ClinicQueueScreen> createState() => _ClinicQueueScreenState();
}

class _ClinicQueueScreenState extends State<ClinicQueueScreen> {
  final _queueRepo = QueueRepository();
  final _clinicRepo = ClinicRepository();
  final _realtimeService = RealtimeService();

  bool _loading = true;
  String? _error;
  String? _clinicId;
  int _nowServing = 0;
  int _currentToken = 0;
  List<Map<String, dynamic>> _queueList = [];

  StreamSubscription? _queueSub;
  StreamSubscription? _apptSub;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _queueSub?.cancel();
    _apptSub?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final cid = widget.clinicId ?? await _clinicRepo.getCurrentUserClinicId() ?? user?.id;
      _clinicId = cid;

      if (cid != null) {
        await _fetchQueue(cid);

        _queueSub?.cancel();
        _queueSub = _realtimeService.watchLiveQueue(clinicId: cid).listen((event) {
          final newNow = (event['now_serving'] as num?)?.toInt();
          if (newNow != null && mounted) {
            setState(() => _nowServing = newNow);
          }
        });

        _apptSub?.cancel();
        _apptSub = _realtimeService.watchAppointments(clinicId: cid).listen((_) {
          _refreshQueueOnly(cid);
        });
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Unable to load clinic queue.';
      });
    }
  }

  Future<void> _fetchQueue(String cid) async {
    final counter = await _queueRepo.getCounter(cid);
    final items = await _queueRepo.list(clinicId: cid);

    if (mounted) {
      setState(() {
        _nowServing = (counter['now_serving'] as num?)?.toInt() ?? 0;
        _currentToken = (counter['current_token'] as num?)?.toInt() ?? 0;
        _queueList = items;
      });
    }
  }

  Future<void> _refreshQueueOnly(String cid) async {
    try {
      final items = await _queueRepo.list(clinicId: cid);
      final counter = await _queueRepo.getCounter(cid);
      if (mounted) {
        setState(() {
          _queueList = items;
          _nowServing = (counter['now_serving'] as num?)?.toInt() ?? _nowServing;
          _currentToken = (counter['current_token'] as num?)?.toInt() ?? _currentToken;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleCallNext() async {
    if (_clinicId == null) return;
    try {
      final res = await _queueRepo.callNext(_clinicId!);
      final newNow = (res['now_serving'] as num?)?.toInt();
      if (newNow != null) {
        setState(() => _nowServing = newNow);
      }
      await _refreshQueueOnly(_clinicId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Called token #$_nowServing. Patient notified.'),
            backgroundColor: ColorTokens.careGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to call next patient.'),
            backgroundColor: ColorTokens.error,
          ),
        );
      }
    }
  }

  Future<void> _handleScanQR() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );
    
    if (scannedCode != null && scannedCode.isNotEmpty && _clinicId != null) {
      setState(() => _loading = true);
      try {
        final res = await _queueRepo.checkIn(
          {'appointment_id': scannedCode, 'clinic_id': _clinicId},
        );
        if (res['success'] == true) {
          final token = res['token_number'] ?? 'N/A';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Patient Checked In! Token: #$token'), backgroundColor: ColorTokens.careGreen),
            );
          }
          await _refreshQueueOnly(_clinicId!);
        } else {
          final msg = res['message'] ?? 'Check-in failed.';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: ColorTokens.error),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error validating QR: $e'), backgroundColor: ColorTokens.error),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }
  }

  Future<void> _updateStatus(String appointmentId, String status) async {
    try {
      await _queueRepo.updateStatus(appointmentId, status);
      if (_clinicId != null) {
        await _refreshQueueOnly(_clinicId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment marked as $status.'),
            backgroundColor: ColorTokens.primaryBlue,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update queue item status.'),
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
        title: const Text('Live Clinic Queue'),
        actions: [
          IconButton(
            onPressed: () {
              if (_clinicId != null) _fetchQueue(_clinicId!);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
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
                      ElevatedButton(
                        onPressed: _initData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    if (_clinicId != null) await _fetchQueue(_clinicId!);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildControlCard(),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Waiting Queue',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: ColorTokens.navy,
                            ),
                          ),
                          Text(
                            '${_queueList.length} waiting',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ColorTokens.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_queueList.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            child: Column(
                              children: const [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 48,
                                  color: ColorTokens.careGreen,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Queue is Clear',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: ColorTokens.navy,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'No patients currently waiting in queue.',
                                  style: TextStyle(color: ColorTokens.muted),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._queueList.map(_buildQueueItem),
                    ],
                  ),
                ),
    );
  }

  Widget _buildControlCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Now Serving',
                        style: TextStyle(fontSize: 12, color: ColorTokens.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _nowServing > 0 ? '#$_nowServing' : '--',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: ColorTokens.careGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: ColorTokens.border),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Token Issued',
                        style: TextStyle(fontSize: 12, color: ColorTokens.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentToken > 0 ? '#$_currentToken' : '--',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: ColorTokens.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _handleCallNext,
                icon: const Icon(Icons.campaign_rounded),
                label: const Text(
                  'Call Next Patient',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _handleScanQR,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text(
                  'Scan Patient QR',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueItem(Map<String, dynamic> item) {
    final token = (item['token_number'] as num?)?.toInt() ?? 0;
    final patientName = item['patient_name'] ?? 'Patient';
    final doctorName = item['doctor_name'] ?? 'Doctor';
    final status = item['status']?.toString() ?? 'checked_in';
    final apptId = item['id'].toString();
    final isServing = token == _nowServing || status == 'in_consultation';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isServing ? ColorTokens.lightGreen : ColorTokens.lightBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#$token',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isServing ? ColorTokens.careGreen : ColorTokens.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: ColorTokens.navy,
                        ),
                      ),
                      Text(
                        'Dr. $doctorName',
                        style: const TextStyle(fontSize: 12, color: ColorTokens.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isServing ? ColorTokens.lightGreen : ColorTokens.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isServing ? 'In Consultation' : 'Waiting',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isServing ? ColorTokens.careGreen : ColorTokens.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isServing)
                  OutlinedButton(
                    onPressed: () => _updateStatus(apptId, 'no_show'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorTokens.error,
                      side: const BorderSide(color: ColorTokens.error),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('No Show'),
                  ),
                const SizedBox(width: 8),
                if (!isServing)
                  ElevatedButton(
                    onPressed: () => _updateStatus(apptId, 'in_consultation'),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Start'),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _updateStatus(apptId, 'completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorTokens.careGreen,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Complete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
