import 'package:flutter/material.dart';
import 'package:careflow/widgets/common/metric_tile.dart';

class HealthMetricsScreen extends StatelessWidget {
  const HealthMetricsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Health Metrics')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const MetricTile(
          label: 'Weight',
          value: '68.5',
          unit: 'kg',
          icon: Icons.monitor_weight_outlined,
        ),
        const MetricTile(
          label: 'Heart Rate',
          value: '72',
          unit: 'bpm',
          icon: Icons.favorite_border,
        ),
        const MetricTile(
          label: 'Blood Glucose',
          value: '108',
          unit: 'mg/dL',
          icon: Icons.water_drop_outlined,
        ),
        const MetricTile(
          label: 'Temperature',
          value: '98.4',
          unit: '°F',
          icon: Icons.thermostat_outlined,
        ),
      ],
    ),
  );
}
