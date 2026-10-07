import 'package:flutter/material.dart';

class AddPatientScreen extends StatelessWidget {
  const AddPatientScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add Patient')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          'Full Name',
          'Phone',
          'Date of Birth',
          'Gender',
          'Blood Group',
          'Address',
          'Emergency Contact',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(decoration: InputDecoration(labelText: x)),
          ),
        ElevatedButton(onPressed: () {}, child: const Text('Save Patient')),
      ],
    ),
  );
}
