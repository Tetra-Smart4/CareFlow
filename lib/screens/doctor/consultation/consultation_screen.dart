import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../repositories/medical_record_repository.dart';

class ConsultationScreen extends StatefulWidget {
  final Map<String, dynamic>? args;
  const ConsultationScreen({super.key, this.args});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  int step = 0;
  final names = const [
    'Symptoms',
    'Examination',
    'Summary',
  ];

  late String appointmentId;
  late String patientId;
  late String patientName;
  
  final symptomsCtrl = TextEditingController();
  final diagnosisCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  bool isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = widget.args ?? ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    appointmentId = args['appointmentId']?.toString() ?? '';
    patientId = args['patientId']?.toString() ?? '';
    patientName = args['patientName']?.toString() ?? 'Patient';
  }

  Future<void> _saveConsultation() async {
    setState(() => isSaving = true);
    try {
      final repo = MedicalRecordRepository();
      await repo.createConsultation(
        appointmentId: appointmentId,
        doctorId: Supabase.instance.client.auth.currentUser!.id,
        patientId: patientId,
        diagnosis: diagnosisCtrl.text.isEmpty ? 'General Consultation' : diagnosisCtrl.text,
        symptoms: symptomsCtrl.text,
        notes: notesCtrl.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consultation saved successfully!')));
        Navigator.pop(context); // Go back to appointment details
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Consultation'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6),
              child: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(10),
              children: [
                for (var i = 0; i < names.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: CircleAvatar(child: Text('${i + 1}')),
                      label: Text(names[i]),
                      backgroundColor: i == step
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _stepWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepWidget() {
    switch (step) {
      case 0:
        return _Symptoms(
          ctrl: symptomsCtrl,
          onNext: () => setState(() => step = 1),
        );
      case 1:
        return _Diagnosis(
          diagnosisCtrl: diagnosisCtrl,
          notesCtrl: notesCtrl,
          onNext: () => setState(() => step = 2),
          onAddPrescription: () => Navigator.pushNamed(
            context,
            '/doctor/consultation/prescription',
            arguments: {
              'appointmentId': appointmentId,
              'patientId': patientId,
              'patientName': patientName,
            },
          ),
        );
      default:
        return _Summary(
          symptoms: symptomsCtrl.text,
          diagnosis: diagnosisCtrl.text,
          onSave: _saveConsultation,
          isSaving: isSaving,
        );
    }
  }
}

class _Symptoms extends StatelessWidget {
  const _Symptoms({required this.onNext, required this.ctrl});
  final VoidCallback onNext;
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Symptoms', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Chief Complaint & History',
            hintText: 'Describe patient symptoms...',
          ),
        ),
        const Spacer(),
        ElevatedButton(onPressed: onNext, child: const Text('Next')),
      ],
    );
  }
}

class _Diagnosis extends StatelessWidget {
  const _Diagnosis({
    required this.onNext,
    required this.diagnosisCtrl,
    required this.notesCtrl,
    this.onAddPrescription,
  });
  final VoidCallback onNext;
  final TextEditingController diagnosisCtrl;
  final TextEditingController notesCtrl;
  final VoidCallback? onAddPrescription;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Examination & Diagnosis', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        TextField(
          controller: diagnosisCtrl,
          decoration: const InputDecoration(
            labelText: 'Primary Diagnosis',
            hintText: 'e.g., Acute Viral Fever',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notesCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Doctor Notes / Advice',
          ),
        ),
        const Spacer(),
        Row(
          children: [
            if (onAddPrescription != null)
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.medication_outlined),
                  label: const Text('Add Prescription'),
                  onPressed: onAddPrescription,
                ),
              ),
            if (onAddPrescription != null) const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(onPressed: onNext, child: const Text('Next')),
            ),
          ],
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.symptoms, required this.diagnosis, required this.onSave, required this.isSaving});
  
  final String symptoms;
  final String diagnosis;
  final VoidCallback onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Consultation Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        ListTile(
          leading: const Icon(Icons.coronavirus),
          title: const Text('Symptoms'),
          subtitle: Text(symptoms.isEmpty ? 'None recorded' : symptoms),
        ),
        ListTile(
          leading: const Icon(Icons.medical_services),
          title: const Text('Diagnosis'),
          subtitle: Text(diagnosis.isEmpty ? 'None recorded' : diagnosis),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSaving ? null : onSave,
            child: isSaving ? const CircularProgressIndicator() : const Text('Save Visit & Complete Consultation'),
          ),
        ),
      ],
    );
  }
}
