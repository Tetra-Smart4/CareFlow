import 'package:flutter/material.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  int step = 0;
  final names = const [
    'Symptoms',
    'Vitals',
    'Examination',
    'Diagnosis',
    'Prescription',
    'Follow-up',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Consultation'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 16, bottom: 6),
              child: Text('Amit Kumar'),
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
        return _Symptoms(onNext: () => setState(() => step = 1));
      case 1:
        return _Vitals(onNext: () => setState(() => step = 2));
      case 2:
        return _Diagnosis(onNext: () => setState(() => step = 3));
      case 3:
        return _PrescriptionStep(onNext: () => setState(() => step = 4));
      case 4:
        return _FollowUpStep(onNext: () => setState(() => step = 5));
      default:
        return const _Summary();
    }
  }
}

class _Symptoms extends StatelessWidget {
  const _Symptoms({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _Step(
      title: 'Symptoms',
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: 'Chief Complaint',
            hintText: 'Fever and body pain for 2 days',
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'History of Present Illness',
            hintText: 'Patient complains of fever, headache and mild body pain since 2 days.',
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 3,
          decoration: InputDecoration(labelText: 'Additional Notes (Optional)'),
        ),
        const Spacer(),
        ElevatedButton(onPressed: onNext, child: const Text('Next')),
      ],
    );
  }
}

class _Vitals extends StatelessWidget {
  const _Vitals({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final values = const [
      ('Blood Pressure', '120/80 mmHg'),
      ('Heart Rate', '72 bpm'),
      ('Temperature', '99.2 °F'),
      ('Weight', '68.5 kg'),
      ('Blood Glucose', '108 mg/dL'),
      ('Oxygen Saturation', '98%'),
    ];

    return _Step(
      title: 'Vitals',
      children: [
        for (final item in values)
          Card(
            child: ListTile(
              title: Text(item.$1),
              trailing: Text(
                item.$2,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        const Spacer(),
        ElevatedButton(onPressed: onNext, child: const Text('Next')),
      ],
    );
  }
}

class _Diagnosis extends StatelessWidget {
  const _Diagnosis({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _Step(
      title: 'Examination & Diagnosis',
      children: [
        const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Examination Findings',
            hintText:
                'Throat mild redness. Chest clear. No respiratory distress.',
          ),
        ),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 8,
          children: [
            Chip(label: Text('Acute Viral Fever')),
            Chip(label: Text('Influenza-like illness')),
          ],
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            labelText: 'ICD Code (Optional)',
            hintText: 'J06.9 - Acute upper respiratory infection',
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 3,
          decoration: InputDecoration(labelText: 'Doctor Notes'),
        ),
        const Spacer(),
        ElevatedButton(onPressed: onNext, child: const Text('Next')),
      ],
    );
  }
}

class _PrescriptionStep extends StatelessWidget {
  const _PrescriptionStep({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final medicines = const [
      'Paracetamol 500 mg • 1-0-1 • 5 days',
      'Cetirizine 10 mg • 0-0-1 • 5 days',
      'Vitamin C • 1-0-0 • 10 days',
    ];

    return _Step(
      title: 'Prescription',
      children: [
        const TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search medicine...',
          ),
        ),
        const SizedBox(height: 10),
        for (final medicine in medicines)
          Card(
            child: ListTile(
              title: Text(medicine),
              trailing: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Add Medicine'),
        ),
        const Spacer(),
        ElevatedButton(onPressed: onNext, child: const Text('Next')),
      ],
    );
  }
}

class _FollowUpStep extends StatelessWidget {
  const _FollowUpStep({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _Step(
      title: 'Follow-up',
      children: [
        SwitchListTile(
          value: true,
          onChanged: (_) {},
          title: const Text('Schedule follow-up'),
        ),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Follow-up Date',
            hintText: '15 Oct 2024',
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Reason',
            hintText: 'Review symptoms and response to medication',
          ),
        ),
        const SizedBox(height: 12),
        const Text('Priority'),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Normal', label: Text('Normal')),
            ButtonSegment(value: 'Urgent', label: Text('Urgent')),
            ButtonSegment(value: 'As needed', label: Text('As needed')),
          ],
          selected: const {'Normal'},
          onSelectionChanged: (_) {},
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: onNext,
          child: const Text('Complete Consultation'),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary();

  @override
  Widget build(BuildContext context) {
    return _Step(
      title: 'Consultation Summary',
      children: [
        const ListTile(
          leading: Icon(Icons.coronavirus),
          title: Text('Symptoms'),
          subtitle: Text('Fever and body pain for 2 days'),
        ),
        const ListTile(
          leading: Icon(Icons.monitor_heart),
          title: Text('Vitals'),
          subtitle: Text('BP 120/80 • HR 72 • Temp 99.2°F'),
        ),
        const ListTile(
          leading: Icon(Icons.medication),
          title: Text('Prescription'),
          subtitle: Text('3 medicines'),
        ),
        const ListTile(
          leading: Icon(Icons.event_repeat),
          title: Text('Follow-up'),
          subtitle: Text('15 Oct 2024'),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Save Visit'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}
