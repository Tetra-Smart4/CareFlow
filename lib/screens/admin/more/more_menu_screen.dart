import 'package:flutter/material.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('More / Menu')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          'About CareFlow',
          'Privacy Policy',
          'Terms of Service',
          'Data Security',
          'Contact Support',
          'Feedback',
          'App Version v1.0.0',
        ])
          Card(
            child: ListTile(
              title: Text(x),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    ),
  );
}
