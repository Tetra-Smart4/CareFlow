class MedicalRecord {
  final String id;
  final String date;
  final String title;
  final String doctorName;
  final String diagnosis;
  final String notes;
  final String? symptoms;
  final String? appointmentId;

  const MedicalRecord({
    required this.id,
    required this.date,
    required this.title,
    required this.doctorName,
    required this.diagnosis,
    required this.notes,
    this.symptoms,
    this.appointmentId,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    final doctorInfo = json['doctors'] ?? json['profiles'];
    final docName = (json['doctor_name'] ??
            (doctorInfo is Map ? doctorInfo['full_name'] : null) ??
            'Doctor')
        .toString();

    final createdAt = json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null;
    final dateStr = (json['date'] ??
            (createdAt != null ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' : 'Recent'))
        .toString();

    final diag = (json['diagnosis'] ?? 'Clinical Consultation').toString();

    return MedicalRecord(
      id: (json['id'] ?? '').toString(),
      date: dateStr,
      title: (json['title'] ?? diag).toString(),
      doctorName: docName,
      diagnosis: diag,
      notes: (json['notes'] ?? '').toString(),
      symptoms: json['symptoms']?.toString(),
      appointmentId: json['appointment_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'doctor_name': doctorName,
      'diagnosis': diagnosis,
      'notes': notes,
      if (symptoms != null) 'symptoms': symptoms,
      if (appointmentId != null) 'appointment_id': appointmentId,
    };
  }
}
