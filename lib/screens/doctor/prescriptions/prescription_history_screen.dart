import 'package:flutter/material.dart';

class PrescriptionHistoryScreen extends StatelessWidget {
  const PrescriptionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const prescriptions = [
      '15 Sep 2024 • 3 Medicines • Active',
      '12 Jun 2024 • 2 Medicines • Completed',
      '5 Apr 2024 • 4 Medicines • Completed',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Prescription History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final prescription in prescriptions)
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(prescription),
                trailing: OutlinedButton(
                  onPressed: () {},
                  child: const Text('View'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
