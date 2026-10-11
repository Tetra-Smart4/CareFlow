import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:careflow/widgets/common/lottie_animation.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _allAppointments = [];
  String _searchQuery = '';
  
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  String _statusFilter = 'All'; // All, Confirmed, Checked In, Completed, Cancelled

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _allAppointments = [];
        });
        return;
      }

      final data = await Supabase.instance.client
          .from('careflow_appointments')
          .select()
          .eq('doctor_id', user.id)
          .order('appointment_date', ascending: true)
          .order('appointment_time', ascending: true);

      final list = List<Map<String, dynamic>>.from(data);

      // Attach patient details
      final patientIds = list
          .map((e) => e['patient_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      if (patientIds.isNotEmpty) {
        final profiles = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name, phone, gender, age')
            .inFilter('id', patientIds);

        final pMap = <String, Map<String, dynamic>>{};
        for (final p in profiles) {
          pMap[p['id'].toString()] = p;
        }

        for (final appt in list) {
          final pId = appt['patient_id']?.toString();
          if (pId != null && pMap.containsKey(pId)) {
            appt['patient_name'] = pMap[pId]!['full_name'];
            appt['patient_phone'] = pMap[pId]!['phone'];
            appt['patient_gender'] = pMap[pId]!['gender'];
            appt['patient_age'] = pMap[pId]!['age'];
          }
        }
      }

      if (mounted) {
        setState(() {
          _allAppointments = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load appointments: $e';
        });
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final dayStr = day.toIso8601String().split('T').first;
    return _allAppointments.where((a) {
      return a['appointment_date']?.toString() == dayStr;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    if (_selectedDay == null) return [];
    
    var events = _getEventsForDay(_selectedDay!);
    
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      events = events.where((a) {
        final pName = (a['patient_name'] ?? '').toString().toLowerCase();
        final reason = (a['reason'] ?? '').toString().toLowerCase();
        return pName.contains(q) || reason.contains(q);
      }).toList();
    }
    
    if (_statusFilter != 'All') {
      events = events.where((a) {
        final status = (a['status'] ?? '').toString().toLowerCase();
        if (_statusFilter == 'Confirmed' && status == 'confirmed') return true;
        if (_statusFilter == 'Checked In' && (status == 'checked_in' || status == 'waiting' || status == 'called' || status == 'in_consultation')) return true;
        if (_statusFilter == 'Completed' && status == 'completed') return true;
        if (_statusFilter == 'Cancelled' && (status == 'cancelled' || status == 'rejected' || status == 'no_show')) return true;
        return false;
      }).toList();
    }
    
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doctor Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded),
            tooltip: 'Manage Availability',
            onPressed: () {
              Navigator.pushNamed(context, '/doctor/availability');
            },
          ),
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Today',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = _focusedDay;
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: _getEventsForDay,
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: ColorTokens.lightBlue,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: ColorTokens.primaryBlue, fontWeight: FontWeight.bold),
                selectedDecoration: BoxDecoration(
                  color: ColorTokens.primaryBlue,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: ColorTokens.careGreen,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonTextStyle: TextStyle(color: ColorTokens.primaryBlue, fontSize: 13),
                formatButtonDecoration: BoxDecoration(
                  color: ColorTokens.lightBlue,
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
              ),
            ),
          ),
          
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search patient...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: ColorTokens.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      icon: const Icon(Icons.filter_list, size: 18),
                      style: const TextStyle(fontSize: 13, color: ColorTokens.navy),
                      items: ['All', 'Confirmed', 'Checked In', 'Completed', 'Cancelled']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _statusFilter = v!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : RefreshIndicator(
                        onRefresh: _loadAppointments,
                        child: _filteredAppointments.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredAppointments.length,
                                itemBuilder: (ctx, i) => _buildAppointmentCard(_filteredAppointments[i])
                                    .animate()
                                    .fade(delay: (i * 50).ms, duration: 400.ms)
                                    .slideY(begin: 0.1, duration: 400.ms),
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            LottieAnimation(
              assetName: 'assets/animations/empty.json',
              width: 150,
              fallback: Icon(Icons.calendar_today_outlined, size: 48, color: ColorTokens.muted),
            ),
            SizedBox(height: 14),
            Text(
              'No Appointments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
            ),
            SizedBox(height: 6),
            Text(
              'There are no appointments matching your filters for this date.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColorTokens.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final patientName = appt['patient_name'] ?? 'Patient';
    final date = appt['appointment_date'] ?? '';
    final time = appt['appointment_time'] ?? '';
    final reason = appt['reason'] ?? 'Consultation';
    final token = (appt['token_number'] as num?)?.toInt() ?? 0;
    final status = (appt['status'] ?? 'pending').toString().toLowerCase();
    final gender = appt['patient_gender'] ?? '';
    final age = appt['patient_age']?.toString() ?? '';

    Color statusColor = ColorTokens.primaryBlue;
    Color statusBg = ColorTokens.lightBlue;
    String statusLabel = 'Confirmed';

    if (status == 'checked_in' || status == 'waiting') {
      statusColor = ColorTokens.warning;
      statusBg = ColorTokens.warning.withValues(alpha: 0.12);
      statusLabel = 'Waiting';
    } else if (status == 'called') {
      statusColor = ColorTokens.warning;
      statusBg = ColorTokens.warning.withValues(alpha: 0.15);
      statusLabel = 'Called';
    } else if (status == 'in_consultation') {
      statusColor = ColorTokens.careGreen;
      statusBg = ColorTokens.lightGreen;
      statusLabel = 'In Consultation';
    } else if (status == 'completed') {
      statusColor = ColorTokens.careGreen;
      statusBg = ColorTokens.lightGreen;
      statusLabel = 'Completed';
    } else if (status == 'cancelled' || status == 'rejected' || status == 'no_show') {
      statusColor = ColorTokens.error;
      statusBg = ColorTokens.error.withValues(alpha: 0.12);
      statusLabel = status == 'no_show' ? 'No-Show' : (status == 'rejected' ? 'Rejected' : 'Cancelled');
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ColorTokens.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/doctor/appointments/detail',
            arguments: appt,
          ).then((_) => _loadAppointments());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: ColorTokens.lightBlue,
                    child: Text(
                      patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ColorTokens.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: ColorTokens.darkNavy,
                          ),
                        ),
                        Text(
                          [if (age.isNotEmpty) '$age yrs', if (gender.isNotEmpty) gender]
                              .join(' • '),
                          style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
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
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: ColorTokens.textMuted),
                      const SizedBox(width: 5),
                      Text(
                        '$date • $time',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ColorTokens.darkNavy),
                      ),
                    ],
                  ),
                  if (token > 0)
                    Text(
                      'Token #$token',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ColorTokens.primaryBlue),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Reason: $reason',
                style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
