import 'package:flutter/material.dart';

class ClinicQueueScreen extends StatelessWidget {
  const ClinicQueueScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Clinic Queue')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: const Text('Now Consulting'),
            subtitle: const Text('Amit Kumar • A015'),
            trailing: const Chip(label: Text('Live')),
          ),
        ),
        const SizedBox(height: 10),
        for (final x in [
          'A016 • Priya Menon • 10 min',
          'A017 • Rahul Kumar • 20 min',
          'A018 • Sneha Verma • 30 min',
          'A019 • Rajesh Mehta • 40 min',
          'A020 • Pooja Singh • 50 min',
        ])
          Card(
            child: ListTile(leading: const Icon(Icons.queue), title: Text(x)),
          ),
      ],
    ),
  );
}
