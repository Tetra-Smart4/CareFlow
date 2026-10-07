import 'package:flutter/material.dart';

class AppointmentManagementScreen extends StatelessWidget {
  const AppointmentManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Appointment Management')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Manage clinic bookings',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...[
          'Rahul Kumar • 10:00 AM • Confirmed',
          'Sneha Verma • 10:30 AM • Confirmed',
          'Rajesh Mehta • 11:00 AM • Pending',
          'Pooja Singh • 11:30 AM • Confirmed',
          'Suresh Nair • 12:00 PM • Confirmed',
        ].map(
          (x) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(x),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    ),
  );
}
