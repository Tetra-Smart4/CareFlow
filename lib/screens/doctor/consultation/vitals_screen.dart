import 'package:flutter/material.dart';

class VitalsScreen extends StatelessWidget {
  const VitalsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vitals')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final x in [
          ('Blood Pressure', '120/80 mmHg'),
          ('Heart Rate', '72 bpm'),
          ('Temperature', '99.2 °F'),
          ('Weight', '68.5 kg'),
          ('Blood Glucose', '108 mg/dL'),
          ('Oxygen Saturation', '98%'),
        ])
          TextField(
            decoration: InputDecoration(labelText: x.$1, hintText: x.$2),
          ),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () {}, child: const Text('Next')),
      ],
    ),
  );
}
