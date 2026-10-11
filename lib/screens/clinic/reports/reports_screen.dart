import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../models/report.dart';
import '../../../repositories/clinic_repository.dart';
import '../../../repositories/report_repository.dart';
import 'upload_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _reportRepo = ReportRepository();
  final _clinicRepo = ClinicRepository();

  bool _loading = true;
  String? _errorMessage;
  List<Report> _reports = [];
  Map<String, String> _patientNames = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final clinicId = await _clinicRepo.getCurrentUserClinicId() ?? user?.id;

      if (clinicId == null) {
        setState(() {
          _loading = false;
          _reports = [];
        });
        return;
      }

      final list = await _reportRepo.listForClinic(clinicId);

      // Fetch patient names
      final patientIds = list.map((r) => r.patientId).toSet().toList();
      if (patientIds.isNotEmpty) {
        final profiles = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', patientIds);

        final pMap = <String, String>{};
        for (final p in profiles) {
          pMap[p['id'].toString()] = p['full_name'] ?? 'Patient';
        }
        _patientNames = pMap;
      }

      if (mounted) {
        setState(() {
          _reports = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load clinic reports: $e';
        });
      }
    }
  }

  List<Report> get _filteredReports {
    if (_searchQuery.trim().isEmpty) return _reports;
    final q = _searchQuery.toLowerCase();
    return _reports.where((r) {
      final pName = (_patientNames[r.patientId] ?? '').toLowerCase();
      final title = r.title.toLowerCase();
      final type = r.reportType.toLowerCase();
      return pName.contains(q) || title.contains(q) || type.contains(q);
    }).toList();
  }

  void _openUploadScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadReportScreen()),
    ).then((result) {
      if (result == true) {
        _loadReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Reports & Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUploadScreen,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Upload Report'),
      ),
      body: Column(
        children: [
          // Search & Action Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by patient, title, or test type...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: ColorTokens.textMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: ColorTokens.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: ColorTokens.border),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ],
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
                              ElevatedButton(
                                onPressed: _loadReports,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredReports.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.description_outlined, size: 48, color: ColorTokens.muted),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'No Patient Reports Uploaded',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: ColorTokens.darkNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Upload diagnostic lab reports, scans, or discharge summaries for clinic patients.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: ColorTokens.muted, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _openUploadScreen,
                                    icon: const Icon(Icons.upload_file_rounded),
                                    label: const Text('Upload First Report'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadReports,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredReports.length,
                              itemBuilder: (ctx, i) {
                                final r = _filteredReports[i];
                                final patientName = _patientNames[r.patientId] ?? 'Patient';

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
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: ColorTokens.lightBlue,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.description_rounded, color: ColorTokens.primaryBlue, size: 24),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    r.title,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w800,
                                                      color: ColorTokens.darkNavy,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Patient: $patientName • ${r.reportType}',
                                                    style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: ColorTokens.lightGreen,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                r.reportDate,
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ColorTokens.careGreen),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (r.description != null && r.description!.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            r.description!,
                                            style: const TextStyle(fontSize: 13, color: ColorTokens.darkNavy),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              r.fileSize ?? 'Document',
                                              style: const TextStyle(fontSize: 11, color: ColorTokens.muted),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: () async {
                                                if (r.storagePath == null) return;
                                                final freshUrl = await _reportRepo.refreshSignedUrl(r.storagePath!);
                                                if (freshUrl != null && context.mounted) {
                                                  Navigator.pushNamed(context, '/shared/pdf', arguments: {'url': freshUrl, 'title': r.title});
                                                } else if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load document URL')));
                                                }
                                              },
                                              icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                                              label: const Text('View File'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: ColorTokens.primaryBlue,
                                                side: const BorderSide(color: ColorTokens.primaryBlue),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
