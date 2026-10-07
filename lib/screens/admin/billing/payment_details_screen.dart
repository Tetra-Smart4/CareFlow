import 'package:flutter/material.dart';

class PaymentDetailsScreen extends StatelessWidget {
  const PaymentDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Payment Details')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(title: Text('Invoice'), subtitle: Text('INV-00123')),
        const ListTile(title: Text('Amount'), subtitle: Text('₹1,200')),
        const ListTile(title: Text('Method'), subtitle: Text('UPI')),
        const ListTile(title: Text('Status'), subtitle: Text('Paid')),
      ],
    ),
  );
}
