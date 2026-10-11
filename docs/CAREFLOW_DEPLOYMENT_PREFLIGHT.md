# CareFlow — Production Readiness & Deployment Preflight Report

**Project**: CareFlow — Clinic Management System  
**Tagline**: *From manual clinic workflows to real-time connected care.*  
**Date of Audit**: 2026-10-11  
**Auditor**: Antigravity Autonomous Engineering Agent  
**Environment**: Windows 11, Flutter SDK 3.47.6 / Dart 3.13.5, Supabase CLI 2.119.0, Android SDK API 35/37.

---

## 1. Environment & Target Verification

| Component | Status | Details / Evidence |
| :--- | :---: | :--- |
| **Supabase Linked Project** | **VERIFIED** | Linked project reference: `cwzymgamqijeoeqnnkvc` (`https://cwzymgamqijeoeqnnkvc.supabase.co`). Verified against `supabase/.temp/project-ref` and `lib/core/config/supabase_config.dart`. |
| **Database Connectivity** | **ONLINE** | Active connection confirmed via PostgREST and Supabase Management API. |
| **Git Working Tree** | **INSPECTED** | Branch: `main`. Uncommitted local enhancements preserved. Zero dropped user files. |
| **Connected Physical Device** | **UNATTACHED** | `adb devices` reports no physical hardware currently connected via USB/WiFi. One Android Virtual Device (`Medium_Phone_API_37.0`) is configured locally. |

---

## 2. Supabase Migration History & Consistency Preflight

A live comparison of local migration files (`supabase/migrations/`) against the remote database migration registry (`supabase_migrations.schema_migrations`) revealed the following statuses:

### Migration Matrix

| Migration Version | Description | Local Status | Remote Status | Assessment |
| :--- | :--- | :---: | :---: | :--- |
| `20261008000000` | Core Schema (`profiles`, `clinics`, `appointments`) | Present | **Applied** | In sync |
| `20261008000001` | Reports & Queue Workflow | Present | **Applied** | In sync |
| `20261008000002` | Scheduling & Slots | Present | **Applied** | In sync |
| `20261008000003` | QR Check-in Core | Present | **Applied** | In sync |
| `20261008183633` | Fix QR Check-in Queue Workflow | Present | **Applied** | In sync |
| `20261009000001` | Calendar & Notifications (Initial version) | Present | **MISSING** | **INCONSISTENCY DETECTED** (See Section 3) |
| `20261009000005` | Fix QR Check-in Workflow 2 | Present | **Applied** | In sync |
| `20261009000006` | Medication Adherence Core | Present | **Applied** | In sync |
| `20261009000007` | Calendar & Notifications (Deduplication fix) | Present | **Applied** | Superseded `20261009000001` remotely |
| `20261009000008` | Doctor Availability | Present | **Applied** | In sync |
| `20261010000001` | Fix Missing QR Token | Present | **Applied** | In sync |
| `20261010000002` | Secure Authorization | Present | **Applied** | In sync (Latest applied remote: `20261010000002`) |
| `20261010000003` | Admin Escalation & Queue Hardening | Present | **PENDING** | Local only; ready for push |
| `20261011000000` | Doctor Record Access Grants | Present | **PENDING** | Local only; ready for push |
| `20261011000001` | Medical History Access Fix | Present | **PENDING** | Local only; ready for push |
| `20261011000002` | Smart Medication Reminder & Caregiver Alerts | Present | **PENDING** | Local only; ready for push |
| `20261011000003` | Permanent Medical History & Record Retention | Present | **PENDING** | Local only; ready for push |

---

## 3. Detailed Root-Cause Analysis of Discrepancies

### A. The `20261009000001` vs `20261009000007` Conflict
- **What Happened**: During historical deployment on October 9, migration `20261009000001` attempted to create a unique index on `careflow_appointments(doctor_id, appointment_date, appointment_time)`. Because duplicate records already existed in the database, the index creation failed. A revised migration `20261009000007` was subsequently written to first cancel duplicate appointments before applying the unique index, and was successfully pushed to remote.
- **Current Issue**: The old file `20261009000001_careflow_calendar_and_notifications.sql` remained in the local `supabase/migrations/` directory. When running `supabase db push --dry-run`, the CLI reports:
  ```json
  "DbPushMissingRemoteError": "Found local migration files to be inserted before the last migration on remote database."
  ```
