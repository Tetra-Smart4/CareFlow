import 'package:flutter/material.dart';

class AdminQuickActionsScreen extends StatelessWidget {
  const AdminQuickActionsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quick Actions')),
    body: GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        for (final x in [
          ('New Appointment', Icons.event_available),
          ('Add Patient', Icons.person_add),
          ('Create Bill', Icons.receipt_long),
          ('View Reports', Icons.description),
          ('Manage Queue', Icons.queue),
          ('Send Notification', Icons.notifications),
          ('Clinic Settings', Icons.tune),
          ('Add Doctor', Icons.person_add_alt_1),
        ])
          Card(
            child: InkWell(
              onTap: () {},
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(x.$2, size: 32),
                  const SizedBox(height: 8),
                  Text(x.$1, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
