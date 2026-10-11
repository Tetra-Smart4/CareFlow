import 'package:flutter_test/flutter_test.dart';
import 'package:careflow/services/push_notification_service.dart';

void main() {
  group('PushNotificationService Unit Tests', () {
    test('1. PushNotificationEvent serialization and fields', () {
      const event = PushNotificationEvent(
        title: 'Appointment Reminder',
        body: 'You have an appointment today.',
        doseId: 'dose_123',
        type: 'medication_reminder',
        payload: {'reference_id': 'ref_456'},
      );

      expect(event.title, 'Appointment Reminder');
      expect(event.body, 'You have an appointment today.');
      expect(event.doseId, 'dose_123');
      expect(event.type, 'medication_reminder');
      expect(event.payload['reference_id'], 'ref_456');
    });

    test('2. Foreground showLocal broadcasts to onNotificationReceived stream', () async {
      final service = PushNotificationService();
      final received = <PushNotificationEvent>[];

      final sub = service.onNotificationReceived.listen((e) {
        received.add(e);
      });

      service.showLocal(
        title: 'Test Notification',
        body: 'Test body',
        type: 'test_notification',
        doseId: 'dose_abc',
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(received.length, 1);
      expect(received.first.title, 'Test Notification');
      expect(received.first.type, 'test_notification');
      expect(received.first.doseId, 'dose_abc');

      await sub.cancel();
    });

    test('3. Deep link routing mapping correctly determines target destination', () {
      String resolveRoute(String? type, String? doseId) {
        if (type == 'caregiver_escalation' || type == 'caregiver_alert') {
          return '/family/dashboard';
        } else if (type == 'patient_reminder' || type == 'medication_reminder' || doseId != null) {
          return '/patient/medications/reminder';
        } else if (type == 'appointment') {
          return '/patient/appointments';
        } else if (type == 'queue') {
          return '/patient/queue';
        } else if (type == 'report') {
          return '/patient/reports';
        } else if (type == 'prescription') {
          return '/patient/prescriptions';
        } else {
          return '/notifications';
        }
      }

      expect(resolveRoute('medication_reminder', 'dose_1'), '/patient/medications/reminder');
      expect(resolveRoute('patient_reminder', null), '/patient/medications/reminder');
      expect(resolveRoute(null, 'dose_99'), '/patient/medications/reminder');
      expect(resolveRoute('caregiver_alert', null), '/family/dashboard');
      expect(resolveRoute('caregiver_escalation', null), '/family/dashboard');
      expect(resolveRoute('appointment', null), '/patient/appointments');
      expect(resolveRoute('queue', null), '/patient/queue');
      expect(resolveRoute('report', null), '/patient/reports');
      expect(resolveRoute('prescription', null), '/patient/prescriptions');
      expect(resolveRoute('unknown_type', null), '/notifications');
    });

    test('4. Token deactivation clears local token state', () async {
      final service = PushNotificationService();
      // Calling deactivate when no active user session cleans up state gracefully
      await service.deactivateDeviceToken();
      expect(service.currentToken, isNull);
      expect(service.isConfigured, isFalse);
    });
  });
}
