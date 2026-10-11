import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'medication_reminder_service.dart';

/// Top-level background message handler required by FirebaseMessaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('FCM background message received: ${message.messageId}');
}

class PushNotificationEvent {
  final String title;
  final String body;
  final String? doseId;
  final String? type;
  final Map<String, dynamic> payload;

  const PushNotificationEvent({
    required this.title,
    required this.body,
    this.doseId,
    this.type,
    this.payload = const {},
  });
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  /// Global navigator key shared from app router for deep link navigation
  static GlobalKey<NavigatorState>? navigatorKey;

  final _reminderService = MedicationReminderService();
  final _eventController = StreamController<PushNotificationEvent>.broadcast();

  Stream<PushNotificationEvent> get onNotificationReceived => _eventController.stream;

  String? _currentToken;
  String? _lastRegisteredUserId;
  bool _isConfigured = false;
  bool _isFirebaseInitialized = false;

  bool get isConfigured => _isConfigured;
  bool get isFirebaseInitialized => _isFirebaseInitialized;
  String? get currentToken => _currentToken;

  /// Initializes Firebase, requests permissions, and registers genuine FCM device token
  Future<void> initialize() async {
    try {
      // 1. Initialize Firebase App safely
      try {
        await Firebase.initializeApp();
        _isFirebaseInitialized = true;
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      } catch (fbErr) {
        debugPrint('Firebase.initializeApp warning (platform may use fallback): $fbErr');
      }

      // 2. Configure Firebase Messaging if initialized
      if (_isFirebaseInitialized) {
        // Request notification permission for Android 13+ / iOS
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        debugPrint('FCM Authorization status: ${settings.authorizationStatus}');

        // Set foreground presentation options to display banners and play sound natively
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // 3. Retrieve genuine FCM registration token
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          debugPrint('Genuine FCM device token acquired: ${token.substring(0, 10)}...');
          await registerDeviceToken(token);
        }

        // 4. Listen to token refresh events
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          debugPrint('FCM device token refreshed');
          await registerDeviceToken(newToken);
        });

