import 'prescription_item.dart';

class Prescription {
  final String id;
  final String date;
  final String doctorName;
  final List<PrescriptionItem> items;
  final String instructions;
  const Prescription({
    required this.id,
    required this.date,
    required this.doctorName,
    required this.items,
    required this.instructions,
  });
}
