import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _diagCtrl = TextEditingController();
  final _icdCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _diagCtrl.dispose();
    _icdCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(title: const Text('Clinical Diagnosis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _diagCtrl,
            decoration: const InputDecoration(
              labelText: 'Primary Diagnosis *',
              hintText: 'Enter clinical diagnosis',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _icdCtrl,
            decoration: const InputDecoration(
              labelText: 'ICD-10 Code (Optional)',
              hintText: 'e.g. J06.9',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Doctor Clinical Notes & Impressions',
              hintText: 'Enter clinical observations and findings...',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'diagnosis': _diagCtrl.text.trim(),
                'icd': _icdCtrl.text.trim(),
                'notes': _notesCtrl.text.trim(),
              });
            },
            child: const Text('Save Diagnosis'),
          ),
        ],
      ),
    );
  }
}
