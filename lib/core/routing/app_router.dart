import 'package:flutter/material.dart';

// ============================================================
// SPLASH
// ============================================================

import 'package:careflow/screens/splash/patient_splash_screen.dart';
import 'package:careflow/screens/splash/doctor_splash_screen.dart';
import 'package:careflow/screens/splash/admin_splash_screen.dart';
import 'package:careflow/screens/splash/staff_splash_screen.dart';
import 'package:careflow/screens/splash/family_splash_screen.dart';
// ============================================================
// AUTH
// ============================================================

import 'package:careflow/screens/auth/login_screen.dart';
import 'package:careflow/screens/auth/patient_login_screen.dart';
import 'package:careflow/screens/auth/doctor_login_screen.dart';
import 'package:careflow/screens/auth/admin_login_screen.dart';
import 'package:careflow/screens/auth/staff_login_screen.dart';
import 'package:careflow/screens/auth/family_login_screen.dart';
import 'package:careflow/screens/auth/register_screen.dart';
import 'package:careflow/screens/auth/patient_registration_screen.dart';
import 'package:careflow/screens/auth/clinic_registration_screen.dart';
import 'package:careflow/screens/auth/forgot_password_screen.dart';
import 'package:careflow/screens/auth/reset_password_screen.dart';
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

import 'package:careflow/screens/patient/queue/live_queue_screen.dart';
import 'package:careflow/core/routing/auth_guard.dart';

import 'package:careflow/screens/patient/medical_records/medical_records_screen.dart';
import 'package:careflow/screens/patient/medical_records/record_details_screen.dart';
import 'package:careflow/screens/patient/medical_history/medical_questionnaire_screen.dart';

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
import 'package:careflow/screens/patient/health/patient_reports_screen.dart';

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
import 'package:careflow/screens/doctor/appointments/doctor_availability_screen.dart';
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

import 'package:careflow/screens/clinic/dashboard/admin_dashboard.dart';

import 'package:careflow/screens/clinic/appointments/appointment_management_screen.dart';

import 'package:careflow/screens/clinic/patients/patient_management_screen.dart';
import 'package:careflow/screens/clinic/patients/add_patient_screen.dart';

import 'package:careflow/screens/clinic/doctors/doctor_management_screen.dart';
import 'package:careflow/screens/clinic/doctors/add_doctor_screen.dart';

import 'package:careflow/screens/clinic/queue/clinic_queue_screen.dart';
import 'package:careflow/screens/clinic/queue/check_in_management_screen.dart';

import 'package:careflow/screens/clinic/billing/billing_screen.dart';
import 'package:careflow/screens/clinic/billing/create_bill_screen.dart';
import 'package:careflow/screens/clinic/billing/payment_details_screen.dart';

import 'package:careflow/screens/clinic/records/patient_records_screen.dart';

import 'package:careflow/screens/clinic/prescriptions/prescription_management_screen.dart';

import 'package:careflow/screens/clinic/follow_ups/follow_up_management_screen.dart';

import 'package:careflow/screens/clinic/notifications/admin_notifications_screen.dart';

import 'package:careflow/screens/clinic/analytics/analytics_dashboard.dart';
import 'package:careflow/screens/clinic/analytics/revenue_analytics.dart';
import 'package:careflow/screens/clinic/analytics/appointment_analytics.dart';
import 'package:careflow/screens/clinic/analytics/doctor_performance.dart';

import 'package:careflow/screens/clinic/reports/reports_screen.dart';
import 'package:careflow/screens/clinic/reports/upload_report_screen.dart';

import 'package:careflow/screens/clinic/inventory/inventory_screen.dart';

import 'package:careflow/screens/clinic/settings/clinic_settings_screen.dart';

import 'package:careflow/screens/clinic/users/user_management_screen.dart';

import 'package:careflow/screens/clinic/calendar/clinic_calendar_screen.dart';

import 'package:careflow/screens/clinic/profile/admin_profile_screen.dart';

import 'package:careflow/screens/clinic/more/more_menu_screen.dart';
import 'package:careflow/screens/clinic/quick_actions/admin_quick_actions_screen.dart';
import 'package:careflow/screens/admin/platform/platform_admin_dashboard.dart';
import 'package:careflow/screens/clinic/clinic_pending_screen.dart';
import 'package:careflow/screens/clinic/clinic_rejected_screen.dart';

// ============================================================
// SHARED
// ============================================================

import 'package:careflow/screens/shared/search/search_screen.dart';
import 'package:careflow/screens/shared/notifications/notifications_screen.dart';
import 'package:careflow/screens/shared/patient_journey/patient_journey_screen.dart';
import 'package:careflow/screens/shared/pdf/pdf_screen.dart';
import 'package:careflow/screens/shared/messages/messages_screen.dart';

// ============================================================
// STAFF
// ============================================================

import 'package:careflow/screens/staff/dashboard/staff_dashboard.dart';

// ============================================================
// FAMILY
// ============================================================

