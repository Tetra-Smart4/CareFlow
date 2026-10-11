import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../models/report.dart';
import '../../../repositories/medical_record_repository.dart';
import '../../../repositories/prescription_repository.dart';
import '../../../repositories/report_repository.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? patient;

  const PatientDetailsScreen({super.key, this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _recordRepo = MedicalRecordRepository();
  final _prescRepo = PrescriptionRepository();
  final _reportRepo = ReportRepository();

  Map<String, dynamic>? _patient;
  bool _loading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _consultations = [];
  List<Map<String, dynamic>> _prescriptions = [];
  List<Report> _reports = [];
  List<Map<String, dynamic>> _followUps = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_patient == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _patient = args;
        _loadPatientHistory();
      } else if (widget.patient != null) {
        _patient = widget.patient;
        _loadPatientHistory();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientHistory() async {
    if (_patient == null) return;
    final patientId = _patient!['id']?.toString();
    if (patientId == null) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 1. Consultations
      final consults = await _recordRepo.list(patientId: patientId);

      // 2. Prescriptions
      final prescs = await _prescRepo.list(patientId: patientId);

      // 3. Reports
      final reports = await _reportRepo.listForPatient(patientId);

      // 4. Follow-ups
      final fData = await Supabase.instance.client
          .from('careflow_followups')
          .select()
          .eq('patient_id', patientId)
          .order('followup_date', ascending: false);

      if (mounted) {
        setState(() {
          _consultations = consults;
          _prescriptions = prescs;
          _reports = reports;
          _followUps = List<Map<String, dynamic>>.from(fData);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load patient history: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Details')),
        body: const Center(child: Text('No patient selected.')),
      );
    }

    final name = _patient!['full_name'] ?? 'Patient';
    final pId = _patient!['id']?.toString() ?? '';
    final phone = _patient!['phone'] ?? 'Not provided';
    final age = _patient!['age']?.toString();
    final gender = _patient!['gender']?.toString();
    final address = _patient!['address'] ?? _patient!['city'] ?? 'Location not provided';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(name),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: ColorTokens.textSecondary,
          indicatorColor: AppColors.primaryBlue,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Timeline'),
            Tab(text: 'Consultations'),
            Tab(text: 'Prescriptions'),
            Tab(text: 'Reports'),
            Tab(text: 'Follow-ups'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Basic Patient Profile Card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: ColorTokens.lightBlue,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'P',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ColorTokens.primaryBlue),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy)),
                      Text('ID: $pId', style: const TextStyle(fontSize: 11, color: ColorTokens.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        [?age != null ? '$age yrs' : null, ?gender, phone, address]
                            .join(' • '),
                        style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 40, color: ColorTokens.error),
                            const SizedBox(height: 8),
                            Text(_errorMessage!, style: const TextStyle(color: ColorTokens.muted)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _loadPatientHistory, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTimelineTab(),
                          _buildConsultationsTab(),
                          _buildPrescriptionsTab(),
                          _buildReportsTab(),
                          _buildFollowUpsTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    List<Map<String, dynamic>> events = [];
    
    for (var c in _consultations) {
      final dateStr = c['created_at']?.toString() ?? c['consultation_date']?.toString() ?? '';
      events.add({
        'type': 'consultation',
        'date': DateTime.tryParse(dateStr) ?? DateTime.now(),
        'title': c['diagnosis'] ?? 'Consultation',
        'subtitle': 'Symptoms: ${c['symptoms'] ?? 'None'}',
        'icon': Icons.medical_information_outlined,
        'color': ColorTokens.primaryBlue,
      });
    }
    
    for (var p in _prescriptions) {
      final dateStr = p['created_at']?.toString() ?? '';
      events.add({
        'type': 'prescription',
        'date': DateTime.tryParse(dateStr) ?? DateTime.now(),
        'title': 'Prescription: ${p['medicine_name']}',
        'subtitle': '${p['dosage']} • ${p['frequency']}',
        'icon': Icons.medication_outlined,
        'color': ColorTokens.careGreen,
      });
    }
    
    for (var r in _reports) {
      events.add({
        'type': 'report',
        'date': DateTime.tryParse(r.reportDate) ?? DateTime.now(),
        'title': r.title,
        'subtitle': r.reportType,
        'icon': Icons.description_outlined,
        'color': Colors.orange,
      });
    }

    events.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (events.isEmpty) {
      return _buildEmptyState('No Timeline Events', 'Patient timeline will appear here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (ctx, i) {
        final e = events[i];
        final dt = e['date'] as DateTime;
        final dateStr = "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}";
        
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ColorTokens.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: (e['color'] as Color).withAlpha(26),
              child: Icon(e['icon'] as IconData, color: e['color'] as Color),
            ),
            title: Text(e['title'], style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.darkNavy)),
            subtitle: Text('$dateStr\n${e['subtitle']}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildConsultationsTab() {
    if (_consultations.isEmpty) {
      return _buildEmptyState('No Previous Consultations', 'Completed clinical encounter records will appear here.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _consultations.length,
      itemBuilder: (ctx, i) {
        final c = _consultations[i];
        final diagnosis = c['diagnosis'] ?? 'Clinical Consultation';
        final symptoms = c['symptoms'] ?? '';
        final notes = c['notes'] ?? '';
        final date = c['created_at'] != null ? c['created_at'].toString().split('T').first : '';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ColorTokens.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      diagnosis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                    ),
                    Text(date, style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
                  ],
                ),
                if (symptoms.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Symptoms: $symptoms', style: const TextStyle(fontSize: 13, color: ColorTokens.textSecondary)),
                ],
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      notes,
                      style: const TextStyle(fontSize: 12, color: ColorTokens.darkNavy),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionsTab() {
    if (_prescriptions.isEmpty) {
      return _buildEmptyState('No Prescriptions on Record', 'Prescribed medicines for this patient will appear here.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _prescriptions.length,
      itemBuilder: (ctx, i) {
        final p = _prescriptions[i];
        final med = p['medicine_name'] ?? 'Medicine';
        final dosage = p['dosage'] ?? '';
        final freq = p['frequency'] ?? '';
        final instructions = p['instructions'] ?? '';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: ColorTokens.border),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: ColorTokens.lightGreen,
              child: Icon(Icons.medication_outlined, color: ColorTokens.careGreen),
            ),
            title: Text(med, style: const TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
            subtitle: Text(
              [if (dosage.isNotEmpty) dosage, if (freq.isNotEmpty) freq, if (instructions.isNotEmpty) instructions].join(' • '),
              style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    if (_reports.isEmpty) {
      return _buildEmptyState('No Diagnostic Reports', 'Reports uploaded by clinic staff or diagnostic labs will appear here.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (ctx, i) {
        final r = _reports[i];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: ColorTokens.border),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: ColorTokens.lightBlue,
              child: Icon(Icons.description_outlined, color: ColorTokens.primaryBlue),
            ),
            title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
            subtitle: Text('${r.reportType} • ${r.reportDate} • ${r.fileSize ?? ""}', style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
            trailing: const Icon(Icons.open_in_new_rounded, size: 20, color: ColorTokens.primaryBlue),
            onTap: () async {
              if (r.storagePath == null) return;
              final freshUrl = await _reportRepo.refreshSignedUrl(r.storagePath!);
              if (freshUrl != null && mounted) {
                Navigator.pushNamed(context, '/shared/pdf', arguments: {'url': freshUrl, 'title': r.title});
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load document URL')));
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildFollowUpsTab() {
    if (_followUps.isEmpty) {
      return _buildEmptyState('No Follow-ups Scheduled', 'Scheduled follow-up reviews will appear here.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _followUps.length,
      itemBuilder: (ctx, i) {
        final f = _followUps[i];
        final date = f['followup_date'] ?? 'N/A';
        final notes = f['notes'] ?? 'Follow-up review';
        final status = f['status'] ?? 'scheduled';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: ColorTokens.border),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: ColorTokens.lightBlue,
              child: Icon(Icons.event_repeat_rounded, color: ColorTokens.primaryBlue),
            ),
            title: Text('Follow-up on $date', style: const TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
            subtitle: Text(notes, style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ColorTokens.lightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ColorTokens.careGreen),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open_outlined, size: 44, color: ColorTokens.muted),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: ColorTokens.muted)),
          ],
        ),
      ),
    );
  }
}
