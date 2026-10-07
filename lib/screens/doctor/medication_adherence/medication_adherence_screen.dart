import 'package:flutter/material.dart';

class DoctorMedicationAdherenceScreen extends StatelessWidget {
  const DoctorMedicationAdherenceScreen({super.key});
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
                CircularProgressIndicator(value: .86, strokeWidth: 14),
                const Text(
                  '86%',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Amit Kumar • Last 30 Days'),
          const SizedBox(height: 18),
          const Text('Taken 26 • Missed 4 • Total 30'),
        ],
      ),
    ),
  );
}
