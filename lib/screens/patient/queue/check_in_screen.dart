import 'package:flutter/material.dart';

class CheckInScreen extends StatelessWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: const Text('Dr. Priya Sharma'),
                subtitle: const Text('Today, 10:00 AM\nConfirmed'),
              ),
            ),
            const Spacer(),
            const Text(
              'Have you arrived at the clinic?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap below to check in and join the queue.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/patient/queue/live'),
              child: const Text('Check in'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
