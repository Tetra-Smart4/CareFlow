import 'package:flutter/material.dart';

class DoctorCalendarScreen extends StatelessWidget {
  const DoctorCalendarScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Calendar')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'October 2024',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        for (final x in [
          '10:00 AM • Amit Kumar • General Checkup',
          '10:30 AM • Sneha Verma • Fever & Cold',
          '11:00 AM • Rajesh Mehta • Back Pain',
          '12:00 PM • Pooja Singh • Skin Consultation',
        ])
          Card(
            child: ListTile(leading: const Icon(Icons.event), title: Text(x)),
          ),
      ],
    ),
  );
}
