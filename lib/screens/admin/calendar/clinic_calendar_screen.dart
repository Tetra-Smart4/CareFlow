import 'package:flutter/material.dart';

class ClinicCalendarScreen extends StatelessWidget {
  const ClinicCalendarScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Calendar View')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          '09:00 • Rahul Kumar • General Checkup',
          '10:00 • Sneha Verma • Fever & Cold',
          '11:00 • Rajesh Mehta • Back Pain',
          '12:00 • Pooja Singh • Skin Consultation',
        ])
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(x),
            ),
          ),
      ],
    ),
  );
}
