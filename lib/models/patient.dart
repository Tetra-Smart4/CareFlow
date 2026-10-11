class Patient {
  final String id;
  final String name;
  final String phone;
  final String gender;
  final String bloodGroup;
  final int? age;
  final String? emergencyContact;
  final DateTime? createdAt;

  const Patient({
    required this.id,
    required this.name,
    required this.phone,
    this.gender = 'Not Specified',
    this.bloodGroup = 'Unknown',
    this.age,
    this.emergencyContact,
    this.createdAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: (json['id'] ?? '').toString(),
      name: (json['full_name'] ?? json['name'] ?? 'Patient').toString(),
      phone: (json['phone'] ?? '').toString(),
      gender: (json['gender'] ?? 'Not Specified').toString(),
      bloodGroup: (json['blood_group'] ?? 'Unknown').toString(),
      age: json['age'] is num ? (json['age'] as num).toInt() : int.tryParse(json['age']?.toString() ?? ''),
      emergencyContact: json['emergency_contact']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'gender': gender,
      'blood_group': bloodGroup,
      if (age != null) 'age': age,
      if (emergencyContact != null) 'emergency_contact': emergencyContact,
    };
  }
}
