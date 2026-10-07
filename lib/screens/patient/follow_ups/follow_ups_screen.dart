import 'package:flutter/material.dart';

class FollowUpsScreen extends StatelessWidget {
  const FollowUpsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Follow-ups')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          ('8 Oct 2024', 'Dr. Priya Sharma', 'General checkup', 'Pending'),
          ('21 Oct 2024', 'Dr. Priya Sharma', 'Post-check review', 'Upcoming'),
          ('20 Nov 2024', 'Dr. Amit Kumar', 'Review', 'Upcoming'),
        ])
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_repeat),
              title: Text(x.$2),
              subtitle: Text('${x.$1} • ${x.$3}'),
              trailing: Chip(label: Text(x.$4)),
            ),
          ),
      ],
    ),
  );
}
