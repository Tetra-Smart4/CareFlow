import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _bills = [];

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
      if (user == null) {
        setState(() {
          _loading = false;
          _bills = [];
        });
        return;
      }

      // Query appointments for patient to show completed consultations/invoices
      final appts = await Supabase.instance.client
          .from('careflow_appointments')
          .select()
          .eq('patient_id', user.id)
          .order('appointment_date', ascending: false);

      final list = List<Map<String, dynamic>>.from(appts);

      if (mounted) {
        setState(() {
          _bills = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load billing history.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Bills & Payments'),
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
                : _bills.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.receipt_outlined, size: 52, color: ColorTokens.muted),
                              SizedBox(height: 12),
                              Text(
                                'No Invoices or Bills',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: ColorTokens.navy,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'When you have consultations and clinical services, your receipts and invoices will be listed here.',
                                style: TextStyle(color: ColorTokens.muted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bills.length,
                        itemBuilder: (context, index) {
                          final item = _bills[index];
                          final date = item['appointment_date']?.toString() ?? '';
                          final reason = item['reason']?.toString() ?? 'Doctor Consultation';
                          final status = item['status']?.toString() ?? 'completed';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: ColorTokens.lightBlue,
                                child: Icon(Icons.receipt_long, color: ColorTokens.primaryBlue),
                              ),
                              title: Text(
                                reason,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.navy),
                              ),
                              subtitle: Text(date),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Consultation',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                  ),
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: status == 'completed'
                                          ? ColorTokens.careGreen
                                          : ColorTokens.primaryBlue,
                                    ),
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
