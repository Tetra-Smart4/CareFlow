class Patient {
  final String id;
  final String name;
  final String phone;
  final String gender;
  final String bloodGroup;
  final String? emergencyContact;
  const Patient({
    required this.id,
    required this.name,
    required this.phone,
    required this.gender,
    required this.bloodGroup,
    required this.emergencyContact,
  });
}
