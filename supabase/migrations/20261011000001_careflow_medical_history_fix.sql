-- ============================================================
-- CAREFLOW MIGRATION FIX: MEDICAL HISTORY ACCESS HARDENING
-- ============================================================

-- 1. Harden helper function with search_path
CREATE OR REPLACE FUNCTION public.careflow_has_active_access(p_patient_id uuid, p_doctor_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.careflow_doctor_access_grants
    WHERE patient_id = p_patient_id
      AND doctor_id = p_doctor_id
      AND is_revoked = false
      AND (expires_at IS NULL OR expires_at > now())
  );
$$;

-- 2. Harden grant RPC with caller validation and dynamic expiry
CREATE OR REPLACE FUNCTION public.careflow_grant_doctor_access(
  p_appointment_id uuid,
  p_patient_id uuid,
  p_doctor_id uuid,
  p_clinic_id uuid,
  p_hours_valid int DEFAULT 24
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_grant_id uuid;
  v_appt_date date;
  v_calculated_expiry timestamptz;
BEGIN
  -- VALIDATE CALLER: Only the patient can grant access to their records
  IF auth.uid() != p_patient_id THEN
    RAISE EXCEPTION 'Unauthorized: Only the patient can grant medical history access.';
  END IF;

  -- Get appointment date to calculate safe expiry
  SELECT appointment_date INTO v_appt_date 
  FROM public.careflow_appointments 
  WHERE id = p_appointment_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Appointment not found.';
  END IF;

  -- Expiry is 24 hours after the appointment date, ensuring it remains valid if booked days in advance
  v_calculated_expiry := (v_appt_date + (p_hours_valid || ' hours')::interval);
  
  -- If appointment is in the past or today, ensure at least 24 hours from NOW
  IF v_calculated_expiry < now() + (p_hours_valid || ' hours')::interval THEN
    v_calculated_expiry := now() + (p_hours_valid || ' hours')::interval;
  END IF;

  -- Insert the grant with explicit consent reference
  INSERT INTO public.careflow_doctor_access_grants (
    appointment_id, patient_id, doctor_id, clinic_id, expires_at, consent_reference
  ) VALUES (
    p_appointment_id, p_patient_id, p_doctor_id, p_clinic_id, v_calculated_expiry, 'Explicit user grant via booking'
  )
  RETURNING id INTO v_grant_id;

  RETURN jsonb_build_object('success', true, 'grant_id', v_grant_id);
END;
$$;

-- 3. Harden revoke RPC with caller validation
CREATE OR REPLACE FUNCTION public.careflow_revoke_doctor_access(
  p_appointment_id uuid
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_patient_id uuid;
BEGIN
  -- Identify the patient for this appointment
  SELECT patient_id INTO v_patient_id 
  FROM public.careflow_appointments 
  WHERE id = p_appointment_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Appointment not found.';
  END IF;

  -- VALIDATE CALLER: Only patient can manually revoke
  IF auth.uid() != v_patient_id THEN
    RAISE EXCEPTION 'Unauthorized: Only the patient can revoke access.';
  END IF;

  UPDATE public.careflow_doctor_access_grants
  SET is_revoked = true, updated_at = now()
  WHERE appointment_id = p_appointment_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 4. Correct the auto-revoke trigger to avoid premature locking
CREATE OR REPLACE FUNCTION public.careflow_auto_revoke_access()
RETURNS TRIGGER AS $$
BEGIN
  -- Only revoke on terminal states that mean consultation didn't happen.
  -- 'completed' is excluded so the doctor has time to finish paperwork.
  -- It will naturally expire based on expires_at.
  IF NEW.status IN ('cancelled', 'rejected', 'no_show') THEN
    UPDATE public.careflow_doctor_access_grants
    SET is_revoked = true, updated_at = now()
    WHERE appointment_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5. Harden INSERT policies for Consultations and Prescriptions
DROP POLICY IF EXISTS "Doctor can insert consultation" ON public.careflow_consultations;
CREATE POLICY "Doctor can insert consultation"
  ON public.careflow_consultations FOR INSERT
  TO authenticated
  WITH CHECK (
    doctor_id = auth.uid() AND 
    EXISTS (
      SELECT 1 FROM public.careflow_appointments a
      WHERE a.doctor_id = auth.uid()
        AND a.patient_id = careflow_consultations.patient_id
        -- Requires a valid appointment on the same day or currently active
        AND (a.status IN ('in_consultation', 'checked_in', 'waiting', 'completed') OR a.appointment_date = CURRENT_DATE)
    )
  );

DROP POLICY IF EXISTS "Doctor can insert prescription" ON public.careflow_prescriptions;
CREATE POLICY "Doctor can insert prescription"
  ON public.careflow_prescriptions FOR INSERT
  TO authenticated
  WITH CHECK (
    doctor_id = auth.uid() AND 
    EXISTS (
      SELECT 1 FROM public.careflow_appointments a
      WHERE a.doctor_id = auth.uid()
        AND a.patient_id = careflow_prescriptions.patient_id
        AND (a.status IN ('in_consultation', 'checked_in', 'waiting', 'completed') OR a.appointment_date = CURRENT_DATE)
    )
  );

-- 6. Secure the Storage Bucket (ensure careflow-reports is private and restricted)
-- First, ensure the bucket exists and is set to private
INSERT INTO storage.buckets (id, name, public)
VALUES ('careflow-reports', 'careflow-reports', false)
ON CONFLICT (id) DO UPDATE SET public = false;

-- Policy to allow patients to read their own reports
DROP POLICY IF EXISTS "Patients can read own reports in storage" ON storage.objects;
CREATE POLICY "Patients can read own reports in storage"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'careflow-reports' AND
  (storage.foldername(name))[1] = auth.uid()::text -- assuming path is patient_id/...
);

-- Policy to allow doctors to read reports if they have active access
DROP POLICY IF EXISTS "Authorized doctors can read reports in storage" ON storage.objects;
CREATE POLICY "Authorized doctors can read reports in storage"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'careflow-reports' AND
  public.careflow_has_active_access((storage.foldername(name))[1]::uuid, auth.uid())
);

-- Policy to allow clinics/labs/doctors to upload
DROP POLICY IF EXISTS "Authorized users can upload reports" ON storage.objects;
CREATE POLICY "Authorized users can upload reports"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'careflow-reports');
