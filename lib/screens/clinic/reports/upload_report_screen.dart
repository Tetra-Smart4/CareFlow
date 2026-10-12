// Removed dart:convert
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/clinic_repository.dart';
import '../../../repositories/report_repository.dart';
import 'package:file_picker/file_picker.dart';

class UploadReportScreen extends StatefulWidget {
  final String? initialPatientId;
  final String? initialPatientName;

  const UploadReportScreen({
    super.key,
    this.initialPatientId,
    this.initialPatientName,
  });

  @override
  State<UploadReportScreen> createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends State<UploadReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reportRepo = ReportRepository();
  final _clinicRepo = ClinicRepository();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedReportType = 'Laboratory Report';
  DateTime _selectedDate = DateTime.now();

  String? _selectedPatientId;
  List<Map<String, dynamic>> _patients = [];
  bool _loadingPatients = true;

  Uint8List? _fileBytes;
  String? _fileName;
  bool _isUploading = false;
  String? _errorMessage;

  final List<String> _reportTypes = const [
    'Laboratory Report',
    'Imaging Report (X-Ray / MRI / CT / Ultrasound)',
    'Diagnostic Test Report',
    'Consultation Summary',
    'Referral Letter',
    'Vaccination Record',
    'Pathology Report',
    'Clinical Note / Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.initialPatientId;
    _loadClinicPatients();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      if (args['patientId'] != null) _selectedPatientId = args['patientId'].toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadClinicPatients() async {
    setState(() => _loadingPatients = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final clinicId = await _clinicRepo.getCurrentUserClinicId() ?? user?.id;

      if (clinicId != null) {
        // Query appointments for clinic to find authorized patients
        final appts = await Supabase.instance.client
            .from('careflow_appointments')
            .select('patient_id')
            .eq('clinic_id', clinicId);

        final pIds = (appts as List)
            .map((e) => e['patient_id']?.toString())
            .whereType<String>()
            .toSet()
            .toList();

        if (pIds.isNotEmpty) {
          final profiles = await Supabase.instance.client
              .from('profiles')
              .select('id, full_name, phone')
              .inFilter('id', pIds);

          _patients = List<Map<String, dynamic>>.from(profiles);
        } else {
          // Fallback to all patients if clinic has not had appointments yet
          final profiles = await Supabase.instance.client
              .from('profiles')
              .select('id, full_name, phone')
              .eq('role', 'patient')
              .limit(50);
          _patients = List<Map<String, dynamic>>.from(profiles);
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingPatients = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      setState(() {
        _fileBytes = bytes;
        _fileName = result.name;
      });
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient for this report.'),
          backgroundColor: ColorTokens.warning,
        ),
      );
      return;
    }

    if (_fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PDF document.'),
          backgroundColor: ColorTokens.warning,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final clinicId = await _clinicRepo.getCurrentUserClinicId() ?? user?.id;

      await _reportRepo.uploadAndCreateReport(
        patientId: _selectedPatientId!,
        title: _titleController.text.trim(),
        reportType: _selectedReportType,
        reportDate: _selectedDate.toIso8601String().split('T').first,
        description: _descriptionController.text.trim(),
        clinicId: clinicId,
        fileBytes: _fileBytes!,
        fileName: _fileName ?? 'clinical_report.txt',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report uploaded successfully! Patient notified.'),
            backgroundColor: ColorTokens.careGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Failed to upload report: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upload Patient Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorTokens.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColorTokens.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: ColorTokens.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_errorMessage!, style: const TextStyle(color: ColorTokens.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Patient Selection Card
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
                    children: [
                      const Text(
                        'Select Patient *',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                      ),
                      const SizedBox(height: 8),
                      if (_loadingPatients)
                        const LinearProgressIndicator()
                      else if (_patients.isEmpty)
                        const Text('No patients registered under this clinic.', style: TextStyle(color: ColorTokens.muted, fontSize: 13))
                      else
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPatientId,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColorTokens.border)),
                          ),
                          hint: const Text('Choose a patient'),
                          items: _patients.map((p) {
                            final name = p['full_name'] ?? 'Patient';
                            final phone = p['phone'] ?? '';
                            return DropdownMenuItem<String>(
                              value: p['id'].toString(),
                              child: Text(phone.isNotEmpty ? '$name ($phone)' : name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedPatientId = val;
                            });
                          },
                          validator: (val) => val == null ? 'Please select a patient' : null,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Report Details Card
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
                    children: [
                      const Text(
                        'Report Metadata',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      const Text('Report Title *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration('e.g. Complete Blood Count (CBC)'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please enter report title' : null,
                      ),
                      const SizedBox(height: 14),

                      // Report Type
                      const Text('Report Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedReportType,
                        decoration: _inputDecoration(''),
                        items: _reportTypes
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedReportType = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Date
                      const Text('Report Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ColorTokens.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate.toIso8601String().split('T').first,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: ColorTokens.darkNavy),
                              ),
                              const Icon(Icons.calendar_today_rounded, size: 18, color: ColorTokens.primaryBlue),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Description
                      const Text('Description / Clinical Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: _inputDecoration('Key findings, reference ranges, or lab notes...'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Document / File Attachment Card
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
                    children: [
                      const Text(
                        'File Attachment',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickFile,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ColorTokens.lightBlue,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ColorTokens.primaryBlue.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_upload_outlined, size: 36, color: ColorTokens.primaryBlue),
                              const SizedBox(height: 8),
                              Text(
                                _fileName != null ? 'Selected: $_fileName' : 'Tap to select PDF document',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _fileName != null
                                    ? '${(_fileBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB'
                                    : 'Upload a .pdf file',
                                style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Upload Button
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _handleUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: Text(
                  _isUploading ? 'Uploading to Supabase Storage...' : 'Upload & Notify Patient',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorTokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorTokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorTokens.primaryBlue, width: 1.5),
      ),
    );
  }
}
