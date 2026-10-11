import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../models/medication_adherence.dart';
import '../../../repositories/medication_adherence_repository.dart';
import '../../../repositories/family_access_repository.dart';
import 'package:careflow/widgets/common/lottie_animation.dart';

class MedicationReminderScreen extends StatefulWidget {
  const MedicationReminderScreen({super.key});

  @override
  State<MedicationReminderScreen> createState() => _MedicationReminderScreenState();
}

class _MedicationReminderScreenState extends State<MedicationReminderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repository = MedicationAdherenceRepository();
  final _familyRepo = FamilyAccessRepository();

  bool _loading = true;
  String? _error;
  List<MedicationAdherence> _todayDoses = [];
  List<MedicationAdherence> _historyDoses = [];
  List<Map<String, dynamic>> _consents = [];
  List<Map<String, dynamic>> _familyLinks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Please log in to view medication schedule.');

      final today = await _repository.getTodayDoses(user.id);
      final history = await _repository.getDoseHistory(user.id);
      final consents = await _repository.getConsents(user.id);
      final familyLinks = await _familyRepo.getLinkedPatients(user.id);

      if (mounted) {
        setState(() {
          _todayDoses = today;
          _historyDoses = history;
          _consents = consents;
          _familyLinks = familyLinks;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleConfirmTaken(MedicationAdherence dose) async {
    final scaffold = ScaffoldMessenger.of(context);
    final res = await _repository.confirmDoseTaken(dose.id);
    if (res['success'] == true) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Dose confirmed as taken! Caregiver alert resolved.'),
          backgroundColor: ColorTokens.careGreen,
        ),
      );
      _loadData();
    } else {
      scaffold.showSnackBar(
        SnackBar(
          content: Text(res['error']?.toString() ?? 'Failed to confirm dose.'),
          backgroundColor: ColorTokens.error,
        ),
      );
    }
  }

  Future<void> _handleReportNotTaken(MedicationAdherence dose) async {
    final reasonCtrl = TextEditingController();
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Dose Not Taken', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explicitly reporting not taken will notify your authorized family caregiver immediately.',
              style: TextStyle(color: ColorTokens.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                hintText: 'e.g. Side effects, missed meal, physician advised pause',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorTokens.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldProceed == true && mounted) {
      final scaffold = ScaffoldMessenger.of(context);
      final res = await _repository.reportDoseNotTaken(dose.id, reason: reasonCtrl.text.trim());
      if (res['success'] == true) {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Status saved. Caregiver alert initiated per protocol.'),
            backgroundColor: ColorTokens.warning,
          ),
        );
        _loadData();
      } else {
        scaffold.showSnackBar(
          SnackBar(content: Text(res['error']?.toString() ?? 'Failed to report dose.')),
        );
      }
    }
  }

  Color _getStatusColor(MedicationDoseStatus status) {
    switch (status) {
      case MedicationDoseStatus.taken:
        return ColorTokens.careGreen;
      case MedicationDoseStatus.notTaken:
        return ColorTokens.error;
      case MedicationDoseStatus.unconfirmed:
        return const Color(0xFFD97706); // Warm Amber
      case MedicationDoseStatus.scheduled:
        return ColorTokens.primaryBlue;
      case MedicationDoseStatus.missed:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Medication & Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _loadData,
            tooltip: 'Refresh Doses',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorTokens.primaryBlue,
          unselectedLabelColor: ColorTokens.textSecondary,
          indicatorColor: ColorTokens.primaryBlue,
          tabs: const [
            Tab(text: "Today's Doses"),
            Tab(text: 'History'),
            Tab(text: 'Caregiver Alerts'),
          ],
        ),
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
                        ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTodayTab(),
                    _buildHistoryTab(),
                    _buildConsentTab(),
                  ],
                ),
    );
  }

  Widget _buildTodayTab() {
    if (_todayDoses.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 60),
            LottieAnimation(
              assetName: 'assets/animations/empty.json',
              width: 130,
              fallback: Icon(Icons.check_circle_outline, size: 64, color: ColorTokens.careGreen),
            ),
            SizedBox(height: 16),
            Text(
              'No Doses Due Today',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
            ),
            SizedBox(height: 8),
            Text(
              'You are all caught up! Prescribed medications will appear here with scheduled administration times.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColorTokens.textSecondary),
            ),
          ],
        ),
      );
    }

    final takenCount = _todayDoses.where((d) => d.status == MedicationDoseStatus.taken).length;
    final totalCount = _todayDoses.length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Today's Adherence Summary Card
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
                    radius: 24,
                    backgroundColor: ColorTokens.lightBlue,
                    child: Icon(Icons.medication, color: ColorTokens.primaryBlue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$takenCount of $totalCount Doses Completed',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ColorTokens.darkNavy),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalCount > 0 ? (takenCount / totalCount) : 0,
                            backgroundColor: ColorTokens.border,
                            color: ColorTokens.careGreen,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._todayDoses.map((dose) => _buildDoseCard(dose)),
        ],
      ),
    );
  }

  Widget _buildDoseCard(MedicationAdherence dose) {
    final statusColor = _getStatusColor(dose.status);
    final dt = dose.scheduledTime;
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final isDone = dose.status == MedicationDoseStatus.taken || dose.status == MedicationDoseStatus.notTaken;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dose.status == MedicationDoseStatus.unconfirmed ? const Color(0xFFF59E0B) : ColorTokens.border, width: dose.status == MedicationDoseStatus.unconfirmed ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorTokens.lightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timeStr,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.primaryBlue, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dose.medicineName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ColorTokens.darkNavy),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dose.status.displayName,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (dose.dosage != null && dose.dosage!.isNotEmpty)
              Text('Dosage: ${dose.dosage}', style: const TextStyle(fontSize: 13, color: ColorTokens.textSecondary)),
            if (dose.instructions != null && dose.instructions!.isNotEmpty)
              Text('Instructions: ${dose.instructions}', style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
            if (dose.status == MedicationDoseStatus.unconfirmed) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Scheduled time reached. Caregiver escalation initiated.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(dose.status == MedicationDoseStatus.taken ? 'Taken' : 'Confirm Taken'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dose.status == MedicationDoseStatus.taken ? ColorTokens.careGreen : ColorTokens.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isDone ? null : () => _handleConfirmTaken(dose),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(dose.status == MedicationDoseStatus.notTaken ? 'Reported' : 'Not Taken'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorTokens.error,
                      side: const BorderSide(color: ColorTokens.error),
                    ),
                    onPressed: isDone ? null : () => _handleReportNotTaken(dose),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_historyDoses.isEmpty) {
      return const Center(child: Text('No historical dose records yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyDoses.length,
      itemBuilder: (ctx, i) {
        final d = _historyDoses[i];
        final color = _getStatusColor(d.status);
        final dt = d.scheduledTime;
        final dateStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: ColorTokens.border),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withAlpha(26),
              child: Icon(
                d.status == MedicationDoseStatus.taken ? Icons.check : Icons.medication,
                color: color,
              ),
            ),
            title: Text(d.medicineName, style: const TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
            subtitle: Text('Scheduled: $dateStr\nStatus: ${d.status.displayName}', style: const TextStyle(fontSize: 12)),
            trailing: d.takenAt != null
                ? const Icon(Icons.done_all, color: ColorTokens.careGreen, size: 18)
                : null,
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildConsentTab() {
    final familyConsent = _consents.firstWhere(
      (c) => c['contact_type'] == 'family_account',
      orElse: () => {'medication_alert_permission': true},
    )['medication_alert_permission'] != false;

    final emergencyConsent = _consents.firstWhere(
      (c) => c['contact_type'] == 'emergency_contact',
      orElse: () => {'medication_alert_permission': true},
    )['medication_alert_permission'] != false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ColorTokens.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Zero-Grace Caregiver Escalation Protocol',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ColorTokens.darkNavy),
                ),
                SizedBox(height: 8),
                Text(
                  'When a scheduled dose reaches its administration time without confirmation, or when explicitly reported as Not taken, CareFlow immediately alerts your authorized caregiver and emergency contacts to ensure patient safety.',
                  style: TextStyle(fontSize: 13, color: ColorTokens.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Medication Alert Authorization',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ColorTokens.navy),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: ColorTokens.border),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Authorized Family Account Escalation', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Allow ${_familyLinks.isNotEmpty ? "${_familyLinks.length} linked family accounts" : "registered family accounts"} to receive unconfirmed dose alerts'),
                value: familyConsent,
                onChanged: (val) async {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    await _repository.setConsent(
                      patientId: user.id,
                      contactType: 'family_account',
                      familyUserId: user.id,
                      granted: val,
                    );
                    _loadData();
                  }
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Emergency Contact Notification', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Dispatch medication escalation via SMS/email to emergency contact when configured'),
                value: emergencyConsent,
                onChanged: (val) async {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    await _repository.setConsent(
                      patientId: user.id,
                      contactType: 'emergency_contact',
                      granted: val,
                    );
                    _loadData();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