import 'package:careflow/screens/family/dashboard/family_dashboard.dart';

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

    '/splash/staff': (_) => const StaffSplashScreen(),

    '/splash/family': (_) => const FamilySplashScreen(),

    // ==========================================================
    // ROLE-SPECIFIC LOGIN
    // ==========================================================

    '/auth/login': (_) => const LoginScreen(),

    '/auth/patient-login': (_) => const PatientLoginScreen(),

    '/auth/doctor-login': (_) => const DoctorLoginScreen(),

    '/auth/admin-login': (_) => const AdminLoginScreen(),

    '/auth/staff-login': (_) => const StaffLoginScreen(),

    '/auth/family-login': (_) => const FamilyLoginScreen(),

    '/auth/register': (_) => const RegisterScreen(),

    '/auth/register-patient': (_) => const PatientRegistrationScreen(),

    '/auth/register-clinic': (_) => const ClinicRegistrationScreen(),

    '/auth/forgot': (_) => const ForgotPasswordScreen(),
    
    '/auth/reset-password': (_) => const ResetPasswordScreen(),

    '/auth/roles': (_) => const RoleSelectionScreen(),

    // ==========================================================
    // PATIENT DASHBOARD
    // ==========================================================

    '/patient/dashboard': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: PatientDashboard()),

    // Doctors
    '/patient/doctors/search': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: DoctorSearchScreen()),

    '/patient/doctors/detail': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: DoctorDetailsScreen()),

    '/patient/doctors/availability': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: DoctorAvailabilityScreen()),

    // Appointments
    '/patient/appointments/book': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: BookAppointmentScreen()),

    '/patient/appointments': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: AppointmentsScreen()),

    '/patient/appointments/detail': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: AppointmentDetailsScreen()),

    '/patient/appointments/success': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: AppointmentSuccessScreen()),

    // Queue
    '/patient/queue/live': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: LiveQueueScreen()),

    // Medical Records
    '/patient/records': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: MedicalRecordsScreen()),

    '/patient/records/detail': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: RecordDetailsScreen()),
    '/patient/medical-history/questionnaire': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: MedicalQuestionnaireScreen()),

    // Reports
    '/patient/reports': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: PatientReportsScreen()),
    '/patient/health/reports': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: PatientReportsScreen()),

    // Prescriptions
    '/patient/prescriptions': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: PrescriptionsScreen()),

    '/patient/prescriptions/detail': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: PrescriptionDetailsScreen()),

    // Medications
    '/patient/medications/reminder': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: MedicationReminderScreen()),

    '/patient/medications/history': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: MedicationHistoryScreen()),

    '/patient/medications/missed': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: MissedDoseScreen()),

    // Emergency
    '/patient/emergency': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: EmergencyContactScreen()),

    // Health
    '/patient/health/analytics': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: HealthAnalyticsScreen()),

    '/patient/health/metrics': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: HealthMetricsScreen()),

    '/patient/health/adherence': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: MedicationAdherenceScreen()),

    '/patient/health/timeline': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: HealthTimelineScreen()),

    // Bills
    '/patient/bills': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: BillsScreen()),

    '/patient/bills/detail': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: BillDetailsScreen()),

    // Follow-ups
    '/patient/followups': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: FollowUpsScreen()),

    // Notifications
    '/patient/notifications': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: PatientNotificationsScreen()),

    // Profile
    '/patient/profile': (_) => const AuthGuardWidget(allowedRoles: ['patient'], child: PatientProfileScreen()),

    // ==========================================================
    // DOCTOR DASHBOARD
    // ==========================================================

    '/doctor/dashboard': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DoctorDashboard()),

    // Appointments
    '/doctor/appointments': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DoctorAppointmentsScreen()),

    '/doctor/appointments/detail': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DoctorAppointmentDetailsScreen()),

    '/doctor/availability': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: ManageDoctorAvailabilityScreen()),

    // Queue
    '/doctor/queue': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DoctorQueueScreen()),

    // Patients
    '/doctor/patients': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: PatientListScreen()),

    '/doctor/patients/detail': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: PatientDetailsScreen()),

    '/doctor/patients/history': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: PatientHistoryScreen()),

    // Consultation
    '/doctor/consultation': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: ConsultationScreen()),

    '/doctor/consultation/symptoms': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: SymptomsScreen()),

    '/doctor/consultation/vitals': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: VitalsScreen()),

    '/doctor/consultation/diagnosis': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DiagnosisScreen()),

    '/doctor/consultation/prescription': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DoctorPrescriptionScreen()),

    '/doctor/consultation/followup': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DoctorFollowUpScreen()),

    '/doctor/consultation/summary': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: ConsultationSummaryScreen()),

    // Medical History
    '/doctor/medical-history': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DoctorMedicalHistoryScreen()),

    // Prescriptions
    '/doctor/prescriptions': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: PrescriptionHistoryScreen()),

    // Medication Adherence
    '/doctor/medication-adherence': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DoctorMedicationAdherenceScreen()),

    // Follow-ups
    '/doctor/followups': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DoctorFollowUpsScreen()),

    // Analytics
    '/doctor/analytics': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DoctorAnalyticsScreen()),

    // Calendar
    '/doctor/calendar': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DoctorCalendarScreen()),

    // Notifications
    '/doctor/notifications': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DoctorNotificationsScreen()),

    // Profile
    '/doctor/profile': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DoctorProfileScreen()),

    // Quick Actions
    '/doctor/quick-actions': (_) => const AuthGuardWidget(allowedRoles: ['doctor'], child: DoctorQuickActionsScreen()),

    // ==========================================================
    // CLINIC / ADMIN DASHBOARD
    // ==========================================================

    '/clinic/dashboard': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: AdminDashboard()),

    // Platform Admin Dashboard
    '/admin/platform-dashboard': (_) => const AuthGuardWidget(allowedRoles: ['platform_admin'], child: PlatformAdminDashboard()),

    // Clinic Approval Status
    '/clinic/pending': (_) => const AuthGuardWidget(allowedRoles: ['clinic_pending'], child: ClinicPendingScreen()),
    '/clinic/rejected': (_) => const AuthGuardWidget(allowedRoles: ['clinic_rejected'], child: ClinicRejectedScreen()),

    // Appointments
    '/clinic/appointments': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: AppointmentManagementScreen()),

    // Patients
    '/clinic/patients': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: PatientManagementScreen()),

    '/clinic/patients/add': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: AddPatientScreen()),

    // Doctors
    '/clinic/doctors': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: DoctorManagementScreen()),

    '/clinic/doctors/add': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: AddDoctorScreen()),

    // Queue
    '/clinic/queue': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: ClinicQueueScreen()),

    '/clinic/checkin': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: CheckInManagementScreen()),

    // Billing
    '/clinic/billing': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: BillingScreen()),

    '/clinic/billing/create': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: CreateBillScreen()),

    '/clinic/billing/payment': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: PaymentDetailsScreen()),

    // Records
    '/clinic/records': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: PatientRecordsScreen()),

    // Prescriptions
    '/clinic/prescriptions': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: PrescriptionManagementScreen()),

    // Follow-ups
    '/clinic/followups': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: FollowUpManagementScreen()),

    // Notifications
    '/clinic/notifications': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: AdminNotificationsScreen()),

    // Analytics
    '/clinic/analytics': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: AnalyticsDashboard()),

    '/clinic/revenue': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: RevenueAnalytics()),

    '/clinic/analytics/appointments': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: AppointmentAnalytics()),

    '/clinic/analytics/doctors': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: DoctorPerformance()),

    // Reports
    '/clinic/reports': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: ReportsScreen()),
    '/clinic/reports/upload': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: UploadReportScreen()),

    // Inventory
    '/clinic/inventory': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: InventoryScreen()),

    // Settings
    '/clinic/settings': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: ClinicSettingsScreen()),

    // Users
    '/clinic/users': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: UserManagementScreen()),

    // Calendar
    '/clinic/calendar': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: ClinicCalendarScreen()),

    // Profile
    '/clinic/profile': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: AdminProfileScreen()),

    // Quick Actions
    '/clinic/quick-actions': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: AdminQuickActionsScreen()),

    // More
    '/clinic/more': (_) => const AuthGuardWidget(allowedRoles: ['clinic'], child: MoreMenuScreen()),

    // ==========================================================
    // SHARED
    // ==========================================================

    '/shared/search': (_) => const AuthGuardWidget(allowedRoles: ['patient', 'doctor', 'clinic', 'admin', 'staff', 'family', 'platform_admin'], child: SearchScreen()),

    '/shared/notifications': (_) => const AuthGuardWidget(allowedRoles: ['patient', 'doctor', 'clinic', 'admin', 'staff', 'family', 'platform_admin'], child: NotificationsScreen()),

    '/shared/journey': (_) => const AuthGuardWidget(allowedRoles: ['patient', 'doctor', 'clinic', 'admin', 'staff', 'family', 'platform_admin'], child: PatientJourneyScreen()),

    '/shared/pdf': (_) => const AuthGuardWidget(allowedRoles: ['patient', 'doctor', 'clinic', 'admin', 'staff', 'family', 'platform_admin'], child: PdfScreen()),

    '/shared/messages': (_) => const AuthGuardWidget(allowedRoles: ['patient', 'doctor', 'clinic', 'admin', 'staff', 'family', 'platform_admin'], child: MessagesScreen()),

    // ==========================================================
    // STAFF DASHBOARD
    // ==========================================================

    '/staff/dashboard': (_) => const AuthGuardWidget(allowedRoles: ['staff'], child: StaffDashboard()),

    // ==========================================================
    // FAMILY DASHBOARD
    // ==========================================================

    '/family/dashboard': (_) => const AuthGuardWidget(allowedRoles: ['family'], child: FamilyDashboard()),
  };
}