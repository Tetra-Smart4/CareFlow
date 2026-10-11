class EmergencyContact {
  final String id;
  final String patientId;
  final String name;
  final String phone;
  final String relationship;
  final DateTime? createdAt;

  const EmergencyContact({
    required this.id,
    required this.patientId,
    required this.name,
    required this.phone,
    required this.relationship,
    this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: (json['id'] ?? '').toString(),
      patientId: (json['patient_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      relationship: (json['relationship'] ?? 'Other').toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
  }

  EmergencyContact copyWith({
    String? id,
    String? patientId,
    String? name,
    String? phone,
    String? relationship,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
