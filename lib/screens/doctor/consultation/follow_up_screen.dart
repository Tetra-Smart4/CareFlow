import 'package:flutter/material.dart';

class DoctorFollowUpScreen extends StatelessWidget {
  const DoctorFollowUpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Set Follow-up')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SwitchListTile(
          value: true,
          onChanged: null,
          title: Text('Schedule follow-up'),
        ),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Follow-up Date',
            hintText: '15 Oct 2024',
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Reason',
            hintText: 'Review symptoms and response to medication',
          ),
        ),
        const SizedBox(height: 12),
        const Text('Reminder to Patient'),
        const Switch(value: true, onChanged: null),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Complete Consultation'),
        ),
      ],
    ),
  );
}
