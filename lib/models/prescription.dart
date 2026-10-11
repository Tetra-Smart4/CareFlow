import 'prescription_item.dart';

class Prescription {
  final String id;
  final String date;
  final String doctorName;
  final String? patientId;
  final String? doctorId;
  final List<PrescriptionItem> items;
  final String instructions;
  final DateTime? createdAt;

  const Prescription({
    required this.id,
    required this.date,
    required this.doctorName,
    this.patientId,
    this.doctorId,
    required this.items,
    required this.instructions,
    this.createdAt,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    final doctorInfo = json['doctors'] ?? json['profiles'];
    final docName = (json['doctor_name'] ??
            (doctorInfo is Map ? doctorInfo['full_name'] : null) ??
            'Doctor')
        .toString();

    final List<PrescriptionItem> parsedItems = [];
    if (json['items'] is List) {
      for (final item in json['items']) {
        if (item is Map<String, dynamic>) {
          parsedItems.add(PrescriptionItem.fromJson(item));
        }
      }
    } else if (json['medicine_name'] != null) {
      // Single row format from careflow_prescriptions
      parsedItems.add(PrescriptionItem(
        medicine: json['medicine_name'].toString(),
        dose: (json['dosage'] ?? '').toString(),
        frequency: (json['frequency'] ?? '').toString(),
        duration: (json['duration'] ?? '').toString(),
        instructions: json['instructions']?.toString(),
      ));
    }

    final createdAtDate = json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null;
    final dateStr = (json['date'] ?? (createdAtDate != null ? '${createdAtDate.day}/${createdAtDate.month}/${createdAtDate.year}' : 'Today')).toString();

    return Prescription(
      id: (json['id'] ?? '').toString(),
      date: dateStr,
      doctorName: docName,
      patientId: json['patient_id']?.toString(),
      doctorId: json['doctor_id']?.toString(),
      items: parsedItems,
      instructions: (json['instructions'] ?? '').toString(),
      createdAt: createdAtDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'doctor_name': doctorName,
      if (patientId != null) 'patient_id': patientId,
      if (doctorId != null) 'doctor_id': doctorId,
      'instructions': instructions,
    };
  }
}
