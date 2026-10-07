import 'package:flutter/material.dart';

import 'package:careflow/widgets/common/metric_tile.dart';

class RecordDetailsScreen extends StatelessWidget {
  const RecordDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medical Record')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '15 Sep 2024 • Dr. Priya Sharma',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 14),
          const Text('Symptoms', style: TextStyle(fontWeight: FontWeight.w800)),
          const Text('Fever, cold, body pain'),
          const SizedBox(height: 14),
          const Text('Vitals', style: TextStyle(fontWeight: FontWeight.w800)),
          const MetricTile(
            label: 'Blood Pressure',
            value: '120/80',
            unit: 'mmHg',
            icon: Icons.favorite_border,
          ),
          const MetricTile(
            label: 'Heart Rate',
            value: '78',
            unit: 'bpm',
            icon: Icons.monitor_heart,
          ),
          const SizedBox(height: 10),
          const Text(
            'Diagnosis',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const Text('Viral fever'),
          const SizedBox(height: 10),
          const Text(
            'Treatment Plan',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const Text('Rest, hydration, medication as prescribed.'),
        ],
      ),
    );
  }
}
