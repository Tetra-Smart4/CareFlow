import 'package:flutter/material.dart';

class ConsultationSummaryScreen extends StatelessWidget {
  const ConsultationSummaryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Consultation Summary')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          ('Symptoms', 'Fever and body pain for 2 days'),
          ('Vitals', 'BP 120/80 • HR 72 • Temp 99.2°F'),
          ('Diagnosis', 'Acute Viral Fever (J06.9)'),
          ('Prescription', '3 medicines'),
          ('Follow-up', '15 Oct 2024'),
          ('Doctor Notes', 'Advised rest and hydration.'),
        ])
          Card(
            child: ListTile(
              title: Text(
                x.$1,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(x.$2),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Save Visit'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
