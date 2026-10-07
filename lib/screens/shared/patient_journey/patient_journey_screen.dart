import 'package:flutter/material.dart';

class PatientJourneyScreen extends StatelessWidget {
  const PatientJourneyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Patient Journey')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Registration → Appointment → Check-in → Consultation → Follow-up',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}
