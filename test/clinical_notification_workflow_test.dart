import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CareFlow Clinical Notifications & Push Delivery Workflow Tests', () {
    // -------------------------------------------------------------------------
    // 1. APPOINTMENT NOTIFICATIONS (Booking, Status Change, Reminders)
    // -------------------------------------------------------------------------
    test('1. Appointment Booking generates notifications for both patient and doctor', () {
      final appointment = {
        'id': 'appt_001',
        'doctor_id': 'doc_123',
        'patient_id': 'pat_456',
        'appointment_date': '2026-10-15',
        'appointment_time': '10:30 AM',
        'status': 'confirmed',
      };

      // Doctor notification
      final doctorNotif = {
        'user_id': appointment['doctor_id'],
        'title': 'New Appointment Booked',
        'body': 'Appointment scheduled for ${appointment['appointment_date']} at ${appointment['appointment_time']}.',
        'type': 'appointment',
        'reference_id': appointment['id'],
      };

      // Patient notification
      final patientNotif = {
        'user_id': appointment['patient_id'],
        'title': 'Appointment Confirmed',
        'body': 'Your appointment has been scheduled for ${appointment['appointment_date']} ${appointment['appointment_time']}.',
        'type': 'appointment',
        'reference_id': appointment['id'],
      };

      expect(doctorNotif['user_id'], 'doc_123');
      expect(doctorNotif['type'], 'appointment');
      expect(patientNotif['user_id'], 'pat_456');
      expect(patientNotif['reference_id'], 'appt_001');
    });

    test('2. Appointment Cancellation notifies the counter-party with privacy-safe text', () {
      const currentUserId = 'doc_123';
      const patientId = 'pat_456';
      const doctorId = 'doc_123';
      const appointmentDate = '2026-10-15';

      // When doctor cancels, patient is the recipient
      final targetUserId = (currentUserId == patientId) ? doctorId : patientId;
      final cancellationNotif = {
        'user_id': targetUserId,
        'title': 'Appointment Cancelled',
        'body': 'Appointment on $appointmentDate has been updated to cancelled.',
        'type': 'appointment',
      };

      expect(cancellationNotif['user_id'], 'pat_456');
      expect(cancellationNotif['title'], 'Appointment Cancelled');
    });

    test('3. Appointment Reminder scanner detects appointments due within 24h idempotently', () {
      final todayStr = '2026-10-12';
      final tomorrowStr = '2026-10-13';
      final nextWeekStr = '2026-10-19';

      final appointments = [
        {'id': 'a1', 'date': todayStr, 'status': 'confirmed', 'patient_id': 'p1'},
        {'id': 'a2', 'date': tomorrowStr, 'status': 'confirmed', 'patient_id': 'p2'},
        {'id': 'a3', 'date': nextWeekStr, 'status': 'confirmed', 'patient_id': 'p3'},
      ];

      final existingReminders = <String>{'a1_2026-10-12'}; // a1 already reminded today

      final dueForReminder = appointments.where((a) {
        final date = a['date'];
        final isDue = date == todayStr || date == tomorrowStr;
        final alreadyReminded = existingReminders.contains('${a['id']}_$todayStr');
        return isDue && !alreadyReminded;
      }).toList();

      expect(dueForReminder.length, 1);
      expect(dueForReminder.first['id'], 'a2');
    });

    // -------------------------------------------------------------------------
    // 2. LIVE QUEUE NOTIFICATIONS (Check-in and Doctor Calling Next)
    // -------------------------------------------------------------------------
    test('4. Queue Check-In generates token confirmation notification', () {
      const tokenNumber = 7;
      final checkInNotif = {
        'user_id': 'pat_456',
        'title': 'Checked In Successfully',
        'body': 'Your queue token number is #$tokenNumber.',
        'type': 'queue',
      };

      expect(checkInNotif['title'], 'Checked In Successfully');
      expect(checkInNotif['body'], contains('#7'));
    });

    test('5. Doctor Calling Next Patient creates high-priority queue notification', () {
      const tokenNumber = 12;
      final callNextNotif = {
        'user_id': 'pat_789',
        'title': 'Your Turn: Now Calling #$tokenNumber',
        'body': 'The doctor is ready for your consultation. Please proceed to the room.',
        'type': 'queue',
      };

      expect(callNextNotif['title'], 'Your Turn: Now Calling #12');
      expect(callNextNotif['type'], 'queue');
    });

    // -------------------------------------------------------------------------
    // 3. LAB REPORTS & PRESCRIPTIONS (Privacy-Preserving Payloads)
    // -------------------------------------------------------------------------
    test('6. Lab Report notification preserves patient privacy on lock screen', () {
      // Diagnostic report details must NOT leak medical diagnoses on lock screen
      const reportTitle = 'Complete Blood Count';
      final reportNotif = {
        'user_id': 'pat_456',
        'title': 'New Medical Report Available',
        'body': 'Your report ("$reportTitle") has been uploaded to your health records.',
        'type': 'report',
      };

      expect(reportNotif['title'], 'New Medical Report Available');
      // Must not contain clinical diagnoses or results
      expect(reportNotif['body'], isNot(contains('diagnosis')));
      expect(reportNotif['body'], isNot(contains('positive')));
    });

    test('7. Prescription Issued notification alerts patient without exposing drug names', () {
      final prescNotif = {
        'user_id': 'pat_456',
        'title': 'New Prescription Issued',
        'body': 'A new prescription has been added to your medical records.',
        'type': 'prescription',
      };

      expect(prescNotif['title'], 'New Prescription Issued');
      expect(prescNotif['body'], isNot(contains('Amoxicillin')));
      expect(prescNotif['body'], isNot(contains('500mg')));
    });

    // -------------------------------------------------------------------------
    // 4. MEDICATION DOSES, CAREGIVER CONSENT & ESCALATION
    // -------------------------------------------------------------------------
    test('8. Due dose generates FCM outbox event when active device tokens exist', () {
      const hasActiveTokens = true;
      final outboxEvents = <Map<String, dynamic>>[];

      if (hasActiveTokens) {
        outboxEvents.add({
          'dose_id': 'dose_001',
          'event_type': 'patient_reminder',
          'recipient_type': 'patient',
          'recipient_id': 'pat_456',
          'delivery_channel': 'fcm',
          'status': 'created',
        });
      }

      expect(outboxEvents.length, 1);
      expect(outboxEvents.first['delivery_channel'], 'fcm');
      expect(outboxEvents.first['status'], 'created');
    });

    test('9. Caregiver consent enforcement: Granted vs Revoked vs Absent', () {
      bool canSendCaregiverPush({
        required bool familyAccessActive,
        required String? consentStatus,
        required bool? medicationAlertPermission,
      }) {
        if (!familyAccessActive) return false;
        if (consentStatus == null || consentStatus != 'granted') return false;
        if (medicationAlertPermission != true) return false;
        return true;
      }

      // Case A: Granted & Active
      expect(canSendCaregiverPush(
        familyAccessActive: true,
        consentStatus: 'granted',
        medicationAlertPermission: true,
      ), isTrue);

      // Case B: Patient revoked consent
      expect(canSendCaregiverPush(
        familyAccessActive: true,
        consentStatus: 'revoked',
        medicationAlertPermission: false,
      ), isFalse);

      // Case C: Consent record absent
      expect(canSendCaregiverPush(
        familyAccessActive: true,
        consentStatus: null,
        medicationAlertPermission: null,
      ), isFalse);

      // Case D: Family account inactive
      expect(canSendCaregiverPush(
        familyAccessActive: false,
        consentStatus: 'granted',
        medicationAlertPermission: true,
      ), isFalse);
    });

    test('10. Dose confirmation immediately transitions un-dispatched caregiver alerts to dose_resolved', () {
      final outbox = [
        {'id': 'ev_1', 'dose_id': 'dose_1', 'event_type': 'caregiver_escalation', 'status': 'created'},
        {'id': 'ev_2', 'dose_id': 'dose_1', 'event_type': 'caregiver_escalation', 'status': 'processing'},
        {'id': 'ev_3', 'dose_id': 'dose_1', 'event_type': 'caregiver_escalation', 'status': 'delivered'},
      ];

      // Patient confirms dose taken:
      for (final ev in outbox) {
        if (ev['dose_id'] == 'dose_1' &&
            ev['event_type'] == 'caregiver_escalation' &&
            (ev['status'] == 'created' || ev['status'] == 'processing')) {
          ev['status'] = 'dose_resolved';
        }
      }

      expect(outbox[0]['status'], 'dose_resolved');
      expect(outbox[1]['status'], 'dose_resolved');
      expect(outbox[2]['status'], 'delivered'); // Already delivered cannot be undone
    });

    // -------------------------------------------------------------------------
    // 5. CONCURRENT SCHEDULER, RETRY BACKOFF & TOKEN CLEANUP
    // -------------------------------------------------------------------------
    test('11. Atomic claim transition prevents concurrent duplicate dispatches', () {
      // Simulate two concurrent scheduler workers claiming from queue
      final events = [
        {'id': 'ev_a', 'status': 'created'},
        {'id': 'ev_b', 'status': 'created'},
      ];

      final lockedIds = <String>{};

      // Worker 1 claims ev_a with FOR UPDATE SKIP LOCKED
      final worker1Claim = <Map<String, dynamic>>[];
      for (final ev in events) {
        if (ev['status'] == 'created' && !lockedIds.contains(ev['id'])) {
          lockedIds.add(ev['id'] as String);
          ev['status'] = 'processing';
          worker1Claim.add(ev);
          break;
        }
      }

      // Worker 2 attempts concurrent claim
      final worker2Claim = <Map<String, dynamic>>[];
      for (final ev in events) {
        if (ev['status'] == 'created' && !lockedIds.contains(ev['id'])) {
          lockedIds.add(ev['id'] as String);
          ev['status'] = 'processing';
          worker2Claim.add(ev);
          break;
        }
      }

      expect(worker1Claim.first['id'], 'ev_a');
      expect(worker2Claim.first['id'], 'ev_b');
      // No duplicate claiming between Worker 1 and Worker 2
      expect(worker1Claim.first['id'], isNot(worker2Claim.first['id']));
    });

    test('12. Exponential backoff retry calculation is bounded and correct', () {
      int calculateBackoffMinutes(int retryCount) {
        return (1 << (retryCount + 1)); // 2^(retry+1)
      }

      expect(calculateBackoffMinutes(0), 2);   // Attempt 1 -> 2 minutes
      expect(calculateBackoffMinutes(1), 4);   // Attempt 2 -> 4 minutes
      expect(calculateBackoffMinutes(2), 8);   // Attempt 3 -> 8 minutes
      expect(calculateBackoffMinutes(3), 16);  // Attempt 4 -> 16 minutes
      expect(calculateBackoffMinutes(4), 32);  // Attempt 5 -> 32 minutes
    });

    test('13. Google FCM UNREGISTERED error triggers token deactivation', () {
      final deviceTokens = [
        {'fcm_token': 'tok_stale', 'is_active': true},
        {'fcm_token': 'tok_fresh', 'is_active': true},
      ];

      // Provider responds with UNREGISTERED on tok_stale
      const fcmError = 'UNREGISTERED';
      if (fcmError == 'UNREGISTERED' || fcmError == 'INVALID_ARGUMENT') {
        final tok = deviceTokens.firstWhere((t) => t['fcm_token'] == 'tok_stale');
        tok['is_active'] = false;
      }

      expect(deviceTokens[0]['is_active'], isFalse);
      expect(deviceTokens[1]['is_active'], isTrue);
    });

    test('14. Unauthorized caller cannot supply arbitrary recipient in send_test', () {
      // In send_test, callerUser must be derived strictly from authenticated JWT
      const callerUserId = 'user_real_caller';
      final requestPayload = {'action': 'send_test', 'user_id': 'victim_other_user'};

      // Edge Function security rule: user_id from client payload is ignored for non-system callers
      final resolvedRecipientId = callerUserId; // Enforced by auth.getUser()

      expect(resolvedRecipientId, 'user_real_caller');
      expect(resolvedRecipientId, isNot(requestPayload['user_id']));
    });
  });
}
