import 'package:flutter/material.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Clinic-wide alerts', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        ...[
          'New appointment • Rahul Kumar',
          'Payment received • Amit Kumar',
          'Follow-up due • Sneha Verma',
          'Appointment cancelled • Rajesh Mehta',
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
