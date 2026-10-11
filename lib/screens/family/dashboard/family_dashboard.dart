import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../models/medication_adherence.dart';
import '../../../repositories/family_access_repository.dart';
import 'package:careflow/widgets/common/lottie_animation.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FamilyDashboard extends StatefulWidget {
  const FamilyDashboard({super.key});

  @override
  State<FamilyDashboard> createState() => _FamilyDashboardState();
}

class _FamilyDashboardState extends State<FamilyDashboard> {
  final _familyRepo = FamilyAccessRepository();
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _linkedPatients = [];
  List<Map<String, dynamic>> _alerts = [];
  List<MedicationAdherence> _selectedPatientDoses = [];
  String? _selectedPatientId;
  String? _selectedPatientName;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Please log in as an authorized family account.');

      final patients = await _familyRepo.getLinkedPatients(user.id);
      final alerts = await _familyRepo.getCaregiverAlerts(user.id);

      List<MedicationAdherence> doses = [];
      String? activePid = _selectedPatientId;
      String? activePname = _selectedPatientName;

      if (patients.isNotEmpty) {
        activePid ??= patients.first['patient_id']?.toString();
        activePname ??= patients.first['patient_name']?.toString() ?? 'Patient';
        if (activePid != null) {
          doses = await _familyRepo.getPatientAdherence(activePid);
        }
      }

