import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/clinic_repository.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _clinicRepo = ClinicRepository();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _bills = [];
  double _totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final cid = await _clinicRepo.getCurrentUserClinicId() ?? user?.id;

      // Try billing table or completed appointments with doctor fee
      List<Map<String, dynamic>> records = [];
      try {
        final billingData = await Supabase.instance.client
            .from('billing')
            .select()
            .order('created_at', ascending: false);
        records = List<Map<String, dynamic>>.from(billingData);
      } catch (_) {
        // Fallback: derive from appointments
        if (cid != null) {
          final apptData = await Supabase.instance.client
              .from('careflow_appointments')
              .select()
              .eq('clinic_id', cid)
              .inFilter('status', ['completed', 'confirmed'])
              .order('created_at', ascending: false);
          records = List<Map<String, dynamic>>.from(apptData);
        }
      }

      // Calculate aggregates
      double total = 0.0;
      for (final r in records) {
        final amt = (r['amount'] as num?)?.toDouble() ?? 500.0;
        total += amt;
      }

      if (mounted) {
        setState(() {
          _bills = records;
          _totalRevenue = total;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load billing data.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Billing & Invoices'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadBills,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBills,
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
                        ElevatedButton(onPressed: _loadBills, child: const Text('Retry')),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          _stat('₹${_totalRevenue.toStringAsFixed(0)}', 'Total Billed'),
                          const SizedBox(width: 12),
                          _stat('${_bills.length}', 'Invoices Issued'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Recent Invoices',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ColorTokens.navy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_bills.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              children: const [
                                Icon(Icons.receipt_outlined, size: 48, color: ColorTokens.muted),
                                SizedBox(height: 12),
                                Text(
                                  'No Invoices Yet',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Billing records for completed patient visits will appear here.',
                                  style: TextStyle(color: ColorTokens.muted),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._bills.map((bill) {
                          final id = bill['id']?.toString() ?? 'INV-001';
                          final invNum = 'INV-${id.length >= 6 ? id.substring(0, 6).toUpperCase() : id}';
                          final patient = bill['patient_name'] ?? 'Patient Consultation';
                          final amt = (bill['amount'] as num?)?.toDouble() ?? 500.0;
                          final status = bill['status']?.toString() ?? 'Paid';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: ColorTokens.lightBlue,
                                child: Icon(Icons.receipt_long, color: ColorTokens.primaryBlue),
                              ),
                              title: Text(invNum, style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text(patient.toString()),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${amt.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                  ),
                                  Text(
                                    status,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: ColorTokens.careGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: ColorTokens.primaryBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: ColorTokens.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
