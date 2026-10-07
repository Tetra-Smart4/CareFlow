import 'package:flutter/material.dart';

class PrescriptionDetailsScreen extends StatelessWidget {
  const PrescriptionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '15 Sep 2024 • Dr. Priya Sharma',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          _medicine('Paracetamol 500 mg', '1-0-1 • After food • 5 days'),
          _medicine('Cetirizine 10 mg', '0-0-1 • Night • 5 days'),
          _medicine('Vitamin C', '1-0-0 • Morning • 10 days'),
          Card(
            color: Colors.white,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Take medicines after food. Drink plenty of water. Rest and avoid cold exposure.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Set Medication Reminder'),
          ),
        ],
      ),
    );
  }

  Widget _medicine(String name, String schedule) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.medication_outlined),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(schedule),
      ),
    );
  }
}
