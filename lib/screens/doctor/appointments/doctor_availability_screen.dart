import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';

class ManageDoctorAvailabilityScreen extends StatefulWidget {
  const ManageDoctorAvailabilityScreen({super.key});

  @override
  State<ManageDoctorAvailabilityScreen> createState() => _ManageDoctorAvailabilityScreenState();
}

class _ManageDoctorAvailabilityScreenState extends State<ManageDoctorAvailabilityScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _availability = [];
  String? _clinicId;

  // Day index 1=Mon...7=Sun
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // fetch clinic id - assume one for simplicity if multiple, just use first
      final cd = await Supabase.instance.client.from('clinic_doctors').select('clinic_id').eq('doctor_id', user.id).maybeSingle();
      if (cd != null) {
        _clinicId = cd['clinic_id'];
      }

      final data = await Supabase.instance.client
          .from('careflow_doctor_availability')
          .select()
          .eq('doctor_id', user.id);

      setState(() {
        _availability = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        // The table might not exist yet if migration isn't run, fallback gracefully
        _error = 'Unable to load availability. Please ensure the availability system is enabled.';
      });
    }
  }

  Future<void> _saveDay(int dayIndex, bool enabled, TimeOfDay? start, TimeOfDay? end) async {
    if (_clinicId == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      if (!enabled) {
        await Supabase.instance.client
            .from('careflow_doctor_availability')
            .delete()
            .eq('doctor_id', user.id)
            .eq('clinic_id', _clinicId!)
            .eq('day_of_week', dayIndex);
      } else {
        if (start == null || end == null) return;
        final startStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}:00';
        final endStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:00';
        
        await Supabase.instance.client
            .from('careflow_doctor_availability')
            .upsert({
              'doctor_id': user.id,
              'clinic_id': _clinicId!,
              'day_of_week': dayIndex,
              'start_time': startStr,
              'end_time': endStr,
              'slot_duration_minutes': 30,
            }, onConflict: 'doctor_id, clinic_id, day_of_week');
      }
      _loadAvailability();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Availability updated')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update availability')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(title: const Text('Working Hours')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.settings_suggest, size: 48, color: ColorTokens.muted),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: ColorTokens.muted)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final dayIndex = index + 1; // 1=Mon, 7=Sun
                    final dayRecord = _availability.where((a) => a['day_of_week'] == dayIndex).firstOrNull;
                    final isEnabled = dayRecord != null;
                    
                    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
                    TimeOfDay end = const TimeOfDay(hour: 17, minute: 0);
                    
                    if (dayRecord != null) {
                      try {
                        final s = dayRecord['start_time'].toString().split(':');
                        final e = dayRecord['end_time'].toString().split(':');
                        start = TimeOfDay(hour: int.parse(s[0]), minute: int.parse(s[1]));
                        end = TimeOfDay(hour: int.parse(e[0]), minute: int.parse(e[1]));
                      } catch (_) {}
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: ColorTokens.border)),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Switch(
                              value: isEnabled,
                              onChanged: (v) {
                                _saveDay(dayIndex, v, start, end);
                              },
                            ),
                            const SizedBox(width: 8),
                            SizedBox(width: 90, child: Text(_days[index], style: const TextStyle(fontWeight: FontWeight.bold))),
                            if (isEnabled) ...[
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final t = await showTimePicker(context: context, initialTime: start);
                                    if (t != null) _saveDay(dayIndex, true, t, end);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: ColorTokens.lightBlue, borderRadius: BorderRadius.circular(8)),
                                    child: Text('${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}'),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('to'),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final t = await showTimePicker(context: context, initialTime: end);
                                    if (t != null) _saveDay(dayIndex, true, start, t);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: ColorTokens.lightBlue, borderRadius: BorderRadius.circular(8)),
                                    child: Text('${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}'),
                                  ),
                                ),
                              ),
                            ] else ...[
                              const Expanded(child: Text('Closed', textAlign: TextAlign.center, style: TextStyle(color: ColorTokens.muted))),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
