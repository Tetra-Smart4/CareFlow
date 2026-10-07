import 'package:flutter/material.dart';

class DoctorNotificationsScreen extends StatelessWidget {
  const DoctorNotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          'New appointment • Rahul Kumar • 10:00 AM',
          'Lab report uploaded • Rahul Kumar',
          'Follow-up due • Sneha Verma',
          'Prescription request • Rajesh Mehta',
        ])
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_none),
              title: Text(x),
              subtitle: const Text('Recent update'),
            ),
          ),
      ],
    ),
  );
}
