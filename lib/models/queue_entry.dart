class QueueEntry {
  final String id;
  final String? appointmentId;
  final String? clinicId;
  final String? doctorId;
  final String? patientId;
  final String patientName;
  final String doctorName;
  final int queueNumber;
  final String status;
  final int nowServing;
  final DateTime? createdAt;

  const QueueEntry({
    required this.id,
    this.appointmentId,
    this.clinicId,
    this.doctorId,
    this.patientId,
    required this.patientName,
    required this.doctorName,
    required this.queueNumber,
    required this.status,
    this.nowServing = 0,
    this.createdAt,
  });

  int get patientsAhead => (queueNumber > nowServing) ? (queueNumber - nowServing - 1) : 0;
  bool get isMyTurn => queueNumber == nowServing && nowServing > 0;

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    final patientInfo = json['patients'] ?? json['profiles'];
    final doctorInfo = json['doctors'];

    final token = json['token_number'] ?? json['queue_number'] ?? json['current_token'] ?? 0;
    final tokenInt = token is num ? token.toInt() : (int.tryParse(token.toString()) ?? 0);

    final nowServ = json['now_serving'] ?? 0;
    final nowServingInt = nowServ is num ? nowServ.toInt() : (int.tryParse(nowServ.toString()) ?? 0);

    return QueueEntry(
      id: (json['id'] ?? '').toString(),
      appointmentId: json['appointment_id']?.toString(),
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
      queueNumber: tokenInt,
      status: (json['status'] ?? 'waiting').toString(),
      nowServing: nowServingInt,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (clinicId != null) 'clinic_id': clinicId,
      if (doctorId != null) 'doctor_id': doctorId,
      if (patientId != null) 'patient_id': patientId,
      'token_number': queueNumber,
      'status': status,
      'now_serving': nowServing,
    };
  }
}
