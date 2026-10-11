import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/prescription_repository.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final _prescRepo = PrescriptionRepository();

  bool _loading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _prescriptions = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _prescriptions = [];
        });
        return;
      }

      final list = await _prescRepo.list(patientId: user.id);

      if (mounted) {
        setState(() {
          _prescriptions = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load prescriptions: $e';
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPrescriptions {
    if (_searchQuery.trim().isEmpty) return _prescriptions;
    final q = _searchQuery.toLowerCase();
    return _prescriptions.where((p) {
      final med = (p['medicine_name'] ?? '').toString().toLowerCase();
      final doc = (p['doctor_name'] ?? '').toString().toLowerCase();
      return med.contains(q) || doc.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPrescriptions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search medicines or doctor...',
                prefixIcon: const Icon(Icons.search, size: 20, color: ColorTokens.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColorTokens.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColorTokens.border)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: ColorTokens.error),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: ColorTokens.muted)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadPrescriptions, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _filteredPrescriptions.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.medication_outlined, size: 48, color: ColorTokens.muted),
                                  SizedBox(height: 14),
                                  Text(
                                    'No Active Prescriptions',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: ColorTokens.darkNavy,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Doctor-prescribed medications from completed consultations will appear here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: ColorTokens.muted, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPrescriptions,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredPrescriptions.length,
                              itemBuilder: (ctx, i) {
                                final p = _filteredPrescriptions[i];
                                final med = p['medicine_name'] ?? 'Medication';
                                final dosage = p['dosage'] ?? 'As directed';
                                final freq = p['frequency'] ?? '';
                                final instruct = p['instructions'] ?? '';
                                final doc = p['doctor_name'] ?? 'Doctor';
                                final date = p['created_at'] != null ? p['created_at'].toString().split('T').first : '';

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
                                                color: ColorTokens.lightGreen,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.medication_rounded, color: ColorTokens.careGreen, size: 24),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    med,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w800,
                                                      color: ColorTokens.darkNavy,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Prescribed by $doc',
                                                    style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (date.isNotEmpty)
                                              Text(
                                                date,
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ColorTokens.textMuted),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1, color: ColorTokens.border),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: ColorTokens.lightBlue,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                dosage,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ColorTokens.primaryBlue),
                                              ),
                                            ),
                                            if (freq.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.background,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  freq,
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ColorTokens.darkNavy),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (instruct.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Instructions: $instruct',
                                            style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/patient/prescriptions/detail',
                                                arguments: p,
                                              );
                                            },
                                            icon: const Icon(Icons.info_outline_rounded, size: 16),
                                            label: const Text('View Full Details'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
