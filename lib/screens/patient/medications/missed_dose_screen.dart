import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';

class MissedDoseScreen extends StatelessWidget {
  const MissedDoseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String medicine = 'Prescribed Medication';
    String timeInfo = 'Scheduled Dose';

    if (args is Map) {
      if (args['medicine'] != null) medicine = args['medicine'].toString();
      if (args['time'] != null) timeInfo = args['time'].toString();
    }

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(title: const Text('Medication Alert')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: ColorTokens.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scheduled Dose Missed',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ColorTokens.navy),
              ),
              const SizedBox(height: 10),
              Text(
                '$medicine\n$timeInfo',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ColorTokens.primaryBlue),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please take your medication as advised by your doctor or contact your clinic if you need guidance.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ColorTokens.muted),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('I Have Taken This Dose'),
              ),
              const SizedBox(height: 8),
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
