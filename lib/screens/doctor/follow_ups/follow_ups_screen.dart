import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';

class DoctorFollowUpsScreen extends StatefulWidget {
  const DoctorFollowUpsScreen({super.key});

  @override
  State<DoctorFollowUpsScreen> createState() => _DoctorFollowUpsScreenState();
}

class _DoctorFollowUpsScreenState extends State<DoctorFollowUpsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _followUps = [];

  @override
  void initState() {
    super.initState();
    _loadFollowUps();
  }

  Future<void> _loadFollowUps() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'User not authenticated.';
        });
        return;
      }

      final data = await Supabase.instance.client
          .from('careflow_followups')
          .select()
          .eq('doctor_id', user.id)
          .order('followup_date', ascending: true);

      final list = List<Map<String, dynamic>>.from(data);

      final patientIds = list.map((e) => e['patient_id']?.toString()).whereType<String>().toSet().toList();
      if (patientIds.isNotEmpty) {
        final profiles = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name, phone')
            .inFilter('id', patientIds);

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
          _followUps = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load scheduled follow-ups.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Doctor Follow-up Management'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadFollowUps,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFollowUps,
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
                        ElevatedButton(onPressed: _loadFollowUps, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _followUps.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.event_available_rounded, size: 52, color: ColorTokens.muted),
                              SizedBox(height: 12),
                              Text(
                                'No Follow-ups Scheduled',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: ColorTokens.navy,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'When you schedule follow-ups at the end of consultations, they will appear here.',
                                style: TextStyle(color: ColorTokens.muted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _followUps.length,
                        itemBuilder: (context, index) {
                          final item = _followUps[index];
                          final patientName = item['patient_name'] ?? 'Patient';
                          final date = item['followup_date']?.toString() ?? '';
                          final reason = item['reason']?.toString() ?? 'Routine Review';
                          final status = item['status']?.toString() ?? 'pending';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: ColorTokens.lightBlue,
                                child: Icon(Icons.schedule_rounded, color: ColorTokens.primaryBlue),
                              ),
                              title: Text(
                                patientName,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.navy),
                              ),
                              subtitle: Text('$date • $reason'),
                              trailing: Chip(
                                label: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                                backgroundColor: status == 'completed'
                                    ? ColorTokens.lightGreen
                                    : ColorTokens.lightBlue,
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