      if (mounted) {
        setState(() {
          _linkedPatients = patients;
          _alerts = alerts;
          _selectedPatientId = activePid;
          _selectedPatientName = activePname;
          _selectedPatientDoses = doses;
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

  Future<void> _selectPatient(String patientId, String patientName) async {
    setState(() {
      _selectedPatientId = patientId;
      _selectedPatientName = patientName;
    });
    try {
      final doses = await _familyRepo.getPatientAdherence(patientId);
      if (mounted) {
        setState(() => _selectedPatientDoses = doses);
      }
    } catch (_) {}
  }

  void _showCallPatientDialog(String patientName, String? phone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.phone_in_talk, color: ColorTokens.careGreen),
            SizedBox(width: 8),
            Text('Contact Patient', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Direct Caregiver Communication for $patientName:', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ColorTokens.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: ColorTokens.primaryBlue),
                  const SizedBox(width: 10),
                  Text(
                    phone != null && phone.isNotEmpty ? phone : '+1 (555) 234-5678',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ColorTokens.darkNavy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'A prompt phone check-in ensures the patient received their medication and is feeling well.',
              style: TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: ColorTokens.careGreen),
            icon: const Icon(Icons.call, color: Colors.white, size: 18),
            label: const Text('Call Now', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dialing ${phone ?? "Patient"}...'),
                  backgroundColor: ColorTokens.careGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Family Caregiver Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _loadDashboard,
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
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: ColorTokens.muted)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadDashboard, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Active Urgent Alerts Section
                      if (_alerts.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.notification_important, color: ColorTokens.error, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Unconfirmed Dose Alerts (${_alerts.length})',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ColorTokens.darkNavy),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ..._alerts.map((alert) => _buildAlertCard(alert)),
                        const SizedBox(height: 20),
                      ],

                      // Linked Patients Section
                      const Text(
                        'Authorized Linked Patients',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ColorTokens.navy),
                      ),
                      const SizedBox(height: 10),
                      if (_linkedPatients.isEmpty)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: ColorTokens.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: const [
                                LottieAnimation(
                                  assetName: 'assets/animations/empty.json',
                                  width: 100,
                                  fallback: Icon(Icons.family_restroom, size: 48, color: ColorTokens.muted),
                                ),
                                SizedBox(height: 10),
                                Text('No linked patients found', style: TextStyle(fontWeight: FontWeight.w700)),
                                SizedBox(height: 4),
                                Text(
                                  'Linked patients with granted medication alert consent will appear here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: ColorTokens.muted),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _linkedPatients.length,
                            itemBuilder: (ctx, i) {
                              final p = _linkedPatients[i];
                              final pid = p['patient_id'].toString();
                              final pname = p['patient_name']?.toString() ?? 'Patient';
                              final isSelected = pid == _selectedPatientId;

                              return GestureDetector(
                                onTap: () => _selectPatient(pid, pname),
                                child: Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? ColorTokens.lightBlue : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? ColorTokens.primaryBlue : ColorTokens.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isSelected ? ColorTokens.primaryBlue : ColorTokens.border,
                                        child: Text(
                                          pname.isNotEmpty ? pname[0] : 'P',
                                          style: TextStyle(color: isSelected ? Colors.white : ColorTokens.darkNavy, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(pname, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: ColorTokens.darkNavy), maxLines: 1),
                                            Text(p['relationship']?.toString().toUpperCase() ?? 'CARE', style: const TextStyle(fontSize: 11, color: ColorTokens.textSecondary)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Medication Adherence Stream for Selected Patient
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$_selectedPatientName\'s Adherence',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ColorTokens.navy),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.phone, size: 16, color: ColorTokens.careGreen),
                              label: const Text('Call Patient', style: TextStyle(color: ColorTokens.careGreen, fontWeight: FontWeight.w700)),
                              onPressed: () {
                                final p = _linkedPatients.firstWhere((element) => element['patient_id'] == _selectedPatientId, orElse: () => {});
                                _showCallPatientDialog(_selectedPatientName ?? 'Patient', p['patient_phone']?.toString());
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_selectedPatientDoses.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No medication adherence records found for this patient.'),
                            ),
                          )
                        else
                          ..._selectedPatientDoses.map((d) => _buildDoseItem(d)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final title = alert['title']?.toString() ?? 'Medicine dose not confirmed';
    final body = alert['body']?.toString() ?? '';
    final dose = alert['dose'] as Map<String, dynamic>?;
    final medName = dose?['medicine_name'] ?? 'Prescribed Medicine';
    final schedTime = dose?['scheduled_time'] != null ? DateTime.tryParse(dose!['scheduled_time'])?.toLocal() : null;
    final timeStr = schedTime != null ? '${schedTime.hour.toString().padLeft(2, '0')}:${schedTime.minute.toString().padLeft(2, '0')}' : 'Due time';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ColorTokens.error, width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: ColorTokens.error,
                  child: Icon(Icons.priority_high, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ColorTokens.darkNavy)),
                      Text('$medName • Scheduled: $timeStr • Zero-Grace Escalation', style: const TextStyle(fontSize: 12, color: ColorTokens.error, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(body, style: const TextStyle(fontSize: 13, color: ColorTokens.darkNavy)),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorTokens.careGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('Call Patient Now'),
                  onPressed: () {
                    final p = _linkedPatients.firstWhere((element) => element['patient_id'] == _selectedPatientId, orElse: () => {});
                    _showCallPatientDialog(_selectedPatientName ?? 'Patient', p['patient_phone']?.toString());
                  },
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _loadDashboard(),
                  child: const Text('Refresh Status'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().shake(duration: 400.ms);
  }

  Widget _buildDoseItem(MedicationAdherence dose) {
    Color statusColor = ColorTokens.primaryBlue;
    if (dose.status == MedicationDoseStatus.taken) statusColor = ColorTokens.careGreen;
    if (dose.status == MedicationDoseStatus.notTaken) statusColor = ColorTokens.error;
    if (dose.status == MedicationDoseStatus.unconfirmed) statusColor = const Color(0xFFD97706);

    final dt = dose.scheduledTime;
    final timeStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ColorTokens.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withAlpha(26),
          child: Icon(
            dose.status == MedicationDoseStatus.taken ? Icons.check : Icons.medication,
            color: statusColor,
          ),
        ),
        title: Text(dose.medicineName, style: const TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
        subtitle: Text('Scheduled: $timeStr\nStatus: ${dose.status.displayName}', style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(26),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            dose.status.displayName.toUpperCase(),
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}
