import 'package:flutter/material.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bills = [
      ('INV-00123', 'Rahul Kumar', '₹500', 'Paid'),
      ('INV-00122', 'Sneha Verma', '₹1,200', 'Pending'),
      ('INV-00121', 'Rajesh Mehta', '₹800', 'Paid'),
      ('INV-00120', 'Pooja Singh', '₹1,500', 'Partial'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Billing & Payments')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _stat('₹18,500', 'Revenue Today'),
              _stat('3', 'Pending Bills'),
            ],
          ),
          const SizedBox(height: 14),
          for (final bill in bills)
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(bill.$1),
                subtitle: Text(bill.$2),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text(bill.$3), Text(bill.$4)],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
