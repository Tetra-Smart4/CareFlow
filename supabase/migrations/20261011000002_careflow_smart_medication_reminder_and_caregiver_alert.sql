-- ============================================================
-- CAREFLOW MIGRATION: SMART MEDICATION REMINDER & CAREGIVER ALERT SYSTEM
-- Target: Supabase / PostgreSQL Single Source of Truth
-- Version: 20261011000002
-- ============================================================

-- 1. ENHANCE PRESCRIPTIONS TABLE
ALTER TABLE IF EXISTS public.careflow_prescriptions
  ADD COLUMN IF NOT EXISTS start_date DATE DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS end_date DATE,
  ADD COLUMN IF NOT EXISTS administration_times JSONB DEFAULT '["08:00", "20:00"]'::jsonb,
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'discontinued')),
  ADD COLUMN IF NOT EXISTS timezone TEXT DEFAULT 'UTC';

-- 2. ENHANCE MEDICATION ADHERENCE TABLE (SAFE ADDITIVE LIFECYCLE)
-- Ensure table exists first
CREATE TABLE IF NOT EXISTS public.careflow_medication_adherence (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    prescription_id UUID REFERENCES public.careflow_prescriptions(id) ON DELETE CASCADE,
    medicine_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'scheduled',
    scheduled_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Safely drop old check constraint if present and apply the complete lifecycle:
DO $$
DECLARE
  v_con_name text;
BEGIN
  FOR v_con_name IN (
    SELECT conname 
    FROM pg_constraint 
    WHERE conrelid = 'public.careflow_medication_adherence'::regclass 
      AND contype = 'c' 
      AND pg_get_constraintdef(oid) LIKE '%status%'
  ) LOOP
    EXECUTE 'ALTER TABLE public.careflow_medication_adherence DROP CONSTRAINT ' || quote_ident(v_con_name);
  END LOOP;
END $$;

ALTER TABLE public.careflow_medication_adherence
  ADD CONSTRAINT careflow_medication_adherence_status_check
  CHECK (status IN ('scheduled', 'taken', 'not_taken', 'unconfirmed', 'missed'));

-- Add necessary timestamp, dosage, and escalation metadata columns
ALTER TABLE public.careflow_medication_adherence
  ADD COLUMN IF NOT EXISTS dosage TEXT,
  ADD COLUMN IF NOT EXISTS instructions TEXT,
  ADD COLUMN IF NOT EXISTS taken_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS reported_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS patient_notes TEXT,
  ADD COLUMN IF NOT EXISTS reminder_sent_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS caregiver_escalated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS escalation_status TEXT DEFAULT 'pending' 
    CHECK (escalation_status IN ('pending', 'not_required', 'escalated', 'resolved')),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- Ensure unique constraint on (prescription_id, scheduled_time) to prevent duplicate dose generation
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conrelid = 'public.careflow_medication_adherence'::regclass 
      AND conname = 'uq_prescription_scheduled_time'
  ) THEN
    ALTER TABLE public.careflow_medication_adherence
      ADD CONSTRAINT uq_prescription_scheduled_time UNIQUE (prescription_id, scheduled_time);
  END IF;
END $$;

-- Indexes for lightning fast scheduler queries and adherence history
CREATE INDEX IF NOT EXISTS idx_adherence_patient_sched 
  ON public.careflow_medication_adherence (patient_id, scheduled_time);

CREATE INDEX IF NOT EXISTS idx_adherence_due_lookup 
  ON public.careflow_medication_adherence (status, scheduled_time) 
  WHERE status IN ('scheduled', 'unconfirmed');

-- 3. REGISTERED FAMILY ACCESS TABLE
CREATE TABLE IF NOT EXISTS public.careflow_family_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  relationship TEXT NOT NULL DEFAULT 'family_member',
  active BOOLEAN NOT NULL DEFAULT true,
  can_view_notifications BOOLEAN NOT NULL DEFAULT true,
  can_view_prescriptions BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT uq_family_patient UNIQUE (family_user_id, patient_id)
);

CREATE INDEX IF NOT EXISTS idx_family_access_patient 
  ON public.careflow_family_access (patient_id, active);
CREATE INDEX IF NOT EXISTS idx_family_access_user 
  ON public.careflow_family_access (family_user_id, active);

