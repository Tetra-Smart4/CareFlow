import 'package:flutter/material.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Profile')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const CircleAvatar(
          radius: 38,
          child: Text('R', style: TextStyle(fontSize: 30)),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Rahul Kumar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 18),
        for (final x in [
          'Personal Information',
          'Emergency Contact',
          'Health Information',
          'Change Password',
          'Notifications',
          'Help & Support',
        ])
          Card(
            child: ListTile(
              title: Text(x),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        TextButton(
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/auth/login'),
          child: const Text('Logout', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
