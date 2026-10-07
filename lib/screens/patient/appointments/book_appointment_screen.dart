import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/appointment_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final AppointmentService appointmentService = AppointmentService();
  final TextEditingController reasonController = TextEditingController();

  String? doctorId;
  String doctorName = 'Doctor';

  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  String selectedTime = '10:00 AM';

  bool isBooking = false;
  bool isLoadingClinic = true;

  String? clinicId;
  String? errorMessage;

  final List<String> timeSlots = const [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readArguments();
    });
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  void _readArguments() {
    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is Map) {
      final receivedDoctorId = arguments['doctorId']?.toString();
      final receivedDoctorName = arguments['doctorName']?.toString();

      setState(() {
        doctorId = receivedDoctorId;

        if (receivedDoctorName != null &&
            receivedDoctorName.trim().isNotEmpty) {
          doctorName = receivedDoctorName;
        }
      });

      if (receivedDoctorId == null || receivedDoctorId.isEmpty) {
        setState(() {
          isLoadingClinic = false;
          errorMessage = 'Doctor information was not received.';
        });
        return;
      }

      _loadClinicForDoctor(receivedDoctorId);
      return;
    }

    setState(() {
      isLoadingClinic = false;
      errorMessage = 'Doctor information was not received.';
    });
  }

  Future<void> _loadClinicForDoctor(String selectedDoctorId) async {
    try {
      final result = await Supabase.instance.client
          .from('clinic_doctors')
          .select('clinic_id')
          .eq('doctor_id', selectedDoctorId)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      if (result == null || result['clinic_id'] == null) {
        setState(() {
          isLoadingClinic = false;
          errorMessage = 'No clinic is assigned to this doctor.';
        });
        return;
      }

      setState(() {
        clinicId = result['clinic_id'].toString();
        isLoadingClinic = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingClinic = false;
        errorMessage = 'Unable to load the doctor clinic.';
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (isBooking) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _showMessage('Please log in again before booking an appointment.');
      return;
    }

    if (doctorId == null || doctorId!.isEmpty) {
      _showMessage('Doctor information is missing.');
      return;
    }

    if (clinicId == null || clinicId!.isEmpty) {
      _showMessage('Clinic information is missing.');
      return;
    }

    setState(() {
      isBooking = true;
      errorMessage = null;
    });

    try {
      final appointment = await appointmentService.create({
        'patient_id': user.id,
        'doctor_id': doctorId,
        'clinic_id': clinicId,
        'appointment_date': _formatDateForDatabase(selectedDate),
        'appointment_time': _formatTimeForDatabase(selectedTime),
        'reason': reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim(),
        'status': 'confirmed',
      });

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/patient/appointments/success',
        arguments: {
          'appointment': appointment,
          'doctorId': doctorId,
          'doctorName': doctorName,
          'appointmentDate': selectedDate,
          'appointmentTime': selectedTime,
        },
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;

      setState(() {
        isBooking = false;
        errorMessage = error.message;
      });

      _showMessage(error.message);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isBooking = false;
        errorMessage = error.toString();
      });

      _showMessage('Unable to book the appointment. Please try again.');
    }
  }

  String _formatDateForDatabase(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _formatTimeForDatabase(String time) {
    final parts = time.split(' ');
    final hourMinute = parts[0].split(':');

    int hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);
    final period = parts[1];

    if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    if (period == 'PM' && hour != 12) {
      hour += 12;
    }

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:00';
  }

  String _formatDateForDisplay(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatWeekday(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return weekdays[date.weekday - 1];
  }

  String _formatShortDate(DateTime date) {
    return '${_formatWeekday(date)} ${date.day}';
  }

  List<DateTime> _nextSevenDays() {
    final today = DateTime.now();

    return List.generate(
      7,
      (index) => DateTime(
        today.year,
        today.month,
        today.day,
      ).add(Duration(days: index + 1)),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dates = _nextSevenDays();

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            doctorName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'CareFlow Doctor',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 20),

          if (errorMessage != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 10),
                    Expanded(child: Text(errorMessage!)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          Text(
            _formatDateForDisplay(selectedDate),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final date = dates[index];

                final isSelected =
                    date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;

                return ChoiceChip(
                  label: Text(_formatShortDate(date)),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Select Time Slot',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: timeSlots.map((time) {
              return ChoiceChip(
                label: Text(time),
                selected: selectedTime == time,
                onSelected: (_) {
                  setState(() {
                    selectedTime = time;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for Visit (Optional)',
              hintText: 'E.g. fever, follow-up, general checkup',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: isBooking || isLoadingClinic ? null : _bookAppointment,
              child: isBooking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      isLoadingClinic
                          ? 'Loading Clinic...'
                          : 'Book Appointment',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
