import 'package:flutter/material.dart';

class CheckInManagementScreen extends StatelessWidget {
  const CheckInManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Check-in Management')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          'Rahul Kumar • 10:00 AM • Dr. Priya Sharma',
          'Sneha Verma • 10:30 AM • Dr. Amit Kumar',
          'Rajesh Mehta • 11:00 AM • Dr. Priya Sharma',
          'Pooja Singh • 11:30 AM • Dr. Neha Verma',
        ])
          Card(
            child: ListTile(
              title: Text(x),
              trailing: FilledButton(
                onPressed: () {},
                child: const Text('Check in'),
              ),
            ),
          ),
      ],
    ),
  );
}
