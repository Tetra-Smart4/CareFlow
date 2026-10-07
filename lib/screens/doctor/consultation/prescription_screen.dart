import 'package:flutter/material.dart';

class DoctorPrescriptionScreen extends StatelessWidget {
  const DoctorPrescriptionScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Prescription')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          'Paracetamol 500 mg • 1-0-1 • After food • 5 Days',
          'Cetirizine 10 mg • 0-0-1 • Night • 5 Days',
          'Vitamin C • 1-0-0 • Morning • 10 Days',
        ])
          Card(
            child: ListTile(
              leading: const Icon(Icons.medication_outlined),
              title: Text(x),
              trailing: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Add Medicine'),
        ),
        ElevatedButton(onPressed: () {}, child: const Text('Next')),
      ],
    ),
  );
}
