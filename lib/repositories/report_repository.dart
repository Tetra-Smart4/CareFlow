import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';

class ReportRepository {
  SupabaseClient get client => Supabase.instance.client;

  static const String bucketName = 'careflow-reports';

  Future<List<Report>> listForPatient(String patientId) async {
    try {
      final data = await client
          .from('careflow_reports')
          .select()
          .eq('patient_id', patientId)
          .order('report_date', ascending: false);

      final reports = (data as List).map((json) => Report.fromJson(json)).toList();
      return await _injectSignedUrls(reports);
    } catch (_) {
      return [];
    }
  }

  Future<List<Report>> listForClinic(String clinicId) async {
    try {
      final data = await client
          .from('careflow_reports')
          .select()
          .eq('clinic_id', clinicId)
          .order('report_date', ascending: false);

      final reports = (data as List).map((json) => Report.fromJson(json)).toList();
      return await _injectSignedUrls(reports);
    } catch (_) {
      return [];
    }
  }

  /// Fetch reports for a doctor.
  Future<List<Report>> listForDoctor(String doctorId) async {
    try {
      final data = await client
          .from('careflow_reports')
          .select()
          .eq('doctor_id', doctorId)
          .order('report_date', ascending: false);

      final reports = (data as List).map((json) => Report.fromJson(json)).toList();
      return await _injectSignedUrls(reports);
    } catch (_) {
      return [];
    }
  }

  Future<List<Report>> _injectSignedUrls(List<Report> reports) async {
    // In a real app, you might want to fetch signed URLs on-demand to avoid excessive API calls.
    // However, to enforce secure private access immediately, we'll generate them for the list.
    for (var r in reports) {
      if (r.storagePath != null && r.storagePath!.isNotEmpty) {
        try {
          r.fileUrl = await client.storage.from(bucketName).createSignedUrl(r.storagePath!, 3600);
        } catch (_) {}
      }
    }
    return reports;
  }

  Future<String?> refreshSignedUrl(String storagePath) async {
    try {
      return await client.storage.from(bucketName).createSignedUrl(storagePath, 3600);
    } catch (_) {
      return null;
    }
  }

  /// Upload file binary to Supabase Storage and create metadata record in database.
  Future<Report> uploadAndCreateReport({
    required String patientId,
    required String title,
    required String reportType,
    required String reportDate,
    String? description,
    String? clinicId,
    String? doctorId,
    String? appointmentId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'patient_$patientId/${timestamp}_$cleanFileName';

    // 1. Upload to Supabase Storage bucket
    try {
      await client.storage.from(bucketName).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );
    } catch (e) {
      // If bucket upload fails, we still allow record creation with a placeholder URL if offline
      // But let's get the public URL if possible
    }

    String fileUrl = '';
    try {
      fileUrl = await client.storage.from(bucketName).createSignedUrl(storagePath, 3600);
    } catch (_) {
      fileUrl = storagePath;
    }

    final fileSizeKb = '${(fileBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB';

    // 2. Insert metadata record into careflow_reports
    final inserted = await client
        .from('careflow_reports')
        .insert({
          'patient_id': patientId,
          if (clinicId != null && clinicId.isNotEmpty) 'clinic_id': clinicId,
          if (doctorId != null && doctorId.isNotEmpty) 'doctor_id': doctorId,
          if (appointmentId != null && appointmentId.isNotEmpty) 'appointment_id': appointmentId,
          'title': title,
          'report_type': reportType,
          'report_date': reportDate,
          if (description != null && description.isNotEmpty) 'description': description,
          'file_url': fileUrl,
          'storage_path': storagePath,
          'file_name': cleanFileName,
          'file_size': fileSizeKb,
        })
        .select()
        .single();

    // 3. Notify the patient
    try {
      await client.from('careflow_notifications').insert({
        'user_id': patientId,
        'title': 'New Medical Report Available',
        'body': 'Your $reportType ("$title") has been uploaded to your health records.',
        'type': 'report',
        'is_read': false,
      });
    } catch (_) {}

    return Report.fromJson(inserted);
  }
}
