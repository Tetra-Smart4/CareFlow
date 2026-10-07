import 'package:flutter/material.dart';

class LiveQueueScreen extends StatefulWidget {
  const LiveQueueScreen({super.key});

  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen> {
  int ahead = 2;
  int token = 17;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Queue Status'),
        actions: [
          IconButton(
            onPressed: () => setState(() => ahead = ahead > 0 ? ahead - 1 : 0),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Dr. Priya Sharma'),
                  const Text(
                    'General Physician',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Your Position',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '#A$token',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '$ahead patients ahead',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(value: .72),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Next in Queue',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          ...[
            'A016 • Priya Menon',
            'A017 • You (Rahul)',
            'A018 • Suresh Nair',
            'A019 • Anjali Rao',
          ].map(
            (item) => Card(
              child: ListTile(
                leading: const Icon(Icons.queue),
                title: Text(item),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
