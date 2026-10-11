-- ============================================================
-- CAREFLOW DATABASE MIGRATION: MEDICAL HISTORY ACCESS
-- ============================================================

-- 1. Create access grants table
CREATE TABLE IF NOT EXISTS public.careflow_doctor_access_grants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id uuid REFERENCES public.careflow_appointments(id) ON DELETE CASCADE,
  patient_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  doctor_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  clinic_id uuid REFERENCES public.clinics(id) ON DELETE CASCADE,
  scope text DEFAULT 'full_history',
  purpose text DEFAULT 'appointment_consultation',
  granted_at timestamptz DEFAULT now(),
  expires_at timestamptz,
  is_revoked boolean DEFAULT false,
  consent_reference text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.careflow_doctor_access_grants ENABLE ROW LEVEL SECURITY;

-- Patients can view their grants
CREATE POLICY "Patients can view their grants"
  ON public.careflow_doctor_access_grants FOR SELECT
  TO authenticated
  USING (patient_id = auth.uid());

-- Doctors can view their active grants
CREATE POLICY "Doctors can view their active grants"
  ON public.careflow_doctor_access_grants FOR SELECT
  TO authenticated
  USING (doctor_id = auth.uid());

-- Clinics can view grants related to their clinic
CREATE POLICY "Clinics can view their grants"
  ON public.careflow_doctor_access_grants FOR SELECT
  TO authenticated
  USING (clinic_id = auth.uid());

-- 2. Helper function to check if a doctor has active access to a patient
CREATE OR REPLACE FUNCTION public.careflow_has_active_access(p_patient_id uuid, p_doctor_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.careflow_doctor_access_grants
    WHERE patient_id = p_patient_id
      AND doctor_id = p_doctor_id
      AND is_revoked = false
      AND (expires_at IS NULL OR expires_at > now())
  );
$$;

-- 3. Update existing RLS policies to allow cross-clinic/doctor access if authorized

-- For Consultations
CREATE POLICY "Authorized doctors can read consultations via grant"
  ON public.careflow_consultations FOR SELECT
  TO authenticated
  USING (
    public.careflow_has_active_access(patient_id, auth.uid())
  );

-- For Prescriptions
CREATE POLICY "Authorized doctors can read prescriptions via grant"
  ON public.careflow_prescriptions FOR SELECT
  TO authenticated
  USING (
    public.careflow_has_active_access(patient_id, auth.uid())
  );

-- For Reports
CREATE POLICY "Authorized doctors can read reports via grant"
  ON public.careflow_reports FOR SELECT
  TO authenticated
  USING (
    public.careflow_has_active_access(patient_id, auth.uid())
  );

-- 4. RPC to grant access during booking (or check-in)
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
AS $$
DECLARE
  v_grant_id uuid;
BEGIN
  -- Insert the grant
  INSERT INTO public.careflow_doctor_access_grants (
    appointment_id, patient_id, doctor_id, clinic_id, expires_at
  ) VALUES (
    p_appointment_id, p_patient_id, p_doctor_id, p_clinic_id, now() + (p_hours_valid || ' hours')::interval
  )
  RETURNING id INTO v_grant_id;

  RETURN jsonb_build_object('success', true, 'grant_id', v_grant_id);
END;
$$;

-- 5. RPC to revoke access (when consultation ends, or manually)
CREATE OR REPLACE FUNCTION public.careflow_revoke_doctor_access(
  p_appointment_id uuid
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.careflow_doctor_access_grants
  SET is_revoked = true, updated_at = now()
  WHERE appointment_id = p_appointment_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 6. Trigger to automatically revoke access when appointment is completed, cancelled, or rejected
CREATE OR REPLACE FUNCTION public.careflow_auto_revoke_access()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status IN ('completed', 'cancelled', 'rejected') THEN
    UPDATE public.careflow_doctor_access_grants
    SET is_revoked = true, updated_at = now()
    WHERE appointment_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_auto_revoke_access ON public.careflow_appointments;
CREATE TRIGGER tr_auto_revoke_access
AFTER UPDATE OF status ON public.careflow_appointments
FOR EACH ROW
WHEN (NEW.status IS DISTINCT FROM OLD.status)
EXECUTE FUNCTION public.careflow_auto_revoke_access();
