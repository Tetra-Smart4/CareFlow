import 'package:flutter/material.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Profile & Availability')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const CircleAvatar(radius: 38, child: Icon(Icons.person, size: 38)),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Dr. Priya Sharma',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        const Center(child: Text('General Physician • ★ 4.8')),
        const SizedBox(height: 18),
        for (final x in [
          'Personal Information',
          'Clinic Information',
          'Consultation Fee',
          'Available Days & Slots',
          'Notification Settings',
          'Change Password',
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
