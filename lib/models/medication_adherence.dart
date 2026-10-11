enum MedicationDoseStatus {
  scheduled,
  taken,
  notTaken,
  unconfirmed,
  missed;

  static MedicationDoseStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'taken':
        return MedicationDoseStatus.taken;
      case 'not_taken':
        return MedicationDoseStatus.notTaken;
      case 'unconfirmed':
        return MedicationDoseStatus.unconfirmed;
      case 'missed':
        return MedicationDoseStatus.missed;
      case 'scheduled':
      default:
        return MedicationDoseStatus.scheduled;
    }
  }

  String toDbString() {
    switch (this) {
      case MedicationDoseStatus.taken:
        return 'taken';
      case MedicationDoseStatus.notTaken:
        return 'not_taken';
      case MedicationDoseStatus.unconfirmed:
        return 'unconfirmed';
      case MedicationDoseStatus.missed:
        return 'missed';
      case MedicationDoseStatus.scheduled:
        return 'scheduled';
    }
  }

  String get displayName {
    switch (this) {
      case MedicationDoseStatus.taken:
        return 'Taken';
      case MedicationDoseStatus.notTaken:
        return 'Not Taken';
      case MedicationDoseStatus.unconfirmed:
        return 'Due / Unconfirmed';
      case MedicationDoseStatus.missed:
        return 'Missed';
      case MedicationDoseStatus.scheduled:
        return 'Scheduled';
    }
  }
}

class MedicationAdherence {
  final String id;
  final String patientId;
  final String? prescriptionId;
  final String medicineName;
  final String? dosage;
  final String? instructions;
  final MedicationDoseStatus status;
  final DateTime scheduledTime;
  final DateTime? takenAt;
  final DateTime? reportedAt;
  final String? patientNotes;
  final String? escalationStatus;
  final DateTime? createdAt;

  const MedicationAdherence({
    required this.id,
    required this.patientId,
    this.prescriptionId,
    required this.medicineName,
    this.dosage,
    this.instructions,
    required this.status,
    required this.scheduledTime,
    this.takenAt,
    this.reportedAt,
    this.patientNotes,
    this.escalationStatus,
    this.createdAt,
  });

  factory MedicationAdherence.fromJson(Map<String, dynamic> json) {
    return MedicationAdherence(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      prescriptionId: json['prescription_id']?.toString(),
      medicineName: json['medicine_name']?.toString() ?? 'Medicine',
      dosage: json['dosage']?.toString(),
      instructions: json['instructions']?.toString(),
      status: MedicationDoseStatus.fromString(json['status']?.toString()),
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'].toString()).toLocal()
          : DateTime.now(),
      takenAt: json['taken_at'] != null
          ? DateTime.tryParse(json['taken_at'].toString())?.toLocal()
          : null,
      reportedAt: json['reported_at'] != null
          ? DateTime.tryParse(json['reported_at'].toString())?.toLocal()
          : null,
      patientNotes: json['patient_notes']?.toString(),
      escalationStatus: json['escalation_status']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'prescription_id': prescriptionId,
      'medicine_name': medicineName,
      'dosage': dosage,
      'instructions': instructions,
      'status': status.toDbString(),
      'scheduled_time': scheduledTime.toUtc().toIso8601String(),
      'taken_at': takenAt?.toUtc().toIso8601String(),
      'reported_at': reportedAt?.toUtc().toIso8601String(),
      'patient_notes': patientNotes,
      'escalation_status': escalationStatus,
    };
  }
}