-- 4. NORMALIZED CAREGIVER MEDICATION ALERT CONSENT MODEL
CREATE TABLE IF NOT EXISTS public.careflow_medication_alert_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  contact_type TEXT NOT NULL CHECK (contact_type IN ('family_account', 'emergency_contact')),
  family_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  emergency_contact_id UUID REFERENCES public.emergency_contacts(id) ON DELETE CASCADE,
  medication_alert_permission BOOLEAN NOT NULL DEFAULT true,
  consent_status TEXT NOT NULL DEFAULT 'granted' CHECK (consent_status IN ('granted', 'revoked')),
  consented_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at TIMESTAMPTZ,
  audit_metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT chk_consent_target CHECK (
    (contact_type = 'family_account' AND family_user_id IS NOT NULL) OR
    (contact_type = 'emergency_contact' AND emergency_contact_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_uq_patient_family_consent 
  ON public.careflow_medication_alert_consents (patient_id, family_user_id) 
  WHERE family_user_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_uq_patient_em_consent 
  ON public.careflow_medication_alert_consents (patient_id, emergency_contact_id) 
  WHERE emergency_contact_id IS NOT NULL;

-- 5. DEVICE TOKENS TABLE (FOR FCM PUSH NOTIFICATIONS)
CREATE TABLE IF NOT EXISTS public.careflow_device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'android',
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_seen_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT uq_user_fcm_token UNIQUE (user_id, fcm_token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user 
  ON public.careflow_device_tokens (user_id, is_active);

-- 6. AUDITABLE NOTIFICATION EVENTS & OUTBOX (DUPLICATE PREVENTION)
CREATE TABLE IF NOT EXISTS public.careflow_medication_alert_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dose_id UUID NOT NULL REFERENCES public.careflow_medication_adherence(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN ('patient_reminder', 'caregiver_escalation', 'dose_resolved')),
  recipient_type TEXT NOT NULL CHECK (recipient_type IN ('patient', 'family', 'emergency_contact')),
  recipient_id TEXT NOT NULL,
  delivery_channel TEXT NOT NULL CHECK (delivery_channel IN ('fcm', 'in_app', 'sms', 'email')),
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'created' CHECK (status IN ('created', 'attempted', 'provider_accepted', 'delivered', 'failed', 'pending_provider_config')),
  failure_reason TEXT,
  retry_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  dispatched_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT uq_medication_event UNIQUE (dose_id, event_type, recipient_type, recipient_id, delivery_channel)
);

CREATE INDEX IF NOT EXISTS idx_alert_events_pending 
  ON public.careflow_medication_alert_events (status, created_at) 
  WHERE status IN ('created', 'attempted');

-- 7. ENHANCE NOTIFICATIONS TABLE WITH DOSE REFERENCE
ALTER TABLE IF EXISTS public.careflow_notifications
  ADD COLUMN IF NOT EXISTS dose_id UUID,
  ADD COLUMN IF NOT EXISTS action_type TEXT;

-- Realtime publication updates
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.careflow_medication_adherence;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.careflow_family_access;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.careflow_medication_alert_events;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;

-- 8. TRANSACTIONAL BACKEND OPERATIONS (RPCS)

-- A. Generate scheduled doses from a saved prescription
CREATE OR REPLACE FUNCTION public.careflow_generate_doses_for_prescription(p_prescription_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_presc RECORD;
  v_start DATE;
  v_end DATE;
  v_day DATE;
  v_time_text TEXT;
  v_time_elem JSONB;
  v_sched_dt TIMESTAMPTZ;
  v_count INT := 0;
  v_duration_days INT := 7;
BEGIN
  SELECT * INTO v_presc 
  FROM public.careflow_prescriptions 
  WHERE id = p_prescription_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Prescription not found');
  END IF;

  -- Caller check: Doctor who created it, or patient it belongs to, or service role
  IF auth.uid() IS NOT NULL AND auth.uid() != v_presc.doctor_id AND auth.uid() != v_presc.patient_id THEN
    RAISE EXCEPTION 'Unauthorized: Only prescribing doctor or patient can generate dose schedules.';
  END IF;

  v_start := COALESCE(v_presc.start_date, CURRENT_DATE);

  -- Infer duration if end_date not explicitly set
  IF v_presc.end_date IS NOT NULL THEN
    v_end := v_presc.end_date;
  ELSE
    -- Check if duration string has digits (e.g. '5 days')
    BEGIN
      IF v_presc.duration IS NOT NULL AND v_presc.duration ~ '^[0-9]+' THEN
        v_duration_days := SUBSTRING(v_presc.duration FROM '^[0-9]+')::INT;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      v_duration_days := 7;
    END;
    v_end := v_start + (v_duration_days - 1);
  END IF;

  -- Ensure end date is not before start date
  IF v_end < v_start THEN
    v_end := v_start;
  END IF;

  -- Cap max generation to 90 days to maintain system performance
  IF (v_end - v_start) > 90 THEN
    v_end := v_start + 89;
  END IF;

  -- Ensure administration_times is not empty
  IF v_presc.administration_times IS NULL OR jsonb_array_length(v_presc.administration_times) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Exact administration times are required.');
  END IF;

  -- Loop through each date in the period
  v_day := v_start;
  WHILE v_day <= v_end LOOP
    FOR v_time_elem IN SELECT * FROM jsonb_array_elements_text(v_presc.administration_times) LOOP
      v_time_text := trim(v_time_elem::TEXT);
      BEGIN
        v_sched_dt := (v_day || ' ' || v_time_text)::TIMESTAMPTZ;
        
        -- Insert dose idempotently (preserving any already existing record)
        INSERT INTO public.careflow_medication_adherence (
          patient_id,
          prescription_id,
          medicine_name,
          dosage,
          instructions,
          status,
          scheduled_time,
          escalation_status,
          created_at
        ) VALUES (
          v_presc.patient_id,
          v_presc.id,
          COALESCE(v_presc.medicine_name, 'Prescribed Medicine'),
          v_presc.dosage,
          v_presc.instructions,
          'scheduled',
          v_sched_dt,
          'pending',
          now()
        )
        ON CONFLICT (prescription_id, scheduled_time) DO NOTHING;

        IF FOUND THEN
          v_count := v_count + 1;
        END IF;
      EXCEPTION WHEN OTHERS THEN
        -- Skip invalid time formats safely
        NULL;
      END;
    END LOOP;
    v_day := v_day + 1;
  END LOOP;

  RETURN jsonb_build_object(
    'success', true, 
    'prescription_id', p_prescription_id, 
    'doses_created', v_count,
    'start_date', v_start,
    'end_date', v_end
  );
END;
$$;

-- B. Atomically claim due doses and initiate zero-grace-period escalation
CREATE OR REPLACE FUNCTION public.careflow_claim_and_process_due_doses(p_limit INT DEFAULT 50)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_dose RECORD;
  v_family RECORD;
  v_em RECORD;
  v_patient_name TEXT;
  v_processed_count INT := 0;
  v_escalated_count INT := 0;
BEGIN
  -- Process up to p_limit scheduled doses due now with row locks
  FOR v_dose IN (
    SELECT * 
    FROM public.careflow_medication_adherence
    WHERE scheduled_time <= now() 
      AND status = 'scheduled'
    ORDER BY scheduled_time ASC
    LIMIT p_limit
    FOR UPDATE SKIP LOCKED
  ) LOOP
    -- Get patient full name
    SELECT full_name INTO v_patient_name 
    FROM public.profiles 
    WHERE id = v_dose.patient_id;
    v_patient_name := COALESCE(v_patient_name, 'Patient');

    -- Transition status to unconfirmed
    UPDATE public.careflow_medication_adherence
    SET status = 'unconfirmed',
        reminder_sent_at = now(),
        caregiver_escalated_at = now(),
        escalation_status = 'escalated',
        updated_at = now()
    WHERE id = v_dose.id;

    -- 1. Create Patient Reminder Notification Event
    INSERT INTO public.careflow_medication_alert_events (
      dose_id,
      event_type,
      recipient_type,
      recipient_id,
      delivery_channel,
      payload,
      status,
      dispatched_at
    ) VALUES (
      v_dose.id,
      'patient_reminder',
      'patient',
      v_dose.patient_id::TEXT,
      'in_app',
      jsonb_build_object(
        'title', 'Time for your medicine',
        'body', 'Your scheduled dose of ' || v_dose.medicine_name || ' is due. Please confirm your dose.',
        'dose_id', v_dose.id,
        'medicine_name', v_dose.medicine_name,
        'scheduled_time', v_dose.scheduled_time,
        'actions', jsonb_build_array('Taken', 'Not taken')
      ),
      'delivered',
      now()
    ) ON CONFLICT (dose_id, event_type, recipient_type, recipient_id, delivery_channel) DO NOTHING;

    -- Also insert into standard careflow_notifications for in-app bell
    INSERT INTO public.careflow_notifications (
      user_id,
      title,
      body,
      type,
      dose_id,
      action_type,
      is_read,
      created_at
    ) VALUES (
      v_dose.patient_id,
      'Time for your medicine',
      'Your scheduled dose of ' || v_dose.medicine_name || ' is due. Please confirm your dose.',
      'medication_reminder',
      v_dose.id,
      'dose_confirmation',
      false,
      now()
    );

    -- 2. ZERO GRACE PERIOD: Immediate Caregiver Escalation
    -- A. Check authorized family accounts with active consent
    FOR v_family IN (
      SELECT fa.family_user_id
      FROM public.careflow_family_access fa
      JOIN public.careflow_medication_alert_consents mac
        ON mac.patient_id = fa.patient_id 
       AND mac.family_user_id = fa.family_user_id
       AND mac.consent_status = 'granted'
       AND mac.medication_alert_permission = true
      WHERE fa.patient_id = v_dose.patient_id
        AND fa.active = true
    ) LOOP
      -- Insert caregiver alert event (Unique constraint prevents duplicates)
      INSERT INTO public.careflow_medication_alert_events (
        dose_id,
        event_type,
        recipient_type,
        recipient_id,
        delivery_channel,
        payload,
        status,
        dispatched_at
      ) VALUES (
        v_dose.id,
        'caregiver_escalation',
        'family',
        v_family.family_user_id::TEXT,
        'in_app',
        jsonb_build_object(
          'title', 'CareFlow — Medicine dose not confirmed',
          'body', v_patient_name || ' has not confirmed the scheduled dose of ' || v_dose.medicine_name || '.',
          'dose_id', v_dose.id,
          'patient_id', v_dose.patient_id,
          'patient_name', v_patient_name,
          'medicine_name', v_dose.medicine_name,
          'scheduled_time', v_dose.scheduled_time
        ),
        'delivered',
        now()
      ) ON CONFLICT (dose_id, event_type, recipient_type, recipient_id, delivery_channel) DO NOTHING;

      -- In-app notification for family member
      INSERT INTO public.careflow_notifications (
        user_id,
        title,
        body,
        type,
        dose_id,
        action_type,
        is_read,
        created_at
      ) VALUES (
        v_family.family_user_id,
        'CareFlow — Medicine dose not confirmed',
        v_patient_name || ' has not confirmed the scheduled dose of ' || v_dose.medicine_name || '.',
        'caregiver_alert',
        v_dose.id,
        'escalation_review',
        false,
        now()
      );
      v_escalated_count := v_escalated_count + 1;
    END LOOP;

    -- B. Check emergency contacts with active consent
    FOR v_em IN (
      SELECT ec.id, ec.name, ec.phone
      FROM public.emergency_contacts ec
      JOIN public.careflow_medication_alert_consents mac
        ON mac.patient_id = ec.patient_id 
       AND mac.emergency_contact_id = ec.id
       AND mac.consent_status = 'granted'
       AND mac.medication_alert_permission = true
      WHERE ec.patient_id = v_dose.patient_id
    ) LOOP
      -- Honest audit: Record channel as pending_provider_config since no live SMS gateway is connected
      INSERT INTO public.careflow_medication_alert_events (
        dose_id,
        event_type,
        recipient_type,
        recipient_id,
        delivery_channel,
        payload,
        status,
        failure_reason,
        created_at
      ) VALUES (
        v_dose.id,
        'caregiver_escalation',
        'emergency_contact',
        v_em.id::TEXT,
        'sms',
        jsonb_build_object(
          'contact_name', v_em.name,
          'phone', v_em.phone,
          'title', 'CareFlow — Medicine dose not confirmed',
          'body', v_patient_name || ' has not confirmed the scheduled dose of ' || v_dose.medicine_name || '.'
        ),
        'pending_provider_config',
        'External SMS gateway credentials not configured in current environment',
        now()
      ) ON CONFLICT (dose_id, event_type, recipient_type, recipient_id, delivery_channel) DO NOTHING;
    END LOOP;

    v_processed_count := v_processed_count + 1;
  END LOOP;

  RETURN jsonb_build_object(
    'success', true, 
    'doses_processed', v_processed_count, 
    'caregiver_escalations_created', v_escalated_count
  );
END;
$$;

-- C. Patient confirms dose taken
CREATE OR REPLACE FUNCTION public.careflow_confirm_dose_taken(p_dose_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_dose RECORD;
BEGIN
  SELECT * INTO v_dose 
  FROM public.careflow_medication_adherence 
  WHERE id = p_dose_id FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Dose not found');
  END IF;

  -- Caller validation: Only the patient who owns the dose can confirm it
  IF auth.uid() != v_dose.patient_id THEN
    RAISE EXCEPTION 'Unauthorized: You can only confirm your own medication doses.';
  END IF;

  -- Idempotent check: if already taken, return state
  IF v_dose.status = 'taken' THEN
    RETURN jsonb_build_object(
      'success', true, 
      'status', 'taken', 
      'taken_at', v_dose.taken_at,
      'already_confirmed', true
    );
  END IF;

  -- Update state atomically
  UPDATE public.careflow_medication_adherence
  SET status = 'taken',
      taken_at = now(),
      reported_at = now(),
      escalation_status = CASE 
        WHEN escalation_status = 'escalated' THEN 'resolved'
        ELSE 'not_required'
      END,
      updated_at = now()
  WHERE id = p_dose_id;

  -- Record resolution event for audit
  INSERT INTO public.careflow_medication_alert_events (
    dose_id,
    event_type,
    recipient_type,
    recipient_id,
    delivery_channel,
    payload,
    status,
    dispatched_at
  ) VALUES (
    p_dose_id,
    'dose_resolved',
    'patient',
    v_dose.patient_id::TEXT,
    'in_app',
    jsonb_build_object('dose_id', p_dose_id, 'status', 'taken', 'resolved_at', now()),
    'delivered',
    now()
  ) ON CONFLICT (dose_id, event_type, recipient_type, recipient_id, delivery_channel) DO NOTHING;

  RETURN jsonb_build_object(
    'success', true, 
    'status', 'taken', 
    'taken_at', now(),
    'already_confirmed', false
  );
END;
$$;

-- D. Patient reports dose not taken
CREATE OR REPLACE FUNCTION public.careflow_report_dose_not_taken(p_dose_id UUID, p_reason TEXT DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_dose RECORD;
  v_patient_name TEXT;
  v_family RECORD;
BEGIN
  SELECT * INTO v_dose 
  FROM public.careflow_medication_adherence 
  WHERE id = p_dose_id FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Dose not found');
  END IF;

  IF auth.uid() != v_dose.patient_id THEN
    RAISE EXCEPTION 'Unauthorized: You can only report your own medication doses.';
  END IF;

  UPDATE public.careflow_medication_adherence
  SET status = 'not_taken',
      reported_at = now(),
      patient_notes = p_reason,
      escalation_status = 'escalated',
      caregiver_escalated_at = COALESCE(caregiver_escalated_at, now()),
      updated_at = now()
  WHERE id = p_dose_id;

  SELECT full_name INTO v_patient_name FROM public.profiles WHERE id = v_dose.patient_id;
  v_patient_name := COALESCE(v_patient_name, 'Patient');

  -- Zero-grace-period escalation if initial caregiver alert not yet created
  FOR v_family IN (
    SELECT fa.family_user_id
    FROM public.careflow_family_access fa
    JOIN public.careflow_medication_alert_consents mac
      ON mac.patient_id = fa.patient_id 
     AND mac.family_user_id = fa.family_user_id
     AND mac.consent_status = 'granted'
     AND mac.medication_alert_permission = true
    WHERE fa.patient_id = v_dose.patient_id AND fa.active = true
  ) LOOP
    INSERT INTO public.careflow_medication_alert_events (
      dose_id,
      event_type,
      recipient_type,
      recipient_id,
      delivery_channel,
      payload,
      status,
      dispatched_at
    ) VALUES (
      p_dose_id,
      'caregiver_escalation',
      'family',
      v_family.family_user_id::TEXT,
      'in_app',
      jsonb_build_object(
        'title', 'CareFlow — Medicine explicitly not taken',
        'body', v_patient_name || ' reported NOT taking ' || v_dose.medicine_name || '. Reason: ' || COALESCE(p_reason, 'None stated'),
        'dose_id', p_dose_id,
        'patient_id', v_dose.patient_id,
        'patient_name', v_patient_name,
        'medicine_name', v_dose.medicine_name,
        'scheduled_time', v_dose.scheduled_time
      ),
      'delivered',
      now()
    ) ON CONFLICT (dose_id, event_type, recipient_type, recipient_id, delivery_channel) DO NOTHING;

    INSERT INTO public.careflow_notifications (
      user_id,
      title,
      body,
      type,
      dose_id,
      action_type,
      is_read,
      created_at
    ) VALUES (
      v_family.family_user_id,
      'CareFlow — Medicine explicitly not taken',
      v_patient_name || ' reported NOT taking ' || v_dose.medicine_name || '.',
      'caregiver_alert',
      p_dose_id,
      'escalation_review',
      false,
      now()
    );
  END LOOP;

  RETURN jsonb_build_object('success', true, 'status', 'not_taken');
END;
$$;

-- E. Register device token for push notifications
CREATE OR REPLACE FUNCTION public.careflow_register_device_token(p_token TEXT, p_platform TEXT DEFAULT 'android')
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: Must be logged in to register device token.';
  END IF;

  INSERT INTO public.careflow_device_tokens (user_id, fcm_token, platform, is_active, last_seen_at)
  VALUES (auth.uid(), p_token, p_platform, true, now())
  ON CONFLICT (user_id, fcm_token) DO UPDATE
    SET is_active = true,
        platform = EXCLUDED.platform,
        last_seen_at = now();

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 9. ROW LEVEL SECURITY (RLS) POLICIES

-- MEDICATION ADHERENCE
ALTER TABLE public.careflow_medication_adherence ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Patients can view own adherence" ON public.careflow_medication_adherence;
CREATE POLICY "Patients can view own adherence" 
  ON public.careflow_medication_adherence FOR SELECT 
  USING (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Patients can update own adherence" ON public.careflow_medication_adherence;
CREATE POLICY "Patients can update own adherence" 
  ON public.careflow_medication_adherence FOR UPDATE 
  USING (auth.uid() = patient_id)
  WITH CHECK (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Doctors can view adherence" ON public.careflow_medication_adherence;
CREATE POLICY "Doctors can view adherence" 
  ON public.careflow_medication_adherence FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.careflow_appointments a
      WHERE a.patient_id = careflow_medication_adherence.patient_id 
        AND a.doctor_id = auth.uid()
    ) OR EXISTS (
      SELECT 1 FROM public.careflow_prescriptions p
      WHERE p.id = careflow_medication_adherence.prescription_id
        AND p.doctor_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Family members can view authorized adherence" ON public.careflow_medication_adherence;
CREATE POLICY "Family members can view authorized adherence" 
  ON public.careflow_medication_adherence FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.careflow_family_access fa
      JOIN public.careflow_medication_alert_consents mac
        ON mac.patient_id = fa.patient_id
       AND mac.family_user_id = fa.family_user_id
       AND mac.consent_status = 'granted'
       AND mac.medication_alert_permission = true
      WHERE fa.family_user_id = auth.uid()
        AND fa.patient_id = careflow_medication_adherence.patient_id
        AND fa.active = true
    )
  );

-- FAMILY ACCESS
ALTER TABLE public.careflow_family_access ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Patients can view and manage their family access" ON public.careflow_family_access;
CREATE POLICY "Patients can view and manage their family access"
  ON public.careflow_family_access FOR ALL
  USING (patient_id = auth.uid())
  WITH CHECK (patient_id = auth.uid());

DROP POLICY IF EXISTS "Family members can view their access records" ON public.careflow_family_access;
CREATE POLICY "Family members can view their access records"
  ON public.careflow_family_access FOR SELECT
  USING (family_user_id = auth.uid());

-- CAREGIVER MEDICATION CONSENTS
ALTER TABLE public.careflow_medication_alert_consents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Patients manage own medication consents" ON public.careflow_medication_alert_consents;
CREATE POLICY "Patients manage own medication consents"
  ON public.careflow_medication_alert_consents FOR ALL
  USING (patient_id = auth.uid())
  WITH CHECK (patient_id = auth.uid());

DROP POLICY IF EXISTS "Family members view their granted consent status" ON public.careflow_medication_alert_consents;
CREATE POLICY "Family members view their granted consent status"
  ON public.careflow_medication_alert_consents FOR SELECT
  USING (family_user_id = auth.uid());

-- DEVICE TOKENS
ALTER TABLE public.careflow_device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage their own device tokens" ON public.careflow_device_tokens;
CREATE POLICY "Users manage their own device tokens"
  ON public.careflow_device_tokens FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ALERT EVENTS & OUTBOX
ALTER TABLE public.careflow_medication_alert_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view alerts where they are recipient or patient" ON public.careflow_medication_alert_events;
CREATE POLICY "Users can view alerts where they are recipient or patient"
  ON public.careflow_medication_alert_events FOR SELECT
  USING (
    recipient_id = auth.uid()::TEXT
    OR EXISTS (
      SELECT 1 FROM public.careflow_medication_adherence d
      WHERE d.id = careflow_medication_alert_events.dose_id
        AND d.patient_id = auth.uid()
    )
  );
