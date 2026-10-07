import 'package:flutter/material.dart';

class DoctorFollowUpsScreen extends StatelessWidget {
  const DoctorFollowUpsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Follow-up Management')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          'Rahul Kumar • 21 Oct 2024 • Post-check review',
          'Sneha Verma • 15 Oct 2024 • Blood test review',
          'Rajesh Mehta • 20 Oct 2024 • Post-surgery review',
          'Pooja Singh • 20 Oct 2024 • Skin review',
        ])
          Card(
            child: ListTile(
              title: Text(x),
              trailing: const Chip(label: Text('Pending')),
            ),
          ),
      ],
    ),
  );
}
