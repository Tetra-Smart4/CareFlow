import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';

class PrescriptionManagementScreen extends StatefulWidget {
  const PrescriptionManagementScreen({super.key});

  @override
  State<PrescriptionManagementScreen> createState() => _PrescriptionManagementScreenState();
}

class _PrescriptionManagementScreenState extends State<PrescriptionManagementScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _prescriptions = [];

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await Supabase.instance.client
          .from('careflow_prescriptions')
          .select()
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(data);

      final pIds = list.map((e) => e['patient_id']?.toString()).whereType<String>().toSet().toList();
      final dIds = list.map((e) => e['doctor_id']?.toString()).whereType<String>().toSet().toList();
      final allIds = {...pIds, ...dIds}.toList();

      if (allIds.isNotEmpty) {
        final profiles = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', allIds);

        final pMap = <String, String>{};
        for (final p in profiles) {
          pMap[p['id'].toString()] = p['full_name']?.toString() ?? '';
        }

        for (final item in list) {
          final pid = item['patient_id']?.toString();
          final did = item['doctor_id']?.toString();
          if (pid != null && pMap.containsKey(pid)) item['patient_name'] = pMap[pid];
          if (did != null && pMap.containsKey(did)) item['doctor_name'] = pMap[did];
        }
      }

      if (mounted) {
        setState(() {
          _prescriptions = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load prescriptions.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Prescription Archive'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadPrescriptions,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPrescriptions,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: ColorTokens.error),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: ColorTokens.muted)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadPrescriptions, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _prescriptions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.receipt_long_outlined, size: 52, color: ColorTokens.muted),
                              SizedBox(height: 12),
                              Text(
                                'No Prescriptions Found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: ColorTokens.navy,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Prescriptions issued by clinic doctors will appear in this archive.',
                                style: TextStyle(color: ColorTokens.muted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _prescriptions.length,
                        itemBuilder: (context, index) {
                          final item = _prescriptions[index];
                          final patient = item['patient_name'] ?? 'Patient';
                          final doctor = item['doctor_name'] ?? 'Doctor';
                          final date = item['created_at']?.toString() ?? '';
                          final meds = item['medicines'];
                          int count = 0;
                          if (meds is List) count = meds.length;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: ColorTokens.lightBlue,
                                child: Icon(Icons.medication_rounded, color: ColorTokens.primaryBlue),
                              ),
                              title: Text(
                                patient,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.navy),
                              ),
                              subtitle: Text(
                                'Dr. $doctor • ${date.length >= 10 ? date.substring(0, 10) : date} • $count medicines',
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
