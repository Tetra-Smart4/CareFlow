import 'package:flutter/material.dart';

class MissedDoseScreen extends StatelessWidget {
  const MissedDoseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_active,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Scheduled dose missed',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Paracetamol 500 mg\n8:00 PM, 8 Oct 2024',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your emergency contact has been notified.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/patient/medications/history',
                ),
                child: const Text('View Medication History'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
