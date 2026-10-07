import 'package:flutter/material.dart';

class FollowUpManagementScreen extends StatelessWidget {
  const FollowUpManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Follow-up Management')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Pending and completed follow-ups',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...[
          'Rahul Kumar • 21 Oct 2024 • Pending',
          'Sneha Verma • 15 Oct 2024 • Pending',
          'Rajesh Mehta • 20 Oct 2024 • Completed',
          'Pooja Singh • 20 Oct 2024 • Pending',
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
