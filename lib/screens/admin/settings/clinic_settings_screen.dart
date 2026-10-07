import 'package:flutter/material.dart';

class ClinicSettingsScreen extends StatelessWidget {
  const ClinicSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Clinic Settings')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          'Clinic Information',
          'Clinic Services',
          'Working Hours',
          'Appointment Rules',
          'Notification Settings',
        ])
          Card(
            child: ListTile(
              leading: const Icon(Icons.tune),
              title: Text(x),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    ),
  );
}
