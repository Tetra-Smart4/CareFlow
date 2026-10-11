class Appointment {
  final String id;
  final String? clinicId;
  final String? doctorId;
  final String? patientId;
  final String patientName;
  final String doctorName;
  final String? clinicName;
  final String date;
  final String time;
  final String reason;
  final String status;
  final int tokenNumber;
  final DateTime? checkedInAt;
  final DateTime? createdAt;

  const Appointment({
    required this.id,
    this.clinicId,
    this.doctorId,
    this.patientId,
    required this.patientName,
    required this.doctorName,
    this.clinicName,
    required this.date,
    required this.time,
    required this.reason,
    required this.status,
    this.tokenNumber = 0,
    this.checkedInAt,
    this.createdAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isCheckedIn => status.toLowerCase() == 'checked_in' || status.toLowerCase() == 'waiting';
  bool get isInConsultation => status.toLowerCase() == 'in_consultation' || status.toLowerCase() == 'called';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final patientInfo = json['patient'] ?? json['profiles'];
    final doctorInfo = json['doctor'];
    final clinicInfo = json['clinic'];

    return Appointment(
      id: (json['id'] ?? '').toString(),
      clinicId: json['clinic_id']?.toString(),
      doctorId: json['doctor_id']?.toString(),
      patientId: json['patient_id']?.toString(),
      patientName: (json['patient_name'] ??
              (patientInfo is Map ? patientInfo['full_name'] : null) ??
              'Patient')
          .toString(),
      doctorName: (json['doctor_name'] ??
              (doctorInfo is Map ? doctorInfo['full_name'] : null) ??
              'Doctor')
          .toString(),
      clinicName: (json['clinic_name'] ??
              (clinicInfo is Map ? clinicInfo['name'] ?? clinicInfo['clinic_name'] : null))
          ?.toString(),
      date: (json['appointment_date'] ?? json['date'] ?? '').toString(),
      time: (json['appointment_time'] ?? json['time'] ?? '').toString(),
      reason: (json['reason'] ?? 'Consultation').toString(),
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      tokenNumber: json['token_number'] is num
          ? (json['token_number'] as num).toInt()
          : (int.tryParse(json['token_number']?.toString() ?? '') ?? 0),
      checkedInAt: json['checked_in_at'] != null ? DateTime.tryParse(json['checked_in_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (clinicId != null) 'clinic_id': clinicId,
      if (doctorId != null) 'doctor_id': doctorId,
      if (patientId != null) 'patient_id': patientId,
      'appointment_date': date,
      'appointment_time': time,
      'reason': reason,
      'status': status,
      'token_number': tokenNumber,
      if (checkedInAt != null) 'checked_in_at': checkedInAt!.toIso8601String(),
    };
  }
}
