import 'package:flutter/material.dart';

class CreateBillScreen extends StatelessWidget {
  const CreateBillScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Bill')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          leading: CircleAvatar(child: Icon(Icons.person)),
          title: Text('Rahul Kumar'),
          subtitle: Text('Male, 32 years • MRN-1025'),
        ),
        const Divider(),
        for (final x in ['Consultation Fee', 'Blood Test (CBC)', 'X-Ray'])
          Card(
            child: ListTile(
              title: Text(x),
              trailing: Text(
                x == 'Consultation Fee'
                    ? '₹500'
                    : x == 'Blood Test (CBC)'
                    ? '₹300'
                    : '₹400',
              ),
            ),
          ),
        const ListTile(
          title: Text('Total', style: TextStyle(fontWeight: FontWeight.w900)),
          trailing: Text(
            '₹1,200',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const Text('Payment Method'),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'Cash', label: Text('Cash')),
            ButtonSegment(value: 'Card', label: Text('Card')),
            ButtonSegment(value: 'UPI', label: Text('UPI')),
          ],
          selected: {'Cash'},
        ),
        const SizedBox(height: 18),
        ElevatedButton(onPressed: () {}, child: const Text('Generate Bill')),
      ],
    ),
  );
}
