import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reports')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          'Appointments Report',
          'Revenue Report',
          'Patient Report',
          'Doctor Performance',
          'Service-wise Report',
          'Follow-up Report',
          'Inventory Report',
          'Custom Report',
        ])
          Card(
            child: ListTile(
              leading: const Icon(Icons.description),
              title: Text(x),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    ),
  );
}
