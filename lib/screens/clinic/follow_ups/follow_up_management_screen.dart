import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';

class FollowUpManagementScreen extends StatefulWidget {
  const FollowUpManagementScreen({super.key});

  @override
  State<FollowUpManagementScreen> createState() => _FollowUpManagementScreenState();
}

class _FollowUpManagementScreenState extends State<FollowUpManagementScreen> {
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
      final data = await Supabase.instance.client
          .from('careflow_followups')
          .select()
          .order('followup_date', ascending: true);

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
          _followUps = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load follow-ups.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Clinic Follow-ups'),
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
                              Icon(Icons.event_available_outlined, size: 52, color: ColorTokens.muted),
                              SizedBox(height: 12),
                              Text(
                                'No Scheduled Follow-ups',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: ColorTokens.navy,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Patient follow-up reviews scheduled by doctors will appear here.',
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
                          final patient = item['patient_name'] ?? 'Patient';
                          final doctor = item['doctor_name'] ?? 'Doctor';
                          final date = item['followup_date']?.toString() ?? '';
                          final reason = item['reason']?.toString() ?? 'Routine check';
                          final status = item['status']?.toString() ?? 'pending';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: ColorTokens.lightBlue,
                                child: Icon(Icons.calendar_today_rounded, color: ColorTokens.primaryBlue),
                              ),
                              title: Text(
                                patient,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.navy),
                              ),
                              subtitle: Text('Dr. $doctor • $date • $reason'),
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
