import 'package:flutter/material.dart';

class MedicationHistoryScreen extends StatelessWidget {
  const MedicationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _dose('8:00 AM', 'Paracetamol 500 mg', 'Taken'),
          _dose('1:00 PM', 'Paracetamol 500 mg', 'Taken'),
          _dose('8:00 PM', 'Paracetamol 500 mg', 'Missed'),
        ],
      ),
    );
  }

  Widget _dose(String time, String medicine, String status) {
    final missed = status == 'Missed';
    return Card(
      child: ListTile(
        leading: Icon(
          missed ? Icons.cancel : Icons.check_circle,
          color: missed ? Colors.red : Colors.green,
        ),
        title: Text(medicine),
        subtitle: Text(time),
        trailing: Text(status),
      ),
    );
  }
}
