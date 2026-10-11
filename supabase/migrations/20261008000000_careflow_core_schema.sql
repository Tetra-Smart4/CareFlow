-- ============================================================
-- CAREFLOW DATABASE MIGRATION & RLS POLICIES
-- Target: Supabase / PostgreSQL Single Source of Truth
-- ============================================================

-- 1. Ensure extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Enhance clinics table with operational status & review metadata
ALTER TABLE IF EXISTS public.clinics
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS name text,
  ADD COLUMN IF NOT EXISTS email text,
  ADD COLUMN IF NOT EXISTS phone text,
  ADD COLUMN IF NOT EXISTS address text,
  ADD COLUMN IF NOT EXISTS city text,
  ADD COLUMN IF NOT EXISTS state text,
  ADD COLUMN IF NOT EXISTS pincode text,
  ADD COLUMN IF NOT EXISTS clinic_type text,
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS rejection_reason text,
  ADD COLUMN IF NOT EXISTS approved_at timestamptz;

-- Set existing clinics to approved so existing data is immediately operational
UPDATE public.clinics SET status = 'approved' WHERE status IS NULL OR status = 'pending';

-- 3. Enhance profiles table with user status and registration fields
ALTER TABLE IF EXISTS public.profiles
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS date_of_birth date,
  ADD COLUMN IF NOT EXISTS city text,
  ADD COLUMN IF NOT EXISTS state text,
  ADD COLUMN IF NOT EXISTS pincode text;

-- 3b. Emergency Contacts table (linked to patient profile)
CREATE TABLE IF NOT EXISTS public.emergency_contacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  name text NOT NULL,
  phone text NOT NULL,
  relationship text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- 4. Enhance careflow_appointments table with queue token tracking
ALTER TABLE IF EXISTS public.careflow_appointments
  ADD COLUMN IF NOT EXISTS token_number integer DEFAULT 0;

-- 5. Enhance careflow_queue_counters with now_serving and updated_at
ALTER TABLE IF EXISTS public.careflow_queue_counters
  ADD COLUMN IF NOT EXISTS now_serving integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- 6. Enhance careflow_notifications table with read flag and message alias
ALTER TABLE IF EXISTS public.careflow_notifications
  ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS message text;

-- 7. Configure Supabase Realtime Publication
-- Note: wrapped in exception block in case a table was already added
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.careflow_appointments;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.careflow_queue_counters;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.careflow_notifications;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.careflow_prescriptions;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.careflow_followups;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.clinics;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;

-- 8. Enable Row Level Security (RLS) on key tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinic_doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.careflow_appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.careflow_queue_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.careflow_consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.careflow_prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.careflow_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.careflow_followups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;

-- 9. RLS Policies

-- PROFILES
DROP POLICY IF EXISTS "Profiles are readable by authenticated users" ON public.profiles;
CREATE POLICY "Profiles are readable by authenticated users"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- CLINICS
DROP POLICY IF EXISTS "Clinics readable by authenticated users" ON public.clinics;
CREATE POLICY "Clinics readable by authenticated users"
  ON public.clinics FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Clinic can insert own clinic record" ON public.clinics;
CREATE POLICY "Clinic can insert own clinic record"
  ON public.clinics FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Clinic can update own record or admin update" ON public.clinics;
CREATE POLICY "Clinic can update own record or admin update"
  ON public.clinics FOR UPDATE
  TO authenticated
  USING (
    auth.uid() = id OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'platform_admin'))
  );

-- DOCTORS
DROP POLICY IF EXISTS "Doctors readable by authenticated users" ON public.doctors;
CREATE POLICY "Doctors readable by authenticated users"
  ON public.doctors FOR SELECT
  TO authenticated
  USING (true);

-- CLINIC_DOCTORS
DROP POLICY IF EXISTS "Clinic doctors readable by authenticated users" ON public.clinic_doctors;
CREATE POLICY "Clinic doctors readable by authenticated users"
  ON public.clinic_doctors FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Clinic can manage its doctors" ON public.clinic_doctors;
CREATE POLICY "Clinic can manage its doctors"
  ON public.clinic_doctors FOR ALL
  TO authenticated
  USING (clinic_id = auth.uid());