- **Rule Enforcement**: Per Phase 2 rules ("Do not use `--include-all` or migration repair as a shortcut for unresolved migration history. If the migration history is inconsistent, stop and explain the discrepancy before changing anything."), we stop and report this exact finding.
- **Resolution Plan**: Safely archive the redundant, superseded local file `20261009000001_careflow_calendar_and_notifications.sql` to `supabase/migrations/.archive/`. Once archived, local migration timestamps strictly start at `20261010000003` (after the remote's latest `20261010000002`), allowing clean, sequential, forward-only deployment without `--include-all` or history alteration.

### B. Dependency Order of Pending Migrations
The 5 pending migrations exhibit the following strict dependency chain:
1. `20261010000003`: Hardens `careflow_clinic_scan_qr` and clinic status triggers on `clinics` and `profiles`.
2. `20261011000000`: Creates `careflow_doctor_access_grants` table and `careflow_has_active_access()` function.
3. `20261011000001`: Hardens `careflow_has_active_access()` with `search_path = public` and caller validation.
4. `20261011000002`: Expands `careflow_prescriptions`, creates `careflow_family_access`, `careflow_medication_alert_consents`, `careflow_device_tokens`, and `careflow_medication_alert_events`. Adds dose generation and response RPCs.
5. `20261011000003`: Creates `careflow_patient_medical_history`, `careflow_audit_logs`, and non-deletion triggers. **Calls `public.careflow_has_active_access()`**, therefore requiring `20261011000001` to be applied prior.

---

## 4. Edge Function & Scheduler Audit (`medication-scheduler`)

- **Current Implementation**: `supabase/functions/medication-scheduler/index.ts` calls `careflow_claim_and_process_due_doses(50)`.
- **Gaps Identified for Production Readiness**:
  1. *Missing Authorization Guard*: The endpoint currently responds to unauthenticated requests. It must enforce `Authorization: Bearer <service-role-or-cron-secret>`.
  2. *Durable Outbox Retry Strategy*: Events with temporary delivery errors need a calculated exponential backoff (`next_retry_at = now() + (2 ^ retry_count * interval '1 minute')`), with a max retry ceiling of 5 attempts.
  3. *Re-checking Consent Prior to Push*: Although `careflow_claim_and_process_due_doses` filters by active consent when queueing, a patient might revoke consent in the interim. The dispatcher must verify active consent at the instant of external push delivery.
  4. *Reliable Scheduling Strategy*: Use Supabase `pg_cron` with `pg_net` or native scheduled Edge Function invocation running every 1 minute.

---

## 5. Firebase Cloud Messaging (FCM) & Android Preflight

- **Android App ID**: `com.example.careflow` (`android/app/build.gradle.kts`).
- **Google Services Plugin**: Not applied in `android/app/build.gradle.kts`.
- **`google-services.json`**: Missing from `android/app/`.
- **Flutter Dependencies**: `pubspec.yaml` currently does not declare `firebase_core` or `firebase_messaging`.
- **Existing Dart Code**: `lib/services/push_notification_service.dart` used a mock token generator (`fcm_tok_...`).
- **Remediation**:
  1. Provide exact configuration requirements for production FCM:
     - Register `com.example.careflow` in the Firebase Console.
     - Download and place `google-services.json` into `android/app/`.
     - Configure Google service account private key in Supabase Secrets as `FIREBASE_SERVICE_ACCOUNT_KEY`.
  2. Replace mock token generation with clean graceful degradation: when Firebase is not initialized, register local device UUID or log explicit unconfigured state rather than faking FCM tokens.

---

## 6. Proposed Safe Execution Order

1. **Step 1 — Resolve Migration Inconsistency**:
   Move redundant `20261009000001_careflow_calendar_and_notifications.sql` to `supabase/migrations/.archive/`.
2. **Step 2 — Verify Dry-Run**:
   Run `npx.cmd supabase db push --dry-run` to confirm the CLI cleanly targets the 5 pending migrations in strict timestamp order without errors.
3. **Step 3 — Apply Pending Migrations**:
   Execute `npx.cmd supabase db push`.
4. **Step 4 — Verify Live Remote Schema**:
   Run automated probe suite to confirm all 5 pending migrations, tables, RPCs, and triggers exist and operate on `cwzymgamqijeoeqnnkvc`.
5. **Step 5 — Harden Edge Function**:
   Update `supabase/functions/medication-scheduler/index.ts` with bearer authentication, consent re-verification, and exponential backoff retry logic.
6. **Step 6 — Clean Push Notification Service**:
   Remove mock token synthesis from `lib/services/push_notification_service.dart` and provide transparent status reporting.
7. **Step 7 — Regression Tests & Build Verification**:
   Execute `flutter analyze`, test suites, and APK build.
