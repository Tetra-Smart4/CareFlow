import 'package:flutter/material.dart';

class DoctorManagementScreen extends StatelessWidget {
  const DoctorManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Doctor Management')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Manage doctors and availability',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...[
          'Dr. Priya Sharma • General Physician • Active',
          'Dr. Amit Kumar • Cardiologist • Active',
          'Dr. Neha Verma • Dermatologist • Active',
          'Dr. Rajesh Mehta • Orthopedic Surgeon • Inactive',
          'Dr. Sunil Nair • ENT Specialist • Active',
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