        // 5. Listen to foreground messages and broadcast into application stream
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          showLocal(
            title: notification?.title ?? message.data['title'] ?? 'CareFlow Alert',
            body: notification?.body ?? message.data['body'] ?? '',
            doseId: message.data['dose_id']?.toString(),
            type: message.data['type']?.toString(),
            payload: message.data,
          );
        });

        // 6. Handle notification tap when opened from background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleRemoteMessageNavigation(message);
        });

        // 7. Handle notification tap when launched from terminated state
        final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          _handleRemoteMessageNavigation(initialMessage);
        }
      }

      // 8. Listen to Supabase auth state changes for safe account transitions
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
          if (_currentToken != null) {
            await registerDeviceToken(_currentToken!);
          } else if (_isFirebaseInitialized) {
            try {
              final token = await FirebaseMessaging.instance.getToken();
              if (token != null && token.isNotEmpty) {
                await registerDeviceToken(token);
              }
            } catch (_) {}
          }
        } else if (event == AuthChangeEvent.signedOut) {
          await deactivateDeviceToken();
        }
      });
    } catch (e) {
      debugPrint('PushNotificationService initialization error: $e');
    }
  }

  User? _getSafeCurrentUser() {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Registers genuine FCM device token in Supabase careflow_device_tokens table
  Future<void> registerDeviceToken(String token, {String platform = 'android'}) async {
    if (token.trim().isEmpty) return;
    _currentToken = token;
    final user = _getSafeCurrentUser();
    if (user == null) return;
    _lastRegisteredUserId = user.id;

    try {
      await Supabase.instance.client.rpc(
        'careflow_register_device_token',
        params: {'p_token': token, 'p_platform': platform},
      );
      _isConfigured = true;
    } catch (_) {
      try {
        await Supabase.instance.client.from('careflow_device_tokens').upsert({
          'user_id': user.id,
          'fcm_token': token,
          'platform': platform,
          'is_active': true,
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        });
        _isConfigured = true;
      } catch (err) {
        debugPrint('Token registration fallback error: $err');
      }
    }
  }

  /// Deactivates token on logout to prevent notifications routing to wrong user
  Future<void> deactivateDeviceToken() async {
    final tokenToDeactivate = _currentToken;
    if (tokenToDeactivate == null || tokenToDeactivate.trim().isEmpty) {
      _currentToken = null;
      _lastRegisteredUserId = null;
      _isConfigured = false;
      return;
    }

    try {
      await Supabase.instance.client.rpc(
        'careflow_deactivate_device_token',
        params: {'p_token': tokenToDeactivate},
      );
    } catch (_) {
      try {
        final user = _getSafeCurrentUser();
        final targetUserId = user?.id ?? _lastRegisteredUserId;
        if (targetUserId != null) {
          await Supabase.instance.client
              .from('careflow_device_tokens')
              .update({'is_active': false})
              .eq('user_id', targetUserId)
              .eq('fcm_token', tokenToDeactivate);
        }
      } catch (e) {
        debugPrint('Error deactivating device token: $e');
      }
    } finally {
      _currentToken = null;
      _lastRegisteredUserId = null;
      _isConfigured = false;
    }
  }

  /// Dispatches a notification event into the stream for foreground display & handlers
  void showLocal({
    required String title,
    required String body,
    String? doseId,
    String? type,
    Map<String, dynamic> payload = const {},
  }) {
    _eventController.add(PushNotificationEvent(
      title: title,
      body: body,
      doseId: doseId,
      type: type,
      payload: payload,
    ));
  }

  /// Handles "Taken" action directly from a notification tap
  Future<Map<String, dynamic>> handleActionTaken(String doseId) async {
    return await _reminderService.markTaken(doseId);
  }

  /// Handles "Not taken" action directly from a notification tap
  Future<Map<String, dynamic>> handleActionNotTaken(String doseId, {String? reason}) async {
    return await _reminderService.markNotTaken(doseId, reason: reason);
  }

  /// Dispatches an isolated test push notification to this authenticated account's active device
  Future<Map<String, dynamic>> sendTestNotification({
    String title = 'CareFlow Test',
    String body = 'Push notification delivery verified.',
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return {'success': false, 'error': 'Must be signed in to send test push notification'};
    }

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'medication-scheduler',
        body: {
          'action': 'send_test',
          'title': title,
          'body': body,
        },
      );

      if (res.status == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      } else {
        final err = (res.data is Map && res.data['error'] != null)
            ? res.data['error'].toString()
            : 'Edge function returned status ${res.status}';
        return {'success': false, 'error': err};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  void _handleRemoteMessageNavigation(RemoteMessage message) {
    final data = message.data;
    debugPrint('Tapped notification with data: $data');
    final doseId = data['dose_id'];
    final type = data['type']?.toString();

    _eventController.add(PushNotificationEvent(
      title: message.notification?.title ?? data['title'] ?? 'Notification',
      body: message.notification?.body ?? data['body'] ?? '',
      doseId: doseId?.toString(),
      type: type,
      payload: data,
    ));

    // Deep link navigation with safe authorization routing
    final nav = navigatorKey?.currentState;
    if (nav != null) {
      if (type == 'caregiver_escalation' || type == 'caregiver_alert') {
        nav.pushNamed('/family/dashboard');
      } else if (type == 'patient_reminder' || type == 'medication_reminder' || doseId != null) {
        nav.pushNamed('/patient/medications/reminder');
      } else if (type == 'appointment') {
        nav.pushNamed('/patient/appointments');
      } else if (type == 'queue') {
        nav.pushNamed('/patient/queue');
      } else if (type == 'report') {
        nav.pushNamed('/patient/reports');
      } else if (type == 'prescription') {
        nav.pushNamed('/patient/prescriptions');
      } else {
        nav.pushNamed('/notifications');
      }
    }
  }
}
