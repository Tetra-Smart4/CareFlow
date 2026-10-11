class Clinic {
  final String id;
  final String? clinicId;
  final String name;
  final String address;
  final String phone;
  final String workingHours;
  final String status;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime? createdAt;

  const Clinic({
    required this.id,
    this.clinicId,
    required this.name,
    this.address = '',
    this.phone = '',
    this.workingHours = '09:00 AM - 05:00 PM',
    this.status = 'pending',
    this.rejectionReason,
    this.approvedAt,
    this.createdAt,
  });

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isSuspended => status.toLowerCase() == 'suspended';

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: (json['id'] ?? '').toString(),
      clinicId: json['clinic_id']?.toString(),
      name: (json['name'] ?? json['clinic_name'] ?? json['full_name'] ?? 'CareFlow Clinic').toString(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      workingHours: (json['working_hours'] ?? '09:00 AM - 05:00 PM').toString(),
      status: (json['status'] ?? 'pending').toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      approvedAt: json['approved_at'] != null ? DateTime.tryParse(json['approved_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (clinicId != null) 'clinic_id': clinicId,
      'name': name,
      'address': address,
      'phone': phone,
      'status': status,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
    };
  }
}
