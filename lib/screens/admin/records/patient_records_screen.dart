import 'package:flutter/material.dart';

class PatientRecordsScreen extends StatelessWidget {
  const PatientRecordsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Patient Records')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Clinic medical record overview',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...[
          'Rahul Kumar • Consultations, Lab Reports, Medications',
          'Sneha Verma • Consultations, Prescriptions',
          'Rajesh Mehta • Surgery follow-up, Vitals',
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
