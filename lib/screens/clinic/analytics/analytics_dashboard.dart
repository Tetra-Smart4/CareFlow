import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/clinic_repository.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final _clinicRepo = ClinicRepository();

  bool _loading = true;
  String _selectedRange = 'today'; // 'today', '7_days', 'month'

  // Operational metrics
  int _scheduledCount = 0;
  int _checkedInCount = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;

  // Financial metrics
  double _totalBilled = 0.0;
  double _totalCollected = 0.0;
  double _outstandingBilled = 0.0;

  // Report & inventory metrics
  int _reportsUploaded = 0;
  int _lowStockCount = 0;

  // Doctor breakdown
  Map<String, int> _doctorWorkload = {};

  // Daily trend
  Map<String, int> _dailyTrend = {};

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final clinicId = await _clinicRepo.getCurrentUserClinicId() ?? user?.id;
      if (clinicId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final now = DateTime.now();
      DateTime startDate;
      if (_selectedRange == 'today') {
        startDate = DateTime(now.year, now.month, now.day);
      } else if (_selectedRange == '7_days') {
        startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      } else {
        startDate = DateTime(now.year, now.month, 1);
      }

      final startDateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

      // 1. Fetch appointments
      final appts = await Supabase.instance.client
          .from('careflow_appointments')
          .select('id, status, appointment_date, doctor_id, recorded_fee')
          .eq('clinic_id', clinicId)
          .gte('appointment_date', startDateStr);

      int scheduled = 0;
      int checkedIn = 0;
      int completed = 0;
      int cancelled = 0;
      double billed = 0.0;
      double collected = 0.0;
      final Map<String, int> docWork = {};
      final Map<String, int> trend = {};

      for (final a in (appts as List)) {
        final status = (a['status'] ?? '').toString().toLowerCase();
        final date = (a['appointment_date'] ?? '').toString();
        final docId = (a['doctor_id'] ?? 'Unassigned').toString();
        final fee = (a['recorded_fee'] as num?)?.toDouble() ?? 500.0;

        billed += fee;
        if (status == 'completed') {
          completed++;
          collected += fee;
          docWork[docId] = (docWork[docId] ?? 0) + 1;
        } else if (status == 'checked_in' || status == 'waiting') {
          checkedIn++;
        } else if (status == 'cancelled' || status == 'rejected') {
          cancelled++;
        } else {
          scheduled++;
        }

        if (date.isNotEmpty) {
          final shortDate = date.length >= 10 ? date.substring(5, 10) : date;
          trend[shortDate] = (trend[shortDate] ?? 0) + 1;
        }
      }

      // 2. Fetch reports count
      int reports = 0;
      try {
        final r = await Supabase.instance.client
            .from('careflow_reports')
            .select('id')
            .eq('clinic_id', clinicId);
        reports = (r as List).length;
      } catch (_) {}

      // 3. Fetch inventory low-stock
      int lowStock = 0;
      try {
        final inv = await Supabase.instance.client
            .from('careflow_inventory_items')
            .select('stock_quantity, reorder_threshold')
            .eq('clinic_id', clinicId);
        for (final item in (inv as List)) {
          final q = (item['stock_quantity'] as num?)?.toInt() ?? 0;
          final t = (item['reorder_threshold'] as num?)?.toInt() ?? 10;
          if (q <= t) lowStock++;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _scheduledCount = scheduled + checkedIn + completed;
          _checkedInCount = checkedIn;
          _completedCount = completed;
          _cancelledCount = cancelled;
          _totalBilled = billed;
          _totalCollected = collected;
          _outstandingBilled = (billed - collected).clamp(0.0, double.infinity);
          _reportsUploaded = reports;
          _lowStockCount = lowStock;
          _doctorWorkload = docWork;
          _dailyTrend = trend;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildMetricTile(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ColorTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: ColorTokens.navy),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Daily Clinic Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAnalytics,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAnalytics,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date Range Segment
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorTokens.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Today')),
                      selected: _selectedRange == 'today',
                      onSelected: (_) {
                        setState(() => _selectedRange = 'today');
                        _fetchAnalytics();
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Last 7 Days')),
                      selected: _selectedRange == '7_days',
                      onSelected: (_) {
                        setState(() => _selectedRange = '7_days');
                        _fetchAnalytics();
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('This Month')),
                      selected: _selectedRange == 'month',
                      onSelected: (_) {
                        setState(() => _selectedRange = 'month');
                        _fetchAnalytics();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Operational Metrics
              const Text(
                'Clinical Operations',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMetricTile('$_scheduledCount', 'Total Booked', ColorTokens.primaryBlue, Icons.calendar_month),
                  const SizedBox(width: 8),
                  _buildMetricTile('$_completedCount', 'Completed', ColorTokens.careGreen, Icons.check_circle_rounded),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMetricTile('$_checkedInCount', 'Waiting / Active', ColorTokens.warning, Icons.hourglass_top_rounded),
                  const SizedBox(width: 8),
                  _buildMetricTile('$_cancelledCount', 'Cancelled / Missed', ColorTokens.error, Icons.cancel_outlined),
                ],
              ),
              const SizedBox(height: 20),

              // Financial Metrics
              const Text(
                'Revenue & Billing',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMetricTile(
                    '₹${_totalBilled.toStringAsFixed(0)}',
                    'Total Invoiced',
                    ColorTokens.primaryBlue,
                    Icons.receipt_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricTile(
                    '₹${_totalCollected.toStringAsFixed(0)}',
                    'Payments Collected',
                    ColorTokens.careGreen,
                    Icons.payments_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMetricTile(
                    '₹${_outstandingBilled.toStringAsFixed(0)}',
                    'Outstanding Due',
                    ColorTokens.warning,
                    Icons.account_balance_wallet_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricTile(
                    '${_doctorWorkload.length}',
                    'Active Consult Doctors',
                    ColorTokens.navy,
                    Icons.medical_services_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Clinical Reports & Stock Alert
              const Text(
                'Reports & Pharmacy Stock',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMetricTile('$_reportsUploaded', 'Medical Reports', ColorTokens.navy, Icons.description_outlined),
                  const SizedBox(width: 8),
                  _buildMetricTile('$_lowStockCount', 'Low Stock SKUs', ColorTokens.error, Icons.inventory_2_outlined),
                ],
              ),
              const SizedBox(height: 20),

              // Volume Trend
              Card(
                elevation: 0,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Appointment Volume Distribution',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${_dailyTrend.length} date entries',
                            style: const TextStyle(fontSize: 12, color: ColorTokens.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_dailyTrend.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No appointment records found for this period.',
                              style: TextStyle(color: ColorTokens.muted, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 120,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: _dailyTrend.entries.map((e) {
                              final count = e.value;
                              final maxCount = _dailyTrend.values.reduce((a, b) => a > b ? a : b);
                              final heightPct = maxCount > 0 ? (count / maxCount).clamp(0.15, 1.0) : 0.2;

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Container(
                                        height: 70 * heightPct,
                                        decoration: BoxDecoration(
                                          color: ColorTokens.primaryBlue,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        e.key,
                                        style: const TextStyle(fontSize: 9.5, color: ColorTokens.muted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
