import 'package:flutter/material.dart';

class MedicalRecordsScreen extends StatelessWidget {
  const MedicalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medical Records')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _record(
            context,
            '15 Sep 2024',
            'General Checkup',
            'Dr. Priya Sharma',
          ),
          _record(context, '10 Aug 2024', 'Fever & Cold', 'Dr. Amit Kumar'),
          _record(context, '12 Jun 2024', 'Follow-up', 'Dr. Priya Sharma'),
          _record(
            context,
            '5 Apr 2024',
            'Blood Test Review',
            'Dr. Priya Sharma',
          ),
        ],
      ),
    );
  }

  Widget _record(
    BuildContext context,
    String date,
    String title,
    String doctor,
  ) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.description)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$date • $doctor'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, '/patient/records/detail'),
      ),
    );
  }
}
