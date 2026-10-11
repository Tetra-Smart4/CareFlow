import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/medical_record_repository.dart';
import '../../../repositories/prescription_repository.dart';
import '../../../repositories/report_repository.dart';

class TimelineEvent {
  final DateTime date;
  final String type; // 'consultation', 'prescription', 'report'
  final dynamic data;
  TimelineEvent({required this.date, required this.type, required this.data});
}

class HealthTimelineScreen extends StatefulWidget {
  const HealthTimelineScreen({super.key});

  @override
  State<HealthTimelineScreen> createState() => _HealthTimelineScreenState();
}

class _HealthTimelineScreenState extends State<HealthTimelineScreen> {
  bool _loading = true;
  String? _error;
  List<TimelineEvent> _allEvents = [];
  List<TimelineEvent> _filteredEvents = [];

  String _searchQuery = '';
  String _selectedType = 'All';

  final _recordRepo = MedicalRecordRepository();
  final _prescRepo = PrescriptionRepository();
  final _reportRepo = ReportRepository();

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final consults = await _recordRepo.list(patientId: user.id);
      final prescs = await _prescRepo.list(patientId: user.id);
      final reports = await _reportRepo.listForPatient(user.id);

      List<TimelineEvent> events = [];

      for (var c in consults) {
        final dStr = c['created_at']?.toString() ?? c['consultation_date']?.toString();
        if (dStr != null) {
          events.add(TimelineEvent(date: DateTime.tryParse(dStr) ?? DateTime.now(), type: 'consultation', data: c));
        }
      }
      for (var p in prescs) {
        final dStr = p['created_at']?.toString();
        if (dStr != null) {
          events.add(TimelineEvent(date: DateTime.tryParse(dStr) ?? DateTime.now(), type: 'prescription', data: p));
        }
      }
      for (var r in reports) {
        events.add(TimelineEvent(date: DateTime.tryParse(r.reportDate) ?? DateTime.now(), type: 'report', data: r));
      }

      events.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _allEvents = events;
          _filteredEvents = events;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load health timeline: $e';
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredEvents = _allEvents.where((e) {
        bool matchesType = _selectedType == 'All' || e.type.toLowerCase() == _selectedType.toLowerCase();
        
        bool matchesSearch = false;
        if (_searchQuery.isEmpty) {
          matchesSearch = true;
        } else {
          final q = _searchQuery.toLowerCase();
          if (e.type == 'consultation') {
            final c = e.data;
            matchesSearch = (c['diagnosis']?.toString().toLowerCase().contains(q) ?? false) ||
                            (c['symptoms']?.toString().toLowerCase().contains(q) ?? false);
          } else if (e.type == 'prescription') {
            final p = e.data;
            matchesSearch = (p['medicine_name']?.toString().toLowerCase().contains(q) ?? false);
          } else if (e.type == 'report') {
            final r = e.data;
            matchesSearch = r.title.toLowerCase().contains(q) || r.reportType.toLowerCase().contains(q);
          }
        }
        return matchesType && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Lifetime Health Timeline'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadTimeline,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search diagnosis, medicine, or report...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedType,
                  items: ['All', 'Consultation', 'Prescription', 'Report']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      _selectedType = val;
                      _applyFilters();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTimeline,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: ColorTokens.error)))
                      : _filteredEvents.isEmpty
                          ? const Center(child: Text('No records found.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredEvents.length,
                              itemBuilder: (context, index) {
                                final event = _filteredEvents[index];
                                return _buildEventCard(event);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(TimelineEvent event) {
    IconData icon;
    Color color;
    String title;
    String subtitle;
    
    final dateStr = "${event.date.year}-${event.date.month.toString().padLeft(2,'0')}-${event.date.day.toString().padLeft(2,'0')}";

    if (event.type == 'consultation') {
      icon = Icons.medical_information_outlined;
      color = ColorTokens.primaryBlue;
      title = event.data['diagnosis'] ?? 'Consultation';
      subtitle = 'Symptoms: ${event.data['symptoms'] ?? 'None'}';
    } else if (event.type == 'prescription') {
      icon = Icons.medication_outlined;
      color = ColorTokens.careGreen;
      title = 'Prescription: ${event.data['medicine_name']}';
      subtitle = '${event.data['dosage']} • ${event.data['frequency']}';
    } else {
      icon = Icons.description_outlined;
      color = Colors.orange;
      title = event.data.title;
      subtitle = event.data.reportType;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(26),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: ColorTokens.navy)),
        subtitle: Text('$dateStr\n$subtitle'),
        isThreeLine: true,
      ),
    );
  }
}
