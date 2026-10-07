# CareFlow Full Lib Package

This package contains the expanded `lib/` layer for the CareFlow Flutter app, based on the three supplied reference sheets covering Patient, Doctor and Admin experiences.

## Coverage

- Patient experience: splash, login/register, dashboard, doctor search, doctor details/availability, appointments, check-in, live queue, medical records, record details, prescriptions, prescription details, medication reminder/history/missed-dose alert, emergency contact, health analytics, health metrics, medication adherence, health timeline, bills, bill details, follow-ups, notifications, profile.
- Doctor experience: splash, login, dashboard, today's appointments, appointment details, live queue, patient list/details/history, consultation flow (symptoms, vitals, diagnosis, prescription, follow-up, summary), medical history, prescription history, medication adherence, follow-up management, analytics, calendar, notifications, profile and quick actions.
- Admin experience: splash, login, dashboard, appointments, patient management/add patient, doctor management/add doctor, live clinic queue, check-in management, billing/create bill/payment details, records, prescriptions, follow-ups, notifications, analytics, revenue, reports, inventory, clinic settings, user management, calendar, profile, quick actions and more/menu.
- Shared: search, notifications, patient journey, PDFs and messages.

## Architecture

`main.dart` → `core` → `screens` → `providers` → `services` → `repositories` → Supabase.

The code also includes model classes for the business objects discussed for CareFlow: patients, doctors, appointments, queue entries, encounters, vitals, medical records, diagnoses, prescriptions, medications, medication alerts/doses, emergency contacts, billing, payments, follow-ups, notifications, health metrics, messages and device tokens.

## Important setup note

The package intentionally does **not** store the Supabase publishable key in source. `supabase_config.dart` reads it from a Dart define.

Run the app in UI/demo mode with:

`flutter run`

Run with your Supabase publishable key with:

`flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY`

The project URL is already set to the Care Flow Supabase project in `supabase_config.dart`.

## Before production

The UI and service layer are intentionally ready before the database layer is completed. Appointment/queue/notification repositories expect the corresponding Supabase tables. Healthcare access must be protected with correct Row Level Security policies; do not add permissive `using (true)` policies and never place a service-role/secret key inside Flutter.

Push/lock-screen notifications also require the Firebase FCM/native setup discussed separately; `push_notification_service.dart` is the integration seam for that work.

## Replacing your current lib

1. Back up your existing `lib/` folder.
2. Extract this ZIP.
3. Replace the project `lib/` with the ZIP's `lib/` directory.
4. Run `flutter pub get`.
5. Start with `flutter run` to confirm the UI navigation.
6. Then add the Supabase schema/RLS and wire each repository to live data.
