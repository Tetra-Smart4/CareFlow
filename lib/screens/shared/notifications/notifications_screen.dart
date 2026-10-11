import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/notification_repository.dart';
import '../../../services/push_notification_service.dart';
import 'package:careflow/widgets/common/lottie_animation.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repository = NotificationRepository();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _notifications = [];
  String _activeFilter = 'all'; // 'all', 'unread', 'alerts'

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
      final list = await _repository.list();
      if (mounted) {
        setState(() {
          _notifications = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load notifications.';
        });
      }
    }
  }

  Future<void> _markRead(String id) async {
    await _repository.markAsRead(id);
    setState(() {
      final idx = _notifications.indexWhere((n) => n['id']?.toString() == id);
      if (idx != -1) {
        _notifications[idx]['is_read'] = true;
      }
    });
  }

  Future<void> _markAllRead() async {
    await _repository.markAllAsRead();
    setState(() {
      for (final n in _notifications) {
        n['is_read'] = true;
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read.')),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Dispatching test push notification via FCM v1...')),
    );

    final res = await PushNotificationService().sendTestNotification();
    if (!mounted) return;

    if (res['success'] == true) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: ColorTokens.careGreen),
              SizedBox(width: 8),
              Text('Test Dispatched'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FCM HTTP v1 dispatch was successful! Check device tray.'),
              const SizedBox(height: 12),
              Text('Message ID: ${res['fcm_message_id'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
              const SizedBox(height: 6),
              Text('Masked Token: ${res['masked_token'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: ColorTokens.error),
              SizedBox(width: 8),
              Text('Test Dispatch Failed'),
            ],
          ),
          content: Text(res['error']?.toString() ?? 'Failed to send test push notification.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_activeFilter == 'unread') {
      return _notifications.where((n) => n['is_read'] != true).toList();
    } else if (_activeFilter == 'alerts') {
      return _notifications.where((n) => n['type'] == 'caregiver_alert' || n['type'] == 'medication_reminder').toList();
    }
    return _notifications;
  }

  void _onNotificationTap(Map<String, dynamic> notification) {
    final id = notification['id']?.toString();
    if (id != null) _markRead(id);

    final type = notification['type']?.toString();
    final doseId = notification['dose_id']?.toString();

    if (type == 'caregiver_alert') {
      Navigator.pushNamed(context, '/family/dashboard');
    } else if (type == 'medication_reminder' || doseId != null) {
      Navigator.pushNamed(context, '/patient/medications/reminder');
    } else if (type == 'appointment') {
      Navigator.pushNamed(context, '/patient/appointments');
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'caregiver_alert':
        return Icons.notification_important_rounded;
      case 'medication_reminder':
        return Icons.medication_rounded;
      case 'appointment':
        return Icons.calendar_today_rounded;
      case 'queue':
        return Icons.confirmation_number_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'caregiver_alert':
        return ColorTokens.error;
      case 'medication_reminder':
        return ColorTokens.primaryBlue;
      case 'appointment':
        return ColorTokens.careGreen;
      case 'queue':
        return Colors.orange;
      default:
        return ColorTokens.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['is_read'] != true).length;

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          IconButton(
            icon: const Icon(Icons.send_to_mobile_rounded),
            onPressed: _loading ? null : _sendTestNotification,
            tooltip: 'Send Test Push Notification',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('All (${_notifications.length})', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Unread ($unreadCount)', 'unread'),
                const SizedBox(width: 8),
                _buildFilterChip('Medication Alerts', 'alerts'),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
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
                        ),
                      )
                    : _filteredNotifications.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _loadNotifications,
                            child: ListView(
                              padding: const EdgeInsets.all(32),
                              children: const [
                                SizedBox(height: 60),
                                LottieAnimation(
                                  assetName: 'assets/animations/empty.json',
                                  width: 120,
                                  fallback: Icon(Icons.notifications_off_outlined, size: 56, color: ColorTokens.muted),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No Notifications',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ColorTokens.darkNavy),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'You have no notifications matching this filter.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: ColorTokens.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadNotifications,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredNotifications.length,
                              itemBuilder: (ctx, i) {
                                final n = _filteredNotifications[i];
                                final isRead = n['is_read'] == true;
                                final type = n['type']?.toString();
                                final color = _getColorForType(type);
                                final icon = _getIconForType(type);
                                final title = n['title']?.toString() ?? 'CareFlow Notification';
                                final body = n['body']?.toString() ?? (n['message']?.toString() ?? '');
                                final dateStr = n['created_at']?.toString() ?? '';

                                String timeLabel = '';
                                if (dateStr.isNotEmpty) {
                                  try {
                                    final dt = DateTime.parse(dateStr).toLocal();
                                    timeLabel = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                  } catch (_) {}
                                }

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: isRead ? ColorTokens.border : color.withAlpha(120),
                                      width: isRead ? 1 : 1.5,
                                    ),
                                  ),
                                  color: isRead ? Colors.white : color.withAlpha(10),
                                  child: ListTile(
                                    onTap: () => _onNotificationTap(n),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: color.withAlpha(26),
                                      child: Icon(icon, color: color, size: 22),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                              color: ColorTokens.darkNavy,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(left: 6),
                                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                          ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(body, style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
                                        if (timeLabel.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(timeLabel, style: const TextStyle(fontSize: 11, color: ColorTokens.muted)),
                                        ],
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right, size: 18, color: ColorTokens.muted),
                                  ),
                                ).animate().fade(delay: (i * 30).ms, duration: 300.ms);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _activeFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      selected: isSelected,
      selectedColor: ColorTokens.lightBlue,
      onSelected: (_) => setState(() => _activeFilter = value),
    );
  }
}
