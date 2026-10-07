import 'package:flutter/material.dart';

class DoctorQuickActionsScreen extends StatelessWidget {
  const DoctorQuickActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('New Consultation', Icons.medical_information),
      ('Search Patient', Icons.search),
      ('Add Prescription', Icons.receipt_long),
      ('View Queue', Icons.queue),
      ("Today's Reports", Icons.description),
      ('Send Notification', Icons.notifications),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Actions')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          for (final action in actions)
            Card(
              child: InkWell(
                onTap: () {},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.$2, size: 32),
                    const SizedBox(height: 8),
                    Text(action.$1),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
