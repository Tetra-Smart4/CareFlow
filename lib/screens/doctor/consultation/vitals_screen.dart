import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  final _bpController = TextEditingController();
  final _hrController = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  final _spo2Controller = TextEditingController();

  @override
  void dispose() {
    _bpController.dispose();
    _hrController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _spo2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(title: const Text('Record Patient Vitals')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _bpController,
            decoration: const InputDecoration(labelText: 'Blood Pressure', hintText: 'e.g. 120/80 mmHg'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hrController,
            decoration: const InputDecoration(labelText: 'Heart Rate (Pulse)', hintText: 'e.g. 72 bpm'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tempController,
            decoration: const InputDecoration(labelText: 'Temperature', hintText: 'e.g. 98.6 °F'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(labelText: 'Weight', hintText: 'e.g. 70 kg'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _spo2Controller,
            decoration: const InputDecoration(labelText: 'SpO2 (Oxygen Saturation)', hintText: 'e.g. 98%'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'bp': _bpController.text.trim(),
                'hr': _hrController.text.trim(),
                'temp': _tempController.text.trim(),
                'weight': _weightController.text.trim(),
                'spo2': _spo2Controller.text.trim(),
              });
            },
            child: const Text('Save Vitals'),
          ),
        ],
      ),
    );
  }
}
