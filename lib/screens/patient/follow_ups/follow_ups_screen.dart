import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';

class FollowUpsScreen extends StatefulWidget {
  const FollowUpsScreen({super.key});

  @override
  State<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends State<FollowUpsScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _followUps = [];

  @override
  void initState() {
    super.initState();
    _loadFollowUps();
  }

  Future<void> _loadFollowUps() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _followUps = [];
        });
        return;
      }

      final data = await Supabase.instance.client
          .from('careflow_followups')
          .select()
          .eq('patient_id', user.id)
          .order('followup_date', ascending: true);

      final list = List<Map<String, dynamic>>.from(data);

      // Fetch doctor names
      final docIds = list.map((e) => e['doctor_id']?.toString()).whereType<String>().toSet().toList();
      if (docIds.isNotEmpty) {
        final profiles = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name, specialization')
            .inFilter('id', docIds);

        final dMap = <String, Map<String, dynamic>>{};
        for (final p in profiles) {
          dMap[p['id'].toString()] = p;
        }

        for (final f in list) {
          final dId = f['doctor_id']?.toString();
          if (dId != null && dMap.containsKey(dId)) {
            f['doctor_name'] = dMap[dId]!['full_name'];
            f['doctor_specialization'] = dMap[dId]!['specialization'];
          }
        }
      }

      if (mounted) {
        setState(() {
          _followUps = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load follow-ups: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Follow-ups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadFollowUps,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: ColorTokens.error),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: const TextStyle(color: ColorTokens.muted)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadFollowUps, child: const Text('Retry')),
                    ],
                  ),
                )
              : _followUps.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.event_repeat_rounded, size: 48, color: ColorTokens.muted),
                            SizedBox(height: 14),
                            Text(
                              'No Follow-ups Scheduled',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: ColorTokens.darkNavy,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Follow-up appointments advised by your doctor will be listed here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: ColorTokens.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFollowUps,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _followUps.length,
                        itemBuilder: (ctx, i) {
                          final f = _followUps[i];
                          final docName = f['doctor_name'] ?? 'Doctor';
                          final spec = f['doctor_specialization'] ?? 'Physician';
                          final date = f['followup_date'] ?? 'Upcoming';
                          final notes = f['notes'] ?? 'Follow-up review';
                          final status = (f['status'] ?? 'scheduled').toString();

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: ColorTokens.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: ColorTokens.lightBlue,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.event_repeat_rounded, color: ColorTokens.primaryBlue, size: 22),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              docName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: ColorTokens.darkNavy,
                                              ),
                                            ),
                                            Text(spec, style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: ColorTokens.lightGreen,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ColorTokens.careGreen),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, color: ColorTokens.border),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Recommended Date', style: TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
                                      Text(date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Instructions: $notes',
                                    style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
