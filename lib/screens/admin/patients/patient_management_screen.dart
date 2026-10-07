import 'package:flutter/material.dart';

class PatientManagementScreen extends StatelessWidget {
  const PatientManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Patient Management')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Search and manage patient records',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...[
          'Rahul Kumar • +91 98765 43210 • Active',
          'Sneha Verma • +91 98765 432109 • Active',
          'Rajesh Mehta • +91 98765 432109 • Follow-up',
          'Pooja Singh • +91 98765 432109 • Active',
          'Suresh Nair • +91 98765 432109 • Active',
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
