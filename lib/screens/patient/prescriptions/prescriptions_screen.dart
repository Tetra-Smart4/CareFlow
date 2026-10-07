import 'package:flutter/material.dart';

class PrescriptionsScreen extends StatelessWidget {
  const PrescriptionsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Prescriptions')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          ('15 Sep 2024', 'Dr. Priya Sharma', '3 medicines'),
          ('10 Aug 2024', 'Dr. Amit Kumar', '2 medicines'),
          ('12 Jun 2024', 'Dr. Priya Sharma', '2 medicines'),
          ('5 Apr 2024', 'Dr. Priya Sharma', '2 medicines'),
        ])
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
              title: Text(x.$1),
              subtitle: Text('${x.$2} • ${x.$3}'),
              trailing: OutlinedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/patient/prescriptions/detail',
                ),
                child: const Text('View'),
              ),
            ),
          ),
      ],
    ),
  );
}
