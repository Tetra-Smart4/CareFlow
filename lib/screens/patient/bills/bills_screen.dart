import 'package:flutter/material.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bills & Payments')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          ('15 Sep 2024', 'Consultation + Test', '₹800', 'Paid'),
          ('10 Aug 2024', 'Consultation + Test', '₹1,200', 'Pending'),
          ('12 Jun 2024', 'Consultation', '₹500', 'Paid'),
          ('5 Apr 2024', 'Consultation', '₹500', 'Paid'),
        ])
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(x.$2),
              subtitle: Text(x.$1),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    x.$3,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(x.$4),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
