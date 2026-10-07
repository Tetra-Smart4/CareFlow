import 'package:flutter/material.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.icon = Icons.insights,
  });
  final String label, value, unit;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text('$label • $unit'),
    ),
  );
}
