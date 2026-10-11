// Removed dart:typed_data
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../models/report.dart';
import '../../../repositories/report_repository.dart';
import 'package:file_picker/file_picker.dart';

class PatientReportsScreen extends StatefulWidget {
  const PatientReportsScreen({super.key});

  @override
  State<PatientReportsScreen> createState() => _PatientReportsScreenState();
}

class _PatientReportsScreenState extends State<PatientReportsScreen> {
  final _reportRepo = ReportRepository();

  bool _loading = true;
  String? _errorMessage;
  List<Report> _reports = [];

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
      if (user == null) {
        setState(() {
          _loading = false;
          _reports = [];
        });
        return;
      }

      final list = await _reportRepo.listForPatient(user.id);

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
          _errorMessage = 'Failed to load medical reports: $e';
        });
      }
    }
  }

  Future<void> _uploadExternalRecord() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    final bytes = await result.readAsBytes();

    setState(() => _loading = true);
    try {
      await _reportRepo.uploadAndCreateReport(
        patientId: user.id,
        title: result.name,
        reportType: 'External',
        reportDate: DateTime.now().toIso8601String().split('T').first,
        description: 'Patient uploaded external health record.',
        fileBytes: bytes,
        fileName: result.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record uploaded successfully')));
        _loadReports();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Medical Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: ColorTokens.error),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: const TextStyle(color: ColorTokens.muted)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadReports, child: const Text('Retry')),
                    ],
                  ),
                )
              : _reports.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.description_outlined, size: 48, color: ColorTokens.muted),
                            SizedBox(height: 14),
                            Text(
                              'No Reports Available',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: ColorTokens.darkNavy,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Diagnostic reports and lab investigations uploaded by your clinic will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: ColorTokens.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        itemBuilder: (ctx, i) {
                          final r = _reports[i];
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
                                            Text(
                                              r.reportType,
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
                                          // Always fetch a fresh signed URL in case the old one expired
                                          final freshUrl = await _reportRepo.refreshSignedUrl(r.storagePath!);
                                          if (freshUrl != null && context.mounted) {
                                            Navigator.pushNamed(context, '/shared/pdf', arguments: {
                                              'url': freshUrl,
                                              'title': r.title,
                                            });
                                          } else if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load document URL')));
                                          }
                                        },
                                        icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                                        label: const Text('View Document'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadExternalRecord,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Record'),
      ),
    );
  }
}