-- PATIENTS
DROP POLICY IF EXISTS "Patients readable by authenticated users" ON public.patients;
CREATE POLICY "Patients readable by authenticated users"
  ON public.patients FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Patient can insert own record" ON public.patients;
CREATE POLICY "Patient can insert own record"
  ON public.patients FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- EMERGENCY CONTACTS (A patient can only access their own emergency contacts)
DROP POLICY IF EXISTS "Patients can view their own emergency contacts" ON public.emergency_contacts;
CREATE POLICY "Patients can view their own emergency contacts"
  ON public.emergency_contacts FOR SELECT
  TO authenticated
  USING (patient_id = auth.uid());

DROP POLICY IF EXISTS "Patients can insert their own emergency contacts" ON public.emergency_contacts;
CREATE POLICY "Patients can insert their own emergency contacts"
  ON public.emergency_contacts FOR INSERT
  TO authenticated
  WITH CHECK (patient_id = auth.uid());

DROP POLICY IF EXISTS "Patients can update their own emergency contacts" ON public.emergency_contacts;
CREATE POLICY "Patients can update their own emergency contacts"
  ON public.emergency_contacts FOR UPDATE
  TO authenticated
  USING (patient_id = auth.uid())
  WITH CHECK (patient_id = auth.uid());

DROP POLICY IF EXISTS "Patients can delete their own emergency contacts" ON public.emergency_contacts;
CREATE POLICY "Patients can delete their own emergency contacts"
  ON public.emergency_contacts FOR DELETE
  TO authenticated
  USING (patient_id = auth.uid());

-- CAREFLOW APPOINTMENTS
DROP POLICY IF EXISTS "Users can view authorized appointments" ON public.careflow_appointments;
CREATE POLICY "Users can view authorized appointments"
  ON public.careflow_appointments FOR SELECT
  TO authenticated
  USING (
    patient_id = auth.uid() OR
    doctor_id = auth.uid() OR
    clinic_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'platform_admin'))
  );

DROP POLICY IF EXISTS "Patients can create appointments" ON public.careflow_appointments;
CREATE POLICY "Patients can create appointments"
  ON public.careflow_appointments FOR INSERT
  TO authenticated
  WITH CHECK (patient_id = auth.uid() OR clinic_id = auth.uid());

DROP POLICY IF EXISTS "Authorized users can update appointments" ON public.careflow_appointments;
CREATE POLICY "Authorized users can update appointments"
  ON public.careflow_appointments FOR UPDATE
  TO authenticated
  USING (
    patient_id = auth.uid() OR
    doctor_id = auth.uid() OR
    clinic_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'platform_admin'))
  );

-- QUEUE COUNTERS
DROP POLICY IF EXISTS "Queue counters readable by all authenticated" ON public.careflow_queue_counters;
CREATE POLICY "Queue counters readable by all authenticated"
  ON public.careflow_queue_counters FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Clinic or doctor can update queue counter" ON public.careflow_queue_counters;
CREATE POLICY "Clinic or doctor can update queue counter"
  ON public.careflow_queue_counters FOR ALL
  TO authenticated
  USING (
    clinic_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.clinic_doctors WHERE doctor_id = auth.uid() AND clinic_id = public.careflow_queue_counters.clinic_id)
  );

-- CONSULTATIONS
DROP POLICY IF EXISTS "Consultations readable by doctor, patient, clinic" ON public.careflow_consultations;
CREATE POLICY "Consultations readable by doctor, patient, clinic"
  ON public.careflow_consultations FOR SELECT
  TO authenticated
  USING (
    patient_id = auth.uid() OR
    doctor_id = auth.uid()
  );

DROP POLICY IF EXISTS "Doctor can insert consultation" ON public.careflow_consultations;
CREATE POLICY "Doctor can insert consultation"
  ON public.careflow_consultations FOR INSERT
  TO authenticated
  WITH CHECK (doctor_id = auth.uid());

-- PRESCRIPTIONS
DROP POLICY IF EXISTS "Prescriptions readable by doctor, patient" ON public.careflow_prescriptions;
CREATE POLICY "Prescriptions readable by doctor, patient"
  ON public.careflow_prescriptions FOR SELECT
  TO authenticated
  USING (
    patient_id = auth.uid() OR
    doctor_id = auth.uid()
  );

