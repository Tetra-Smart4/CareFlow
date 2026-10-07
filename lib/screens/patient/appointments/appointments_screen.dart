import 'package:flutter/material.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Appointments')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Dr. Priya Sharma'),
            subtitle: const Text('General checkup • Today, 10:00 AM'),
            trailing: const Chip(label: Text('Confirmed')),
          ),
        ),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Dr. Amit Kumar'),
            subtitle: const Text('Follow-up • 12 Jun'),
            trailing: const Chip(label: Text('Completed')),
          ),
        ),
      ],
    ),
  );
}
