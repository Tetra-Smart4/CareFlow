class Profile {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? gender;
  final int? age;
  final String? address;
  final String? clinicName;
  final String? specialization;
  final String? qualification;
  final int? experience;
  final double? consultationFee;
  final String? registrationNumber;
  final String? bio;
  final String status;
  final DateTime? createdAt;

  const Profile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.gender,
    this.age,
    this.address,
    this.clinicName,
    this.specialization,
    this.qualification,
    this.experience,
    this.consultationFee,
    this.registrationNumber,
    this.bio,
    this.status = 'active',
    this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: (json['id'] ?? '').toString(),
      fullName: (json['full_name'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'patient').toString().toLowerCase(),
      phone: json['phone']?.toString(),
      gender: json['gender']?.toString(),
      age: json['age'] is num ? (json['age'] as num).toInt() : int.tryParse(json['age']?.toString() ?? ''),
      address: json['address']?.toString(),
      clinicName: json['clinic_name']?.toString(),
      specialization: json['specialization']?.toString(),
      qualification: json['qualification']?.toString(),
      experience: json['experience'] is num
          ? (json['experience'] as num).toInt()
          : int.tryParse(json['experience']?.toString() ?? ''),
      consultationFee: json['consultation_fee'] is num
          ? (json['consultation_fee'] as num).toDouble()
          : double.tryParse(json['consultation_fee']?.toString() ?? ''),
      registrationNumber: json['registration_number']?.toString(),
      bio: json['bio']?.toString(),
      status: (json['status'] ?? 'active').toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'phone': phone,
      'gender': gender,
      'age': age,
      'address': address,
      'clinic_name': clinicName,
      'specialization': specialization,
      'qualification': qualification,
      'experience': experience,
      'consultation_fee': consultationFee,
      'registration_number': registrationNumber,
      'bio': bio,
      'status': status,
    };
  }

  Profile copyWith({
    String? fullName,
    String? email,
    String? role,
    String? phone,
    String? gender,
    int? age,
    String? address,
    String? clinicName,
    String? specialization,
    String? qualification,
    int? experience,
    double? consultationFee,
    String? registrationNumber,
    String? bio,
    String? status,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      address: address ?? this.address,
      clinicName: clinicName ?? this.clinicName,
      specialization: specialization ?? this.specialization,
      qualification: qualification ?? this.qualification,
      experience: experience ?? this.experience,
      consultationFee: consultationFee ?? this.consultationFee,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
