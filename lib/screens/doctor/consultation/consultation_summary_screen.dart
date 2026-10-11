import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';

class ConsultationSummaryScreen extends StatelessWidget {
  const ConsultationSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String patientName = 'Patient';
    String diagnosis = 'General Consultation';
    String symptoms = 'None recorded';
    String vitals = 'Normal';
    String notes = 'Standard examination';

    if (args is Map) {
      if (args['patientName'] != null) patientName = args['patientName'].toString();
      if (args['diagnosis'] != null) diagnosis = args['diagnosis'].toString();
      if (args['symptoms'] != null) symptoms = args['symptoms'].toString();
      if (args['vitals'] != null) vitals = args['vitals'].toString();
      if (args['notes'] != null) notes = args['notes'].toString();
    }

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(title: const Text('Consultation Summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: ColorTokens.lightBlue,
                child: Icon(Icons.person, color: ColorTokens.primaryBlue),
              ),
              title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Patient Consultation Record'),
            ),
          ),
          const SizedBox(height: 12),
          _summaryTile('Diagnosis', diagnosis),
          _summaryTile('Chief Complaints & Symptoms', symptoms),
          _summaryTile('Recorded Vitals', vitals),
          _summaryTile('Clinical Notes', notes),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close Summary'),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, color: ColorTokens.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(content, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ColorTokens.navy)),
          ],
        ),
      ),
    );
  }
}
