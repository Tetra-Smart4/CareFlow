import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/prescription_repository.dart';
import '../../../repositories/medication_adherence_repository.dart';
import 'package:careflow/widgets/common/lottie_animation.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DoctorPrescriptionScreen extends StatefulWidget {
  final Map<String, dynamic>? args;
  const DoctorPrescriptionScreen({super.key, this.args});

  @override
  State<DoctorPrescriptionScreen> createState() => _DoctorPrescriptionScreenState();
}

class _DoctorPrescriptionScreenState extends State<DoctorPrescriptionScreen> {
  final List<Map<String, dynamic>> _medicines = [];
  final _prescRepo = PrescriptionRepository();
  final _adherenceRepo = MedicationAdherenceRepository();

  String? _patientId;
  String? _patientName;
  String? _appointmentId;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalArgs = ModalRoute.of(context)?.settings.arguments;
    final combined = widget.args ?? (modalArgs is Map<String, dynamic> ? modalArgs : {});
    _patientId ??= combined['patientId']?.toString();
    _patientName ??= combined['patientName']?.toString() ?? 'Patient';
    _appointmentId ??= combined['appointmentId']?.toString();
  }

  void _showAddMedicineDialog() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController(text: '1 tablet (500mg)');
    final freqCtrl = TextEditingController(text: 'Twice daily');
    final durationCtrl = TextEditingController(text: '5 days');
    final instructionsCtrl = TextEditingController(text: 'Take after food');

    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 4));
    List<String> adminTimes = ['08:00', '20:00'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: const Text('Add Prescribed Medicine', style: TextStyle(fontWeight: FontWeight.w800)),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name *',
                        hintText: 'e.g. Paracetamol, Amoxicillin',
                        prefixIcon: Icon(Icons.medication),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dosageCtrl,
                            decoration: const InputDecoration(labelText: 'Dosage', hintText: 'e.g. 500 mg'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: freqCtrl,
                            decoration: const InputDecoration(labelText: 'Frequency', hintText: 'Twice daily'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: durationCtrl,
                            decoration: const InputDecoration(labelText: 'Duration', hintText: '5 days'),
                            onChanged: (val) {
                              final days = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 5;
                              setDlgState(() {
                                endDate = startDate.add(Duration(days: days > 0 ? days - 1 : 0));
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              'Start: ${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setDlgState(() {
                                  startDate = picked;
                                  final days = int.tryParse(durationCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 5;
                                  endDate = startDate.add(Duration(days: days > 0 ? days - 1 : 0));
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: instructionsCtrl,
                      decoration: const InputDecoration(labelText: 'Clinical Instructions', hintText: 'e.g. After food with water'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Exact Administration Times (Required for Reminders)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ColorTokens.darkNavy),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildPresetChip('Morning (08:00)', '08:00', adminTimes, () {
                          setDlgState(() {
                            if (adminTimes.contains('08:00')) {
                              adminTimes.remove('08:00');
                            } else {
                              adminTimes.add('08:00');
                            }
                            adminTimes.sort();
                          });
                        }),
                        _buildPresetChip('Afternoon (13:00)', '13:00', adminTimes, () {
                          setDlgState(() {
                            if (adminTimes.contains('13:00')) {
                              adminTimes.remove('13:00');
                            } else {
                              adminTimes.add('13:00');
                            }
                            adminTimes.sort();
                          });
                        }),
                        _buildPresetChip('Evening (18:00)', '18:00', adminTimes, () {
                          setDlgState(() {
                            if (adminTimes.contains('18:00')) {
                              adminTimes.remove('18:00');
                            } else {
                              adminTimes.add('18:00');
                            }
                            adminTimes.sort();
                          });
                        }),
                        _buildPresetChip('Night (21:00)', '21:00', adminTimes, () {
                          setDlgState(() {
                            if (adminTimes.contains('21:00')) {
                              adminTimes.remove('21:00');
                            } else {
                              adminTimes.add('21:00');
                            }
                            adminTimes.sort();
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Selected (${adminTimes.length}): ${adminTimes.join(', ')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ColorTokens.primaryBlue)),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.add_alarm, size: 16),
                          label: const Text('Custom Time', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
                            if (time != null) {
                              final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                              if (!adminTimes.contains(formatted)) {
                                setDlgState(() {
                                  adminTimes.add(formatted);
                                  adminTimes.sort();
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine name is required.')));
                    return;
                  }
                  if (adminTimes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one exact administration time.')));
                    return;
                  }
                  setState(() {
                    _medicines.add({
                      'medicine_name': name,
                      'dosage': dosageCtrl.text.trim(),
                      'frequency': freqCtrl.text.trim(),
                      'duration': durationCtrl.text.trim(),
                      'instructions': instructionsCtrl.text.trim(),
                      'start_date': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                      'end_date': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
                      'administration_times': List<String>.from(adminTimes),
                    });
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Add to Prescription'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresetChip(String label, String time, List<String> current, VoidCallback onTap) {
    final selected = current.contains(time);
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : ColorTokens.darkNavy)),
      selected: selected,
      selectedColor: ColorTokens.primaryBlue,
      checkmarkColor: Colors.white,
      onSelected: (_) => onTap(),
    );
  }

  Future<void> _savePrescription() async {
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one medicine.')));
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doctor authentication required.')));
      return;
    }

    setState(() => _isSaving = true);
    int totalDosesCreated = 0;

    try {
      for (final med in _medicines) {
        final payload = {
          'doctor_id': user.id,
          if (_patientId != null) 'patient_id': _patientId,
          if (_appointmentId != null) 'appointment_id': _appointmentId,
          'medicine_name': med['medicine_name'],
          'dosage': med['dosage'],
          'frequency': med['frequency'],
          'duration': med['duration'],
          'instructions': med['instructions'],
          'start_date': med['start_date'],
          'end_date': med['end_date'],
          'administration_times': med['administration_times'],
          'status': 'active',
          'timezone': 'UTC',
        };

        final saved = await _prescRepo.create(payload);
        if (saved['id'] != null) {
          final res = await _adherenceRepo.generateDosesForPrescription(saved['id'].toString());
          if (res['doses_created'] is int) {
            totalDosesCreated += res['doses_created'] as int;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prescription saved! Generated $totalDosesCreated scheduled doses with zero-grace caregiver alerts.'),
            backgroundColor: ColorTokens.careGreen,
          ),
        );
        Navigator.pop(context, _medicines);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving prescription: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Prescription Builder'),
        bottom: _patientName != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 6),
                    child: Text('Patient: $_patientName', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prescribed Medicines (${_medicines.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ColorTokens.navy),
              ),
              ElevatedButton.icon(
                onPressed: _showAddMedicineDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Medicine'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_medicines.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: ColorTokens.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: const [
                    LottieAnimation(
                      assetName: 'assets/animations/empty.json',
                      width: 120,
                      fallback: Icon(Icons.medication_outlined, size: 48, color: ColorTokens.muted),
                    ),
                    SizedBox(height: 10),
                    Text('No medicines added yet', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Tap "Add Medicine" to configure dosages, administration times, and schedules.', style: TextStyle(color: ColorTokens.muted), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ..._medicines.asMap().entries.map((entry) {
              final idx = entry.key;
              final med = entry.value;
              final times = (med['administration_times'] as List?)?.join(', ') ?? '08:00, 20:00';
              final duration = med['duration'] ?? '';
              final start = med['start_date'] ?? '';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: ColorTokens.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: ColorTokens.lightBlue,
                            child: Icon(Icons.medication_rounded, color: ColorTokens.primaryBlue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(med['medicine_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ColorTokens.darkNavy)),
                                Text('${med['dosage']} • ${med['frequency']} • $duration', style: const TextStyle(fontSize: 13, color: ColorTokens.textSecondary)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: ColorTokens.error),
                            onPressed: () => setState(() => _medicines.removeAt(idx)),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled, size: 16, color: ColorTokens.primaryBlue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Dose Schedule: $times (Starts $start)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ColorTokens.darkNavy),
                            ),
                          ),
                        ],
                      ),
                      if (med['instructions'] != null && med['instructions'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: ColorTokens.muted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Instructions: ${med['instructions']}',
                                style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ).animate().fade(delay: (idx * 50).ms, duration: 400.ms).slideY(begin: 0.1, duration: 400.ms);
            }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _savePrescription,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorTokens.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Prescription & Schedule Doses', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
