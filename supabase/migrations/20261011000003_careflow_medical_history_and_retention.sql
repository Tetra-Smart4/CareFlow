-- ============================================================
-- CAREFLOW MIGRATION: PERMANENT MEDICAL HISTORY, NON-DELETION, AUDIT LOGGING & QUEUE HARDENING
-- Version: 20261011000003
-- ============================================================

-- 1. PERMANENT PATIENT MEDICAL HISTORY QUESTIONNAIRE TABLE
CREATE TABLE IF NOT EXISTS public.careflow_patient_medical_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  questionnaire_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed')),
  completion_percentage INT NOT NULL DEFAULT 0,
  last_reviewed_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT uq_patient_medical_history UNIQUE (patient_id)
);

CREATE INDEX IF NOT EXISTS idx_patient_medical_history_patient 
  ON public.careflow_patient_medical_history (patient_id);

-- 2. AUDIT LOGS TABLE FOR CLINICAL AUDIT TRAIL
CREATE TABLE IF NOT EXISTS public.careflow_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE IF EXISTS public.careflow_audit_logs
  ADD COLUMN IF NOT EXISTS actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS action TEXT,
  ADD COLUMN IF NOT EXISTS resource_type TEXT,
  ADD COLUMN IF NOT EXISTS resource_id TEXT,
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_audit_logs_resource 
  ON public.careflow_audit_logs (resource_type, resource_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor 
  ON public.careflow_audit_logs (actor_id, created_at);

-- 3. RLS POLICIES FOR MEDICAL HISTORY
ALTER TABLE public.careflow_patient_medical_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Patients can view own medical history" ON public.careflow_patient_medical_history;
CREATE POLICY "Patients can view own medical history"
  ON public.careflow_patient_medical_history FOR SELECT
  USING (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Patients can update own medical history" ON public.careflow_patient_medical_history;
CREATE POLICY "Patients can update own medical history"
  ON public.careflow_patient_medical_history FOR UPDATE
  USING (auth.uid() = patient_id)
  WITH CHECK (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Patients can insert own medical history" ON public.careflow_patient_medical_history;
CREATE POLICY "Patients can insert own medical history"
  ON public.careflow_patient_medical_history FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Authorized doctors can view patient medical history" ON public.careflow_patient_medical_history;
CREATE POLICY "Authorized doctors can view patient medical history"
  ON public.careflow_patient_medical_history FOR SELECT
  USING (
    public.careflow_has_active_access(careflow_patient_medical_history.patient_id, auth.uid())
    OR EXISTS (
      SELECT 1 FROM public.careflow_appointments a
      WHERE a.patient_id = careflow_patient_medical_history.patient_id
        AND a.doctor_id = auth.uid()
        AND a.status IN ('checked_in', 'waiting', 'in_consultation')
    )
  );

-- 4. NON-DELETION ENFORCEMENT TRIGGER (BLOCKS RECORD ERASURE BY REGULAR USERS)
CREATE OR REPLACE FUNCTION public.careflow_prevent_clinical_record_deletion()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Service role or platform admin emergency procedure exception
  IF auth.role() = 'service_role' THEN
    RETURN OLD;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'platform_admin'
  ) THEN
    -- Log administrative deletion for compliance audit
    INSERT INTO public.careflow_audit_logs (actor_id, action, resource_type, resource_id, metadata)
    VALUES (auth.uid(), 'ADMIN_DELETE', TG_TABLE_NAME, OLD.id::TEXT, jsonb_build_object('reason', 'Administrative deletion'));
    RETURN OLD;
  END IF;

  -- Block deletion for all patients, doctors, clinics, and staff
  RAISE EXCEPTION 'Operation blocked: Clinical health records cannot be deleted. Corrections must be submitted as amendments.';
END;
$$;

-- Apply non-deletion trigger to medical history, consultations, and reports
DROP TRIGGER IF EXISTS trg_prevent_med_history_delete ON public.careflow_patient_medical_history;
CREATE TRIGGER trg_prevent_med_history_delete
  BEFORE DELETE ON public.careflow_patient_medical_history
  FOR EACH ROW EXECUTE FUNCTION public.careflow_prevent_clinical_record_deletion();

DROP TRIGGER IF EXISTS trg_prevent_consultation_delete ON public.careflow_consultations;
CREATE TRIGGER trg_prevent_consultation_delete
  BEFORE DELETE ON public.careflow_consultations
  FOR EACH ROW EXECUTE FUNCTION public.careflow_prevent_clinical_record_deletion();

DROP TRIGGER IF EXISTS trg_prevent_report_delete ON public.careflow_reports;
CREATE TRIGGER trg_prevent_report_delete
  BEFORE DELETE ON public.careflow_reports
  FOR EACH ROW EXECUTE FUNCTION public.careflow_prevent_clinical_record_deletion();

-- 5. RPC: SAVE MEDICAL HISTORY QUESTIONNAIRE (TRANSACTION SAFE)
CREATE OR REPLACE FUNCTION public.careflow_save_medical_history(
  p_questionnaire JSONB,
  p_is_completed BOOLEAN DEFAULT false,
  p_completion_percentage INT DEFAULT 100
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_patient_id UUID := auth.uid();
  v_status TEXT := CASE WHEN p_is_completed THEN 'completed' ELSE 'in_progress' END;
BEGIN
  IF v_patient_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: User must be authenticated to save medical history.';
  END IF;

  INSERT INTO public.careflow_patient_medical_history (
    patient_id,
    questionnaire_data,
    status,
    completion_percentage,
    last_reviewed_at,
    updated_at
  ) VALUES (
    v_patient_id,
    p_questionnaire,
    v_status,
    p_completion_percentage,
    now(),
    now()
  )
  ON CONFLICT (patient_id) DO UPDATE
    SET questionnaire_data = EXCLUDED.questionnaire_data,
        status = EXCLUDED.status,
        completion_percentage = EXCLUDED.completion_percentage,
        last_reviewed_at = now(),
        updated_at = now();

  -- Audit log update
  INSERT INTO public.careflow_audit_logs (actor_id, action, resource_type, resource_id, metadata)
  VALUES (
    v_patient_id,
    CASE WHEN p_is_completed THEN 'COMPLETED_QUESTIONNAIRE' ELSE 'UPDATED_QUESTIONNAIRE' END,
    'patient_medical_history',
    v_patient_id::TEXT,
    jsonb_build_object('completion_percentage', p_completion_percentage)
  );

  RETURN jsonb_build_object('success', true, 'status', v_status);
END;
$$;

-- 6. HARDEN CALL NEXT PATIENT CONCURRENCY (ELIMINATE RACE CONDITIONS)
CREATE OR REPLACE FUNCTION public.careflow_call_next_patient(p_clinic_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next_appointment RECORD;
  v_now_serving INT;
  v_is_authorized BOOLEAN := false;
BEGIN
  -- Authorization check
  IF auth.role() = 'authenticated' THEN
    IF auth.uid() = p_clinic_id THEN 
      v_is_authorized := true;
    ELSIF EXISTS (SELECT 1 FROM public.clinic_doctors WHERE doctor_id = auth.uid() AND clinic_id = p_clinic_id) THEN 
      v_is_authorized := true;
    ELSIF EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin') THEN 
      v_is_authorized := true; 
    END IF;

    IF NOT v_is_authorized THEN 
      RAISE EXCEPTION 'Unauthorized: Caller is not authorized for this clinic.'; 
    END IF;
  ELSIF auth.role() = 'service_role' THEN 
    v_is_authorized := true; 
  ELSE 
    RAISE EXCEPTION 'Unauthorized: Invalid execution context.'; 
  END IF;

  -- Lock the queue counter to serialize calls for this clinic
  SELECT now_serving INTO v_now_serving 
  FROM public.careflow_queue_counters 
  WHERE clinic_id = p_clinic_id 
  FOR UPDATE;

  -- CRITICAL RACE-SAFETY FIX: Lock the next candidate appointment using FOR UPDATE SKIP LOCKED
  SELECT * INTO v_next_appointment 
  FROM public.careflow_appointments 
  WHERE clinic_id = p_clinic_id 
    AND status IN ('checked_in', 'waiting') 
    AND token_number > 0 
  ORDER BY token_number ASC 
  LIMIT 1 
  FOR UPDATE SKIP LOCKED;

  IF NOT FOUND THEN 
    RETURN jsonb_build_object('success', false, 'message', 'No patients waiting in queue.'); 
  END IF;

  -- Advance now_serving in queue counter to match this patient's token
  UPDATE public.careflow_queue_counters 
  SET now_serving = v_next_appointment.token_number, 
      updated_at = now() 
  WHERE clinic_id = p_clinic_id 
  RETURNING now_serving INTO v_now_serving;

  -- Transition appointment status to in_consultation
  UPDATE public.careflow_appointments 
  SET status = 'in_consultation' 
  WHERE id = v_next_appointment.id;

  -- Send in-app notification to patient
  INSERT INTO public.careflow_notifications(user_id, title, body, type, is_read, created_at) 
  VALUES (
    v_next_appointment.patient_id, 
    'Your Turn: Now Serving #' || v_now_serving, 
    'Please proceed to the doctor consultation room.', 
    'queue', 
    false, 
    now()
  );

  RETURN jsonb_build_object(
    'success', true, 
    'clinic_id', p_clinic_id, 
    'now_serving', v_now_serving, 
    'appointment_id', v_next_appointment.id,
    'patient_id', v_next_appointment.patient_id
  );
END;
$$;
