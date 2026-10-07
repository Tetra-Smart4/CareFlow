import 'package:flutter/material.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const CircleAvatar(
          radius: 38,
          child: Text('A', style: TextStyle(fontSize: 30)),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Admin User',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        const Center(child: Text('Clinic Administrator')),
        const SizedBox(height: 18),
        for (final x in [
          'Personal Information',
          'Change Password',
          'Notification Preferences',
          'App Settings',
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
