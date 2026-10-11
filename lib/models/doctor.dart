class Doctor {
  final String id;
  final String? doctorId;
  final String name;
  final String specialization;
  final String? qualification;
  final String experience;
  final double rating;
  final bool available;
  final double? consultationFee;
  final String? clinicId;
  final String? clinicName;
  final String? phone;

  const Doctor({
    required this.id,
    this.doctorId,
    required this.name,
    required this.specialization,
    this.qualification,
    required this.experience,
    this.rating = 4.8,
    required this.available,
    this.consultationFee,
    this.clinicId,
    this.clinicName,
    this.phone,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    final expValue = json['experience'];
    final expStr = expValue is num ? '${expValue.toInt()} yrs' : (expValue?.toString() ?? '5+ yrs');

    return Doctor(
      id: (json['id'] ?? '').toString(),
      doctorId: json['doctor_id']?.toString(),
      name: (json['full_name'] ?? json['name'] ?? 'Doctor').toString(),
      specialization: (json['specialization'] ?? 'General Physician').toString(),
      qualification: json['qualification']?.toString(),
      experience: expStr,
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : 4.8,
      available: json['is_available'] == true || json['available'] == true || json['is_available'] == null,
      consultationFee: json['consultation_fee'] is num
          ? (json['consultation_fee'] as num).toDouble()
          : double.tryParse(json['consultation_fee']?.toString() ?? ''),
      clinicId: json['clinic_id']?.toString(),
      clinicName: json['clinic_name']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (doctorId != null) 'doctor_id': doctorId,
      'name': name,
      'specialization': specialization,
      'qualification': qualification,
      'is_available': available,
      'consultation_fee': consultationFee,
    };
  }
}
