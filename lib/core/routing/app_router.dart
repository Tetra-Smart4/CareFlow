import 'package:flutter/material.dart';

// ============================================================
// SPLASH
// ============================================================

import 'package:careflow/screens/splash/patient_splash_screen.dart';
import 'package:careflow/screens/splash/doctor_splash_screen.dart';
import 'package:careflow/screens/splash/admin_splash_screen.dart';

// ============================================================
// AUTH
// ============================================================

import 'package:careflow/screens/auth/patient_login_screen.dart';
import 'package:careflow/screens/auth/doctor_login_screen.dart';
import 'package:careflow/screens/auth/admin_login_screen.dart';
import 'package:careflow/screens/auth/register_screen.dart';
import 'package:careflow/screens/auth/forgot_password_screen.dart';
import 'package:careflow/screens/auth/role_selection_screen.dart';

// ============================================================
// PATIENT
// ============================================================

import 'package:careflow/screens/patient/dashboard/patient_dashboard.dart';

import 'package:careflow/screens/patient/doctors/doctor_search_screen.dart';
import 'package:careflow/screens/patient/doctors/doctor_details_screen.dart';
import 'package:careflow/screens/patient/doctors/doctor_availability_screen.dart';

import 'package:careflow/screens/patient/appointments/book_appointment_screen.dart';
import 'package:careflow/screens/patient/appointments/appointments_screen.dart';
import 'package:careflow/screens/patient/appointments/appointment_details_screen.dart';
import 'package:careflow/screens/patient/appointments/appointment_success_screen.dart';

import 'package:careflow/screens/patient/queue/check_in_screen.dart';
import 'package:careflow/screens/patient/queue/live_queue_screen.dart';

import 'package:careflow/screens/patient/medical_records/medical_records_screen.dart';
import 'package:careflow/screens/patient/medical_records/record_details_screen.dart';

import 'package:careflow/screens/patient/prescriptions/prescriptions_screen.dart';
import 'package:careflow/screens/patient/prescriptions/prescription_details_screen.dart';

import 'package:careflow/screens/patient/medications/medication_reminder_screen.dart';
import 'package:careflow/screens/patient/medications/medication_history_screen.dart';
import 'package:careflow/screens/patient/medications/missed_dose_screen.dart';

import 'package:careflow/screens/patient/emergency/emergency_contact_screen.dart';

import 'package:careflow/screens/patient/health/health_analytics_screen.dart';
import 'package:careflow/screens/patient/health/health_metrics_screen.dart';
import 'package:careflow/screens/patient/health/medication_adherence_screen.dart';
import 'package:careflow/screens/patient/health/health_timeline_screen.dart';

import 'package:careflow/screens/patient/bills/bills_screen.dart';
import 'package:careflow/screens/patient/bills/bill_details_screen.dart';

import 'package:careflow/screens/patient/follow_ups/follow_ups_screen.dart';
import 'package:careflow/screens/patient/notifications/patient_notifications_screen.dart';
import 'package:careflow/screens/patient/profile/patient_profile_screen.dart';

// ============================================================
// DOCTOR
// ============================================================

import 'package:careflow/screens/doctor/dashboard/doctor_dashboard.dart';

import 'package:careflow/screens/doctor/appointments/doctor_appointments_screen.dart';
import 'package:careflow/screens/doctor/appointments/appointment_details_screen.dart';

import 'package:careflow/screens/doctor/queue/doctor_queue_screen.dart';

import 'package:careflow/screens/doctor/patients/patient_list_screen.dart';
import 'package:careflow/screens/doctor/patients/patient_details_screen.dart';
import 'package:careflow/screens/doctor/patients/patient_history_screen.dart';

import 'package:careflow/screens/doctor/consultation/consultation_screen.dart';
import 'package:careflow/screens/doctor/consultation/symptoms_screen.dart';
import 'package:careflow/screens/doctor/consultation/vitals_screen.dart';
import 'package:careflow/screens/doctor/consultation/diagnosis_screen.dart';
import 'package:careflow/screens/doctor/consultation/prescription_screen.dart';
import 'package:careflow/screens/doctor/consultation/follow_up_screen.dart';
import 'package:careflow/screens/doctor/consultation/consultation_summary_screen.dart';

