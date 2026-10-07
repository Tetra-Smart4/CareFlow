import 'package:flutter/material.dart';

class PatientDetailsScreen extends StatelessWidget {
  const PatientDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Amit Kumar')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          title: Text(
            'Contact Information',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '+91 98765 43210\namit.kumar@gmail.com\nErnakulam, Kochi',
          ),
        ),
        const ListTile(
          title: Text(
            'Emergency Contact',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text('Suresh Kumar (Father)'),
        ),
        const ListTile(
          title: Text(
            'Allergies',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text('No known allergies'),
        ),
        const ListTile(
          title: Text(
            'Medical Conditions',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text('Type 2 Diabetes (2022)\nHypertension (2023)'),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.pushNamed(context, '/doctor/medical-history'),
          child: const Text('View All Records'),
        ),
      ],
    ),
  );
}
