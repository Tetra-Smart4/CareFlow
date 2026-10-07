import 'package:flutter/material.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Today's Appointments")),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          ('08:00 AM', 'Rahul Kumar', 'General checkup', 'Completed'),
          ('10:00 AM', 'Amit Kumar', 'General checkup', 'Next'),
          ('10:30 AM', 'Sneha Verma', 'Follow-up', 'Upcoming'),
          ('11:00 AM', 'Rajesh Mehta', 'Back Pain', 'Upcoming'),
          ('11:30 AM', 'Pooja Singh', 'Skin Consultation', 'Upcoming'),
          ('12:00 PM', 'Suresh Nair', 'Blood Test Review', 'Upcoming'),
        ])
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(
                x.$2,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${x.$1} • ${x.$3}'),
              trailing: Chip(label: Text(x.$4)),
            ),
          ),
      ],
    ),
  );
}
