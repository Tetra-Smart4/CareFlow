import 'package:flutter/material.dart';

class DiagnosisScreen extends StatelessWidget {
  const DiagnosisScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diagnosis')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: 'Diagnosis',
            hintText: 'Acute Viral Fever',
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            labelText: 'ICD Code (Optional)',
            hintText: 'J06.9',
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 4,
          decoration: InputDecoration(labelText: 'Doctor Notes'),
        ),
        const SizedBox(height: 18),
        ElevatedButton(onPressed: () {}, child: const Text('Next')),
      ],
    ),
  );
}
