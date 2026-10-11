class FollowUp {
  final String id;
  final String patientName;
  final String date;
  final String reason;
  final String priority;
  final String status;
  final String? doctorId;
  final String? patientId;
  final String? appointmentId;

  const FollowUp({
    required this.id,
    required this.patientName,
    required this.date,
    required this.reason,
    required this.priority,
    required this.status,
    this.doctorId,
    this.patientId,
    this.appointmentId,
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    final patientInfo = json['patients'] ?? json['profiles'];
    final pName = (json['patient_name'] ??
            (patientInfo is Map ? patientInfo['full_name'] : null) ??
            'Patient')
        .toString();

    final dateStr = (json['followup_date'] ?? json['date'] ?? '').toString();

    return FollowUp(
      id: (json['id'] ?? '').toString(),
      patientName: pName,
      date: dateStr,
      reason: (json['notes'] ?? json['reason'] ?? 'Follow-up consultation').toString(),
      priority: (json['priority'] ?? 'Standard').toString(),
      status: (json['status'] ?? 'pending').toString(),
      doctorId: json['doctor_id']?.toString(),
      patientId: json['patient_id']?.toString(),
      appointmentId: json['appointment_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (doctorId != null) 'doctor_id': doctorId,
      if (patientId != null) 'patient_id': patientId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      'followup_date': date,
      'notes': reason,
      'status': status,
    };
  }
}
