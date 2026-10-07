import 'package:flutter/material.dart';

class DoctorMedicalHistoryScreen extends StatelessWidget {
  const DoctorMedicalHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Patient Medical History')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          ('15 Sep 2024', 'Viral Fever', 'Dr. Priya Sharma'),
          ('12 Jun 2024', 'Follow-up', 'Dr. Priya Sharma'),
          ('5 Apr 2024', 'Blood Test Review', 'Dr. Priya Sharma'),
        ])
          Card(
            child: ListTile(
              leading: const Icon(Icons.description),
              title: Text(x.$2),
              subtitle: Text('${x.$1} • ${x.$3}'),
              trailing: const Text('View'),
            ),
          ),
      ],
    ),
  );
}