import 'package:careflow/screens/doctor/medical_history/medical_history_screen.dart';

import 'package:careflow/screens/doctor/prescriptions/prescription_history_screen.dart';

import 'package:careflow/screens/doctor/medication_adherence/medication_adherence_screen.dart';

import 'package:careflow/screens/doctor/follow_ups/follow_ups_screen.dart';

import 'package:careflow/screens/doctor/analytics/doctor_analytics_screen.dart';

import 'package:careflow/screens/doctor/calendar/doctor_calendar_screen.dart';

import 'package:careflow/screens/doctor/notifications/doctor_notifications_screen.dart';

import 'package:careflow/screens/doctor/profile/doctor_profile_screen.dart';

import 'package:careflow/screens/doctor/quick_actions/quick_actions_screen.dart';

// ============================================================
// CLINIC / ADMIN
// ============================================================

import 'package:careflow/screens/admin/dashboard/admin_dashboard.dart';

import 'package:careflow/screens/admin/appointments/appointment_management_screen.dart';

import 'package:careflow/screens/admin/patients/patient_management_screen.dart';
import 'package:careflow/screens/admin/patients/add_patient_screen.dart';

import 'package:careflow/screens/admin/doctors/doctor_management_screen.dart';
import 'package:careflow/screens/admin/doctors/add_doctor_screen.dart';

import 'package:careflow/screens/admin/queue/clinic_queue_screen.dart';
import 'package:careflow/screens/admin/queue/check_in_management_screen.dart';

import 'package:careflow/screens/admin/billing/billing_screen.dart';
import 'package:careflow/screens/admin/billing/create_bill_screen.dart';
import 'package:careflow/screens/admin/billing/payment_details_screen.dart';

import 'package:careflow/screens/admin/records/patient_records_screen.dart';

import 'package:careflow/screens/admin/prescriptions/prescription_management_screen.dart';

import 'package:careflow/screens/admin/follow_ups/follow_up_management_screen.dart';

import 'package:careflow/screens/admin/notifications/admin_notifications_screen.dart';

import 'package:careflow/screens/admin/analytics/analytics_dashboard.dart';
import 'package:careflow/screens/admin/analytics/revenue_analytics.dart';
import 'package:careflow/screens/admin/analytics/appointment_analytics.dart';
import 'package:careflow/screens/admin/analytics/doctor_performance.dart';

import 'package:careflow/screens/admin/reports/reports_screen.dart';

import 'package:careflow/screens/admin/inventory/inventory_screen.dart';

import 'package:careflow/screens/admin/settings/clinic_settings_screen.dart';

import 'package:careflow/screens/admin/users/user_management_screen.dart';

import 'package:careflow/screens/admin/calendar/clinic_calendar_screen.dart';

import 'package:careflow/screens/admin/profile/admin_profile_screen.dart';

import 'package:careflow/screens/admin/quick_actions/admin_quick_actions_screen.dart';

import 'package:careflow/screens/admin/more/more_menu_screen.dart';

// ============================================================
// SHARED
// ============================================================

import 'package:careflow/screens/shared/search/search_screen.dart';
import 'package:careflow/screens/shared/notifications/notifications_screen.dart';
import 'package:careflow/screens/shared/patient_journey/patient_journey_screen.dart';
import 'package:careflow/screens/shared/pdf/pdf_screen.dart';
import 'package:careflow/screens/shared/messages/messages_screen.dart';

// ============================================================
// APP ROUTER
// ============================================================

class AppRouter {
  static const splash = '/splash';

