import 'package:flutter/material.dart';

class BillDetailsScreen extends StatelessWidget {
  const BillDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bill Details')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: ListTile(
            title: Text('Consultation Fee'),
            trailing: Text('₹500'),
          ),
        ),
        const Card(
          child: ListTile(
            title: Text('Blood Test (CBC)'),
            trailing: Text('₹300'),
          ),
        ),
        const Card(
          child: ListTile(title: Text('X-Ray'), trailing: Text('₹400')),
        ),
        const ListTile(
          title: Text('Total', style: TextStyle(fontWeight: FontWeight.w800)),
          trailing: Text(
            '₹1,200',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        ElevatedButton(onPressed: () {}, child: const Text('Pay Now')),
      ],
    ),
  );
}
