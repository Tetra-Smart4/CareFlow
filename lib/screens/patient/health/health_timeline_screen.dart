import 'package:flutter/material.dart';

class HealthTimelineScreen extends StatelessWidget {
  const HealthTimelineScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Health Timeline')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          '01 Oct 2024 • BP 122/80 • Medication 3/3 taken',
          '20 Sep 2024 • Consultation completed • Prescription created',
          '21 Sep 2024 • BP 118/76 • Weight 69.2 kg',
        ])
          Card(
            child: ListTile(
              leading: const Icon(Icons.timeline),
              title: Text(x),
            ),
          ),
      ],
    ),
  );
}
