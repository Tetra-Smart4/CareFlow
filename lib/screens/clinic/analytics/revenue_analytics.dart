import 'package:flutter/material.dart';

class RevenueAnalytics extends StatelessWidget {
  const RevenueAnalytics({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Revenue Details')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Total Revenue', style: TextStyle(color: Colors.grey)),
        const Text(
          '₹1,25,000',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            title: const Text('Consultation'),
            trailing: const Text('45%'),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Blood Tests'),
            trailing: const Text('25%'),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('X-Ray'),
            trailing: const Text('15%'),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Other Services'),
            trailing: const Text('15%'),
          ),
        ),
      ],
    ),
  );
}
