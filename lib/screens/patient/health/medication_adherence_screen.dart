import 'package:flutter/material.dart';

class MedicationAdherenceScreen extends StatelessWidget {
  const MedicationAdherenceScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Medication Adherence')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: .86, strokeWidth: 15),
                const Text(
                  '86%',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          const Text('Last 30 Days', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          const Text('Taken 26   •   Missed 4   •   Total 30'),
        ],
      ),
    ),
  );
}
