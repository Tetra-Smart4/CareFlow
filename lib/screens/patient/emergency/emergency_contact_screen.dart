import 'package:flutter/material.dart';

class EmergencyContactScreen extends StatelessWidget {
  const EmergencyContactScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Emergency Contact')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text(
              'Suresh Kumar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('Father\n+91 98765 43210'),
            trailing: TextButton(onPressed: () {}, child: const Text('Edit')),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Call Emergency Contact',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.call),
          label: const Text('Call Now'),
        ),
        const SizedBox(height: 12),
        const Text(
          'This contact will also be notified for important medication alerts.',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    ),
  );
}
