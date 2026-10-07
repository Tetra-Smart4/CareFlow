import 'package:flutter/material.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('User Management'),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.person_add)),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          'Dr. Priya Sharma • Doctor • Active',
          'Dr. Amit Kumar • Doctor • Active',
          'Receptionist • Staff • Active',
          'Lab Technician • Staff • Active',
        ])
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(x),
              trailing: const Icon(Icons.more_vert),
            ),
          ),
      ],
    ),
  );
}
