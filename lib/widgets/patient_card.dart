import 'package:flutter/material.dart';

class PatientCard extends StatelessWidget {
  const PatientCard({
    super.key,
    this.title = 'Patient',
    this.subtitle = 'CareFlow update',
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: trailing,
    ),
  );
}
