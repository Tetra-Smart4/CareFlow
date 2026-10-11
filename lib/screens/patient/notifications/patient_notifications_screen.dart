import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/notification_repository.dart';

class PatientNotificationsScreen extends StatefulWidget {
  const PatientNotificationsScreen({super.key});

  @override
  State<PatientNotificationsScreen> createState() => _PatientNotificationsScreenState();
}

class _PatientNotificationsScreenState extends State<PatientNotificationsScreen> {
  final _notifRepo = NotificationRepository();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
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
    _loadNotifications();
  }

  Future<void> _markAllRead() async {
    await _notifRepo.markAllAsRead();
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Notifications'),
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
                                'You will receive notifications here about appointments, queue status, and health records.',
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

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: isRead ? Colors.white : ColorTokens.lightBlue.withValues(alpha: 0.4),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isRead ? ColorTokens.background : ColorTokens.lightBlue,
                                child: Icon(
                                  Icons.notifications_rounded,
                                  color: isRead ? ColorTokens.muted : ColorTokens.primaryBlue,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
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
                                  if (message.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      message,
                                      style: const TextStyle(fontSize: 13, color: ColorTokens.navy),
                                    ),
                                  ],
                                  if (dateStr.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      dateStr.substring(0, dateStr.length >= 10 ? 10 : dateStr.length),
                                      style: const TextStyle(fontSize: 11, color: ColorTokens.muted),
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                if (!isRead) _markRead(id);
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
