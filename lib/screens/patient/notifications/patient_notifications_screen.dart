import 'package:flutter/material.dart';

class PatientNotificationsScreen extends StatelessWidget {
  const PatientNotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          (
            'Appointment Confirmed',
            'Your appointment with Dr. Priya Sharma is confirmed.',
          ),
          ('Medication Reminder', 'Time to take Paracetamol 500 mg.'),
          ('Prescription Available', 'Your prescription is ready to view.'),
          ('Follow-up Reminder', 'Your follow-up is due on 21 Oct 2024.'),
        ])
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.notifications_none),
              ),
              title: Text(
                x.$1,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(x.$2),
            ),
          ),
      ],
    ),
  );
}
