import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/medical_record_repository.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final _recordRepo = MedicalRecordRepository();

  bool _loading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _records = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _records = [];
        });
        return;
      }

      final list = await _recordRepo.list(patientId: user.id);

      if (mounted) {
        setState(() {
          _records = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load medical history: $e';
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredRecords {
    if (_searchQuery.trim().isEmpty) return _records;
    final q = _searchQuery.toLowerCase();
    return _records.where((r) {
      final diag = (r['diagnosis'] ?? '').toString().toLowerCase();
      final doc = (r['doctor_name'] ?? '').toString().toLowerCase();
      final notes = (r['notes'] ?? '').toString().toLowerCase();
      return diag.contains(q) || doc.contains(q) || notes.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medical Records & History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRecords,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Permanent Medical History Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorTokens.primaryBlue.withValues(alpha: 0.08), ColorTokens.careGreen.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ColorTokens.primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorTokens.primaryBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_outlined, color: ColorTokens.primaryBlue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Patient Medical Questionnaire',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ColorTokens.darkNavy),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Keep your 20-point medical history up to date for consultations across any CareFlow clinic.',
                        style: TextStyle(fontSize: 11, color: ColorTokens.textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/patient/medical-history/questionnaire');
                  },
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
          // Search box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search consultations, diagnoses, or doctors...',
                prefixIcon: const Icon(Icons.search, size: 20, color: ColorTokens.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColorTokens.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColorTokens.border)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: ColorTokens.error),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: ColorTokens.muted)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadRecords, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _filteredRecords.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.folder_open_rounded, size: 48, color: ColorTokens.muted),
                                  SizedBox(height: 14),
                                  Text(
                                    'No Medical Records Found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: ColorTokens.darkNavy,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Completed consultations and verified doctor clinical notes will appear here automatically.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: ColorTokens.muted, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadRecords,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredRecords.length,
                              itemBuilder: (ctx, i) {
                                final r = _filteredRecords[i];
                                final diagnosis = r['diagnosis'] ?? 'Clinical Encounter';
                                final doc = r['doctor_name'] ?? 'Doctor';
                                final spec = r['doctor_specialization'] ?? 'Physician';
                                final date = r['created_at'] != null ? r['created_at'].toString().split('T').first : 'Recent';

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: ColorTokens.border),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: ColorTokens.lightGreen,
                                      child: const Icon(Icons.medical_information_rounded, color: ColorTokens.careGreen),
                                    ),
                                    title: Text(
                                      diagnosis,
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                                    ),
                                    subtitle: Text(
                                      '$date • $doc ($spec)',
                                      style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                                    ),
                                    trailing: const Icon(Icons.chevron_right_rounded, color: ColorTokens.muted),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/patient/records/detail',
                                        arguments: r,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
