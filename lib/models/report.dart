class Report {
  final String id;
  final String patientId;
  final String? clinicId;
  final String? doctorId;
  final String? appointmentId;
  final String title;
  final String reportType;
  final String reportDate;
  final String? description;
  String fileUrl;
  final String? storagePath;
  final String? fileName;
  final String? fileSize;
  final DateTime? createdAt;

  Report({
    required this.id,
    required this.patientId,
    this.clinicId,
    this.doctorId,
    this.appointmentId,
    required this.title,
    required this.reportType,
    required this.reportDate,
    this.description,
    required this.fileUrl,
    this.storagePath,
    this.fileName,
    this.fileSize,
    this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: (json['id'] ?? '').toString(),
      patientId: (json['patient_id'] ?? '').toString(),
      clinicId: json['clinic_id']?.toString(),
      doctorId: json['doctor_id']?.toString(),
      appointmentId: json['appointment_id']?.toString(),
      title: (json['title'] ?? 'Medical Report').toString(),
      reportType: (json['report_type'] ?? 'General Report').toString(),
      reportDate: (json['report_date'] ?? '').toString(),
      description: json['description']?.toString(),
      fileUrl: (json['file_url'] ?? '').toString(),
      storagePath: json['storage_path']?.toString(),
      fileName: json['file_name']?.toString(),
      fileSize: json['file_size']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      if (clinicId != null) 'clinic_id': clinicId,
      if (doctorId != null) 'doctor_id': doctorId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      'title': title,
      'report_type': reportType,
      'report_date': reportDate,
      if (description != null) 'description': description,
      'file_url': fileUrl,
      if (storagePath != null) 'storage_path': storagePath,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
    };
  }
}
