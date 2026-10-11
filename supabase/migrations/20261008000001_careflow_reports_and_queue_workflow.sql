-- ============================================================
-- CAREFLOW MIGRATION: Reports Storage, Atomic Queue Workflow
-- ============================================================

-- 1. Create careflow_reports metadata table
CREATE TABLE IF NOT EXISTS public.careflow_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  clinic_id uuid REFERENCES public.clinics(id) ON DELETE SET NULL,
  doctor_id uuid REFERENCES public.doctors(id) ON DELETE SET NULL,
  appointment_id uuid REFERENCES public.careflow_appointments(id) ON DELETE SET NULL,
  title text NOT NULL,
  report_type text NOT NULL,
  report_date date NOT NULL DEFAULT CURRENT_DATE,
  description text,
  file_url text NOT NULL,
  storage_path text,
  file_name text,
  file_size text,
  created_at timestamptz DEFAULT now()
);

-- 2. Enhance careflow_appointments with lifecycle timestamps
ALTER TABLE IF EXISTS public.careflow_appointments
  ADD COLUMN IF NOT EXISTS called_at timestamptz,
  ADD COLUMN IF NOT EXISTS consultation_started_at timestamptz,
  ADD COLUMN IF NOT EXISTS consultation_completed_at timestamptz;

-- 3. Enable RLS on careflow_reports
ALTER TABLE public.careflow_reports ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for careflow_reports

-- Patients can view only their own reports
DROP POLICY IF EXISTS "Patients can view their own reports" ON public.careflow_reports;
CREATE POLICY "Patients can view their own reports"
  ON public.careflow_reports FOR SELECT
  TO authenticated
  USING (patient_id = auth.uid());

-- Clinics can view and insert reports for patients they manage
DROP POLICY IF EXISTS "Clinics can manage reports for their clinic" ON public.careflow_reports;
CREATE POLICY "Clinics can manage reports for their clinic"
  ON public.careflow_reports FOR ALL
  TO authenticated
  USING (
    clinic_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.careflow_appointments a
      WHERE a.id = appointment_id AND a.clinic_id = auth.uid()
    )
  );

-- Doctors can view reports for their patients
DROP POLICY IF EXISTS "Doctors can view reports for authorized patients" ON public.careflow_reports;
CREATE POLICY "Doctors can view reports for authorized patients"
  ON public.careflow_reports FOR SELECT
  TO authenticated
  USING (
    doctor_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.careflow_appointments a
      WHERE a.patient_id = careflow_reports.patient_id AND a.doctor_id = auth.uid()
    )
  );

-- 5. Realtime publication for careflow_reports
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.careflow_reports;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;

-- 6. Atomic Doctor Next Patient Workflow (WAITING -> CALLED)
CREATE OR REPLACE FUNCTION public.careflow_doctor_call_next_patient(p_doctor_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_next_appointment RECORD;
  v_clinic_id UUID;
  v_token INT;
BEGIN
  -- 1. Find next waiting appointment for this doctor safely with row lock
  SELECT * INTO v_next_appointment
  FROM public.careflow_appointments
  WHERE doctor_id = p_doctor_id
    AND status IN ('checked_in', 'waiting')
  ORDER BY token_number ASC, appointment_time ASC
  LIMIT 1
  FOR UPDATE SKIP LOCKED;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'No waiting patients found for this doctor.'
    );
  END IF;

  v_clinic_id := v_next_appointment.clinic_id;
  v_token := v_next_appointment.token_number;

  -- 2. Atomically update appointment to 'called'
  UPDATE public.careflow_appointments
  SET status = 'called',
      called_at = now()
  WHERE id = v_next_appointment.id;

  -- 3. Update now_serving in queue counter if clinic_id is present
  IF v_clinic_id IS NOT NULL AND v_token > 0 THEN
    UPDATE public.careflow_queue_counters
    SET now_serving = v_token,
        updated_at = now()
    WHERE clinic_id = v_clinic_id;
  END IF;

  -- 4. Send notification to patient
  INSERT INTO public.careflow_notifications(user_id, title, body, type, is_read, created_at)
  VALUES (
    v_next_appointment.patient_id,
    'Your Turn: Now Calling #' || v_token,
    'The doctor is ready for your consultation. Please proceed to the consultation room.',
    'queue',
    false,
    now()
  );

  RETURN jsonb_build_object(
    'success', true,
    'appointment_id', v_next_appointment.id,
    'token_number', v_token,
    'patient_id', v_next_appointment.patient_id,
    'status', 'called'
  );
END;
$$;

-- 7. Atomic Start Consultation (CALLED -> IN_CONSULTATION)
CREATE OR REPLACE FUNCTION public.careflow_start_consultation(p_appointment_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
BEGIN
  SELECT * INTO v_appointment
  FROM public.careflow_appointments
  WHERE id = p_appointment_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'Appointment not found.');
  END IF;

  UPDATE public.careflow_appointments
  SET status = 'in_consultation',
      consultation_started_at = now()
  WHERE id = p_appointment_id;

  RETURN jsonb_build_object(
    'success', true,
    'appointment_id', p_appointment_id,
    'status', 'in_consultation'
  );
END;
$$;

