import 'package:flutter/material.dart';

class PatientHistoryScreen extends StatelessWidget {
  const PatientHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Patient History')),
    body: ListView( 
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          '15 Sep 2024 • Viral Fever • Dr. Priya Sharma',
          '12 Jun 2024 • Follow-up • Dr. Priya Sharma',
          '5 Apr 2024 • Blood Test Review • Dr. Priya Sharma',
        ])
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(x),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    ),
  );
}
