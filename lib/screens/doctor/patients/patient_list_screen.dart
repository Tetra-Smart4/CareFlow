import 'package:flutter/material.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Patients')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          'Rahul Kumar',
          'Sneha Verma',
          'Rajesh Mehta',
          'Pooja Singh',
          'Suresh Nair',
        ])
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(
                x,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Phone • Last visit available'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.pushNamed(context, '/doctor/patients/detail'),
            ),
          ),
      ],
    ),
  );
}
