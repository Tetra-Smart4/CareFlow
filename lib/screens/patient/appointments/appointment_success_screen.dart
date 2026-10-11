import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../widgets/common/lottie_animation.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppointmentSuccessScreen extends StatelessWidget {
  const AppointmentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String doctorName = 'Doctor';
    String formattedDateTime = 'Appointment Scheduled';

    if (args is Map) {
      if (args['doctorName'] != null) {
        doctorName = args['doctorName'].toString();
      }
      final date = args['appointmentDate'];
      final time = args['appointmentTime']?.toString();
      if (date is DateTime && time != null) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final dayName = weekdays[date.weekday - 1];
        final monthName = months[date.month - 1];
        formattedDateTime = '$dayName, $monthName ${date.day}, ${date.year} • $time';
      }
    }

    return Scaffold(
      backgroundColor: ColorTokens.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    color: ColorTokens.lightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: LottieAnimation(
                      assetName: 'assets/animations/success.json',
                      width: 100,
                      height: 100,
                      fallback: Icon(
                        Icons.check_circle_rounded,
                        size: 80,
                        color: ColorTokens.careGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Appointment Booked!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: ColorTokens.navy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  doctorName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColorTokens.primaryBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formattedDateTime,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: ColorTokens.muted,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/patient/dashboard',
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Back to Dashboard',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/patient/appointments',
                      );
                    },
                    child: const Text('View My Appointments'),
                  ),
                ),
              ].animate(interval: 100.ms).fade(duration: 500.ms).slideY(begin: 0.2, duration: 500.ms),
            ),
          ),
        ),
      ),
    );
  }
}
