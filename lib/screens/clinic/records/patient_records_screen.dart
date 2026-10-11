import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';

class PatientRecordsScreen extends StatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  State<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends State<PatientRecordsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final consultations = await Supabase.instance.client
          .from('careflow_consultations')
          .select()
          .order('consultation_date', ascending: false)
          .limit(30);

      final list = List<Map<String, dynamic>>.from(consultations);

      final pIds = list.map((e) => e['patient_id']?.toString()).whereType<String>().toSet().toList();
      if (pIds.isNotEmpty) {
        final profiles = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name, phone')
            .inFilter('id', pIds);

        final pMap = <String, Map<String, dynamic>>{};
        for (final p in profiles) {
          pMap[p['id'].toString()] = p;
        }

        for (final item in list) {
          final pid = item['patient_id']?.toString();
          if (pid != null && pMap.containsKey(pid)) {
            item['patient_name'] = pMap[pid]!['full_name'];
            item['patient_phone'] = pMap[pid]!['phone'];
          }
        }
      }

      if (mounted) {
        setState(() {
          _records = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load clinical records.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Clinical Records Overview'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadRecords,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecords,
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
                        ElevatedButton(onPressed: _loadRecords, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _records.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.folder_open_rounded, size: 52, color: ColorTokens.muted),
                              SizedBox(height: 12),
                              Text(
                                'No Clinical Records',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: ColorTokens.navy,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Medical records generated during consultations will appear here.',
                                style: TextStyle(color: ColorTokens.muted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          final rec = _records[index];
                          final patient = rec['patient_name'] ?? 'Patient';
                          final date = rec['consultation_date']?.toString() ?? '';
                          final diagnosis = rec['diagnosis']?.toString() ?? 'General Consultation';
                          final symptoms = rec['symptoms']?.toString();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: ColorTokens.lightBlue,
                                child: Icon(Icons.receipt_long_rounded, color: ColorTokens.primaryBlue),
                              ),
                              title: Text(
                                patient,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.navy),
                              ),
                              subtitle: Text(
                                '$diagnosis • $date${symptoms != null ? " • $symptoms" : ""}',
                              ),
                              trailing: const Icon(Icons.chevron_right, color: ColorTokens.muted),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/doctor/patients/details',
                                  arguments: {'patientId': rec['patient_id']},
                                );
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
