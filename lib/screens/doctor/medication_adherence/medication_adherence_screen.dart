import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';

class DoctorMedicationAdherenceScreen extends StatelessWidget {
  const DoctorMedicationAdherenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String patientName = 'Patient';
    if (args is Map && args['patientName'] != null) {
      patientName = args['patientName'].toString();
    }

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(title: const Text('Medication Adherence')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 64,
                color: ColorTokens.primaryBlue,
              ),
              const SizedBox(height: 16),
              Text(
                'Adherence Tracker for $patientName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ColorTokens.navy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Medication intake records are tracked when patients log their scheduled doses in the CareFlow patient portal.',
                style: TextStyle(color: ColorTokens.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: ColorTokens.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Active Prescription Adherence Monitoring Enabled',
                  style: TextStyle(
                    color: ColorTokens.primaryBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
