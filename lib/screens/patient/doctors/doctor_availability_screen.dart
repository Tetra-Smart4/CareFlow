import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/appointment_repository.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  final String? doctorId;
  final String? doctorName;

  const DoctorAvailabilityScreen({super.key, this.doctorId, this.doctorName});

  @override
  State<DoctorAvailabilityScreen> createState() => _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  final _appointmentRepo = AppointmentRepository();

  DateTime _selectedDate = DateTime.now();
  List<String> _slots = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final docId = widget.doctorId;
    if (docId == null) {
      setState(() {
        _loading = false;
        _error = 'Doctor not specified.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final available = await _appointmentRepo.getAvailableSlots(docId, _selectedDate);
      if (mounted) {
        setState(() {
          _slots = available;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load doctor availability.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.doctorName ?? 'Doctor';

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: Text('Availability • $name'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: ColorTokens.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Date: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _loadSlots();
                      }
                    },
                    child: const Text('Change Date'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Available Time Slots',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.navy),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_error != null)
            Center(
              child: Column(
                children: [
                  Text(_error!, style: const TextStyle(color: ColorTokens.error)),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _loadSlots, child: const Text('Retry')),
                ],
              ),
            )
          else if (_slots.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.event_busy_rounded, size: 40, color: ColorTokens.muted),
                      SizedBox(height: 8),
                      Text('No available slots for this date.', style: TextStyle(color: ColorTokens.muted)),
                    ],
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _slots.map((s) {
                return Chip(
                  avatar: const Icon(Icons.access_time_rounded, size: 16, color: ColorTokens.careGreen),
                  label: Text(s),
                  backgroundColor: ColorTokens.lightGreen,
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          if (widget.doctorId != null)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/patient/appointments/book',
                    arguments: {
                      'doctorId': widget.doctorId,
                      'doctorName': widget.doctorName,
                    },
                  );
                },
                child: const Text('Proceed to Book'),
              ),
            ),
        ],
      ),
    );
  }
}
