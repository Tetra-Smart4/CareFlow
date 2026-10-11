import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/notification_repository.dart';
import '../../../services/realtime_service.dart';

class DoctorNotificationsScreen extends StatefulWidget {
  const DoctorNotificationsScreen({super.key});

  @override
  State<DoctorNotificationsScreen> createState() => _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState extends State<DoctorNotificationsScreen> {
  final _notifRepo = NotificationRepository();
  StreamSubscription? _sub;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupRealtime();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _setupRealtime() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      _sub = RealtimeService().watchNotifications(uid).listen((list) {
        if (mounted) {
          setState(() {
            _notifications = list;
            _loading = false;
          });
        }
      }, onError: (e) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Unable to load notifications.';
          });
        }
      });
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _notifRepo.list();
      if (mounted) {
        setState(() {
          _notifications = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load notifications.';
        });
      }
    }
  }

  Future<void> _markRead(String id) async {
    await _notifRepo.markAsRead(id);
    // Realtime stream will auto-update the UI
  }

  Future<void> _markAllRead() async {
    await _notifRepo.markAllAsRead();
    // Realtime stream will auto-update the UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Doctor Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
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
                        ElevatedButton(onPressed: _loadNotifications, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.notifications_none_rounded, size: 56, color: ColorTokens.muted),
                              SizedBox(height: 12),
                              Text(
                                'No notifications yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: ColorTokens.navy,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'You will be notified when patients book appointments, check in, or when follow-ups are due.',
                                style: TextStyle(color: ColorTokens.muted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final id = item['id'].toString();
                          final title = item['title'] ?? 'Notification';
                          final message = item['message'] ?? item['body'] ?? '';
                          final isRead = item['is_read'] == true;
                          final dateStr = item['created_at']?.toString() ?? '';
                          final refId = item['reference_id']?.toString();
                          
                          // Enriched data from repository
                          final patientName = item['patient_name']?.toString();
                          final apptDate = item['appointment_date']?.toString();
                          final apptTime = item['appointment_time']?.toString();

                          // Fallback handling
                          final bool isEnriched = patientName != null && apptDate != null && apptTime != null;
                          final displayTitle = isEnriched ? 'New Appointment Booked' : title;
                          final displayDesc = isEnriched 
                              ? ' booked an appointment with you.' 
                              : message;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: isRead ? Colors.white : ColorTokens.lightBlue.withValues(alpha: 0.4),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isRead ? ColorTokens.background : ColorTokens.lightBlue,
                                child: Icon(
                                  Icons.medical_services_outlined,
                                  color: isRead ? ColorTokens.muted : ColorTokens.primaryBlue,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayTitle,
                                      style: TextStyle(
                                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                        fontSize: 15,
                                        color: ColorTokens.navy,
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: ColorTokens.primaryBlue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  if (isEnriched)
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 14, color: ColorTokens.navy),
                                        children: [
                                          TextSpan(
                                            text: patientName,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(text: displayDesc),
                                        ],
                                      ),
                                    )
                                  else if (displayDesc.isNotEmpty)
                                    Text(
                                      displayDesc, 
                                      style: const TextStyle(fontSize: 14, color: ColorTokens.navy),
                                    ),
                                    
                                  if (isEnriched) ...[
                                    const SizedBox(height: 8),
                                    Text('Date: $apptDate', style: const TextStyle(fontSize: 13, color: ColorTokens.navy)),
                                    const SizedBox(height: 2),
                                    Text('Time: $apptTime', style: const TextStyle(fontSize: 13, color: ColorTokens.navy)),
                                  ],
                                    
                                  if (!isEnriched) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: ColorTokens.background,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Older Notification', style: TextStyle(fontSize: 10, color: ColorTokens.muted)),
                                    ),
                                  ],
                                    
                                  if (dateStr.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Received: ${dateStr.substring(0, dateStr.length >= 10 ? 10 : dateStr.length)}',
                                      style: const TextStyle(fontSize: 11, color: ColorTokens.muted),
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                if (!isRead) _markRead(id);
                                if (refId != null && refId.isNotEmpty) {
                                  if (item['type'] == 'appointment' || item['type'] == 'queue') {
                                    Navigator.pushNamed(
                                      context,
                                      '/doctor/appointments/detail',
                                      arguments: {'appointment_id': refId},
                                    );
                                  } else if (item['type'] == 'health' || item['type'] == 'report') {
                                    Navigator.pushNamed(context, '/doctor/patients');
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