DROP POLICY IF EXISTS "Doctor can insert prescription" ON public.careflow_prescriptions;
CREATE POLICY "Doctor can insert prescription"
  ON public.careflow_prescriptions FOR INSERT
  TO authenticated
  WITH CHECK (doctor_id = auth.uid());

-- NOTIFICATIONS
DROP POLICY IF EXISTS "Users can view and update their own notifications" ON public.careflow_notifications;
CREATE POLICY "Users can view and update their own notifications"
  ON public.careflow_notifications FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- 10. RPC Helper Functions

-- Check-in appointment and allocate token
CREATE OR REPLACE FUNCTION public.careflow_patient_check_in(p_appointment_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_next_token INT;
  v_clinic_id UUID;
BEGIN
  SELECT * INTO v_appointment FROM public.careflow_appointments WHERE id = p_appointment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Appointment not found.';
  END IF;

  v_clinic_id := v_appointment.clinic_id;

  -- Ensure queue counter row exists for clinic
  INSERT INTO public.careflow_queue_counters(clinic_id, current_token, now_serving)
  VALUES (v_clinic_id, 0, 0)
  ON CONFLICT (clinic_id) DO NOTHING;

  -- Calculate next token
  UPDATE public.careflow_queue_counters
  SET current_token = COALESCE(current_token, 0) + 1,
      updated_at = now()
  WHERE clinic_id = v_clinic_id
  RETURNING current_token INTO v_next_token;

  -- Update appointment status and token
  UPDATE public.careflow_appointments
  SET status = 'checked_in',
      checked_in_at = now(),
      token_number = v_next_token
  WHERE id = p_appointment_id;

  -- Notify patient
  INSERT INTO public.careflow_notifications(user_id, title, body, type, is_read, created_at)
  VALUES (
    v_appointment.patient_id,
    'Checked In Successfully',
    'Your queue token number is #' || v_next_token || '.',
    'queue',
    false,
    now()
  );

  RETURN jsonb_build_object(
    'success', true,
    'appointment_id', p_appointment_id,
    'token_number', v_next_token,
    'status', 'checked_in'
  );
END;
$$;

-- Call next patient in queue
CREATE OR REPLACE FUNCTION public.careflow_call_next_patient(p_clinic_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_now_serving INT;
  v_next_appointment RECORD;
BEGIN
  -- Advance now_serving in queue counter
  UPDATE public.careflow_queue_counters
  SET now_serving = COALESCE(now_serving, 0) + 1,
      updated_at = now()
  WHERE clinic_id = p_clinic_id
  RETURNING now_serving INTO v_now_serving;

  -- Find the appointment matching this token number
  SELECT * INTO v_next_appointment
  FROM public.careflow_appointments
  WHERE clinic_id = p_clinic_id
    AND token_number = v_now_serving
    AND status = 'checked_in'
  LIMIT 1;

  IF FOUND THEN
    UPDATE public.careflow_appointments
    SET status = 'in_consultation'
    WHERE id = v_next_appointment.id;

    -- Send notification to the patient
    INSERT INTO public.careflow_notifications(user_id, title, body, type, is_read, created_at)
    VALUES (
      v_next_appointment.patient_id,
      'Your Turn: Now Serving #' || v_now_serving,
      'Please proceed to the doctor consultation room.',
      'queue',
      false,
      now()
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'clinic_id', p_clinic_id,
    'now_serving', v_now_serving,
    'appointment_id', v_next_appointment.id
  );
END;
$$;

-- Platform Admin: Approve clinic
CREATE OR REPLACE FUNCTION public.careflow_admin_approve_clinic(p_clinic_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.clinics
  SET status = 'approved',
      approved_at = now(),
      rejection_reason = null
  WHERE id = p_clinic_id;

  RETURN jsonb_build_object('success', true, 'status', 'approved');
END;
$$;

-- Platform Admin: Reject clinic
CREATE OR REPLACE FUNCTION public.careflow_admin_reject_clinic(p_clinic_id UUID, p_reason text)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.clinics
  SET status = 'rejected',
      rejection_reason = p_reason
  WHERE id = p_clinic_id;

  RETURN jsonb_build_object('success', true, 'status', 'rejected', 'reason', p_reason);
END;
$$;

