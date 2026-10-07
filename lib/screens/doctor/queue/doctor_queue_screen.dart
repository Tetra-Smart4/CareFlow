import 'package:flutter/material.dart';

class DoctorQueueScreen extends StatelessWidget {
  const DoctorQueueScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Patient Queue')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Now Consulting'),
            subtitle: const Text('Amit Kumar • #A015'),
            trailing: FilledButton(
              onPressed: () {},
              child: const Text('Mark Complete'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final x in [
          ('A016', 'Amit Kumar', '10:00 AM'),
          ('A017', 'Sneha Verma', '10:30 AM'),
          ('A018', 'Rajesh Mehta', '11:00 AM'),
          ('A019', 'Pooja Singh', '11:30 AM'),
          ('A020', 'Suresh Nair', '12:00 PM'),
        ])
          Card(
            child: ListTile(
              leading: Text(
                x.$1,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              title: Text(x.$2),
              trailing: Text(x.$3),
            ),
          ),
      ],
    ),
  );
}
