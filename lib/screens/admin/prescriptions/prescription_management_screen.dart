import 'package:flutter/material.dart';

class PrescriptionManagementScreen extends StatelessWidget {
  const PrescriptionManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Prescription Management')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Review prescription records',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...[
          'Rahul Kumar • 15 Sep 2024 • 3 medicines',
          'Amit Kumar • 12 Jun 2024 • 2 medicines',
          'Sneha Verma • 4 Apr 2024 • 4 medicines',
        ].map(
          (x) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(x),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    ),
  );
}