  static final Map<String, WidgetBuilder> routes = {
    // ==========================================================
    // COMMON SPLASH
    // ==========================================================

    '/splash': (_) => const PatientSplashScreen(),

    '/splash/patient': (_) => const PatientSplashScreen(),

    '/splash/doctor': (_) => const DoctorSplashScreen(),

    '/splash/admin': (_) => const AdminSplashScreen(),

    // ==========================================================
    // ROLE-SPECIFIC LOGIN
    // ==========================================================

    '/auth/patient-login': (_) => const PatientLoginScreen(),

    '/auth/doctor-login': (_) => const DoctorLoginScreen(),

    '/auth/admin-login': (_) => const AdminLoginScreen(),

    '/auth/register': (_) => const RegisterScreen(),

    '/auth/forgot': (_) => const ForgotPasswordScreen(),

    '/auth/roles': (_) => const RoleSelectionScreen(),

    // ==========================================================
    // PATIENT DASHBOARD
    // ==========================================================

    '/patient/dashboard': (_) => const PatientDashboard(),

    // Doctors
    '/patient/doctors/search': (_) => const DoctorSearchScreen(),

    '/patient/doctors/detail': (_) => const DoctorDetailsScreen(),

    '/patient/doctors/availability': (_) =>
        const DoctorAvailabilityScreen(),

    // Appointments
    '/patient/appointments/book': (_) =>
        const BookAppointmentScreen(),

    '/patient/appointments': (_) =>
        const AppointmentsScreen(),

    '/patient/appointments/detail': (_) =>
        const AppointmentDetailsScreen(),

    '/patient/appointments/success': (_) =>
        const AppointmentSuccessScreen(),

    // Queue
    '/patient/queue/checkin': (_) =>
        const CheckInScreen(),

    '/patient/queue/live': (_) =>
        const LiveQueueScreen(),

    // Medical Records
    '/patient/records': (_) =>
        const MedicalRecordsScreen(),

    '/patient/records/detail': (_) =>
        const RecordDetailsScreen(),

    // Prescriptions
    '/patient/prescriptions': (_) =>
        const PrescriptionsScreen(),

    '/patient/prescriptions/detail': (_) =>
        const PrescriptionDetailsScreen(),

    // Medications
    '/patient/medications/reminder': (_) =>
        const MedicationReminderScreen(),

    '/patient/medications/history': (_) =>
        const MedicationHistoryScreen(),

    '/patient/medications/missed': (_) =>
        const MissedDoseScreen(),

    // Emergency
    '/patient/emergency': (_) =>
        const EmergencyContactScreen(),

    // Health
    '/patient/health/analytics': (_) =>
        const HealthAnalyticsScreen(),

    '/patient/health/metrics': (_) =>
        const HealthMetricsScreen(),

    '/patient/health/adherence': (_) =>
        const MedicationAdherenceScreen(),

    '/patient/health/timeline': (_) =>
        const HealthTimelineScreen(),

    // Bills
    '/patient/bills': (_) =>
        const BillsScreen(),

    '/patient/bills/detail': (_) =>
        const BillDetailsScreen(),

    // Follow-ups
    '/patient/followups': (_) =>
        const FollowUpsScreen(),

    // Notifications
    '/patient/notifications': (_) =>
        const PatientNotificationsScreen(),

    // Profile
    '/patient/profile': (_) =>
        const PatientProfileScreen(),

    // ==========================================================
    // DOCTOR DASHBOARD
    // ==========================================================

    '/doctor/dashboard': (_) =>
        const DoctorDashboard(),

    // Appointments
    '/doctor/appointments': (_) =>
        const DoctorAppointmentsScreen(),

    '/doctor/appointments/detail': (_) =>
        const DoctorAppointmentDetailsScreen(),

    // Queue
    '/doctor/queue': (_) =>
        const DoctorQueueScreen(),

    // Patients
    '/doctor/patients': (_) =>
        const PatientListScreen(),

    '/doctor/patients/detail': (_) =>
        const PatientDetailsScreen(),

    '/doctor/patients/history': (_) =>
        const PatientHistoryScreen(),

    // Consultation
    '/doctor/consultation': (_) =>
        const ConsultationScreen(),

    '/doctor/consultation/symptoms': (_) =>
        const SymptomsScreen(),

    '/doctor/consultation/vitals': (_) =>
        const VitalsScreen(),

    '/doctor/consultation/diagnosis': (_) =>
        const DiagnosisScreen(),

    '/doctor/consultation/prescription': (_) =>
        const DoctorPrescriptionScreen(),

    '/doctor/consultation/followup': (_) =>
        const DoctorFollowUpScreen(),

    '/doctor/consultation/summary': (_) =>
        const ConsultationSummaryScreen(),

    // Medical History
    '/doctor/medical-history': (_) =>
        const DoctorMedicalHistoryScreen(),

    // Prescriptions
    '/doctor/prescriptions': (_) =>
        const PrescriptionHistoryScreen(),

    // Medication Adherence
    '/doctor/medication-adherence': (_) =>
        const DoctorMedicationAdherenceScreen(),

    // Follow-ups
    '/doctor/followups': (_) =>
        const DoctorFollowUpsScreen(),

    // Analytics
    '/doctor/analytics': (_) =>
        const DoctorAnalyticsScreen(),

    // Calendar
    '/doctor/calendar': (_) =>
        const DoctorCalendarScreen(),

    // Notifications
    '/doctor/notifications': (_) =>
        const DoctorNotificationsScreen(),

    // Profile
    '/doctor/profile': (_) =>
        const DoctorProfileScreen(),

    // Quick Actions
    '/doctor/quick-actions': (_) =>
        const DoctorQuickActionsScreen(),

    // ==========================================================
    // CLINIC / ADMIN DASHBOARD
    // ==========================================================

    '/admin/dashboard': (_) =>
        const AdminDashboard(),

    // Appointments
    '/admin/appointments': (_) =>
        const AppointmentManagementScreen(),

    // Patients
    '/admin/patients': (_) =>
        const PatientManagementScreen(),

    '/admin/patients/add': (_) =>
        const AddPatientScreen(),

    // Doctors
    '/admin/doctors': (_) =>
        const DoctorManagementScreen(),

    '/admin/doctors/add': (_) =>
        const AddDoctorScreen(),

    // Queue
    '/admin/queue': (_) =>
        const ClinicQueueScreen(),

    '/admin/checkin': (_) =>
        const CheckInManagementScreen(),

    // Billing
    '/admin/billing': (_) =>
        const BillingScreen(),

    '/admin/billing/create': (_) =>
        const CreateBillScreen(),

    '/admin/billing/payment': (_) =>
        const PaymentDetailsScreen(),

    // Records
    '/admin/records': (_) =>
        const PatientRecordsScreen(),

    // Prescriptions
    '/admin/prescriptions': (_) =>
        const PrescriptionManagementScreen(),

    // Follow-ups
    '/admin/followups': (_) =>
        const FollowUpManagementScreen(),

    // Notifications
    '/admin/notifications': (_) =>
        const AdminNotificationsScreen(),

    // Analytics
    '/admin/analytics': (_) =>
        const AnalyticsDashboard(),

    '/admin/revenue': (_) =>
        const RevenueAnalytics(),

    '/admin/analytics/appointments': (_) =>
        const AppointmentAnalytics(),

    '/admin/analytics/doctors': (_) =>
        const DoctorPerformance(),

    // Reports
    '/admin/reports': (_) =>
        const ReportsScreen(),

    // Inventory
    '/admin/inventory': (_) =>
        const InventoryScreen(),

    // Settings
    '/admin/settings': (_) =>
        const ClinicSettingsScreen(),

    // Users
    '/admin/users': (_) =>
        const UserManagementScreen(),

    // Calendar
    '/admin/calendar': (_) =>
        const ClinicCalendarScreen(),

    // Profile
    '/admin/profile': (_) =>
        const AdminProfileScreen(),

    // Quick Actions
    '/admin/quick-actions': (_) =>
        const AdminQuickActionsScreen(),

    // More
    '/admin/more': (_) =>
        const MoreMenuScreen(),

    // ==========================================================
    // SHARED
    // ==========================================================

    '/shared/search': (_) =>
        const SearchScreen(),

    '/shared/notifications': (_) =>
        const NotificationsScreen(),

    '/shared/journey': (_) =>
        const PatientJourneyScreen(),

    '/shared/pdf': (_) =>
        const PdfScreen(),

    '/shared/messages': (_) =>
        const MessagesScreen(),
  };
}