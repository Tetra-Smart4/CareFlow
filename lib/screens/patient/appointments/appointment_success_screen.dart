import 'package:flutter/material.dart';

class AppointmentSuccessScreen extends StatelessWidget {
  const AppointmentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 44,
                child: Icon(Icons.check, size: 50),
              ),
              const SizedBox(height: 18),
              const Text(
                'Appointment Booked Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'Dr. Priya Sharma\nTuesday, 8 October • 10:00 AM',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Add to Calendar'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('View Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
