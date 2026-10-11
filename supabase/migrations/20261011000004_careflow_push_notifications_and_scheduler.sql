-- ============================================================================
-- CAREFLOW MIGRATION: COMPLETE PUSH NOTIFICATION & SCHEDULER SYSTEM
-- Target: Supabase / PostgreSQL Single Source of Truth
-- Version: 20261011000004
-- ============================================================================

-- 0. ENABLE REQUIRED EXTENSIONS SAFELY
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

-- 1. ENHANCE NOTIFICATIONS TABLE FOR REAL-TIME FCM OUTBOX & DELIVERY AUDIT
ALTER TABLE IF EXISTS public.careflow_notifications
  ADD COLUMN IF NOT EXISTS fcm_status TEXT DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS fcm_message_id TEXT,
  ADD COLUMN IF NOT EXISTS dispatched_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS retry_count INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS next_retry_at TIMESTAMPTZ;

-- Safely expand or enforce check constraint on fcm_status
DO $$
DECLARE
  v_con_name text;
BEGIN
  FOR v_con_name IN (
    SELECT conname 
    FROM pg_constraint 
    WHERE conrelid = 'public.careflow_notifications'::regclass 
      AND contype = 'c' 
      AND pg_get_constraintdef(oid) LIKE '%fcm_status%'
  ) LOOP
    EXECUTE 'ALTER TABLE public.careflow_notifications DROP CONSTRAINT ' || quote_ident(v_con_name);
  END LOOP;
END $$;

ALTER TABLE public.careflow_notifications
  ADD CONSTRAINT careflow_notifications_fcm_status_check
  CHECK (fcm_status IN ('pending', 'processing', 'delivered', 'failed', 'no_tokens', 'skipped'));

CREATE INDEX IF NOT EXISTS idx_notifications_fcm_pending
  ON public.careflow_notifications (fcm_status, next_retry_at, created_at)
  WHERE fcm_status IN ('pending', 'processing', 'failed');

-- 2. ENHANCE MEDICATION ALERT EVENTS TABLE FOR RETRY & FCM MESSAGE ID
ALTER TABLE IF EXISTS public.careflow_medication_alert_events
  ADD COLUMN IF NOT EXISTS next_retry_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS fcm_message_id TEXT;

-- Safely expand status check constraint to include 'processing' and 'dose_resolved'
DO $$
DECLARE
  v_con_name text;
BEGIN
  FOR v_con_name IN (
    SELECT conname 
    FROM pg_constraint 
    WHERE conrelid = 'public.careflow_medication_alert_events'::regclass 
      AND contype = 'c' 
      AND pg_get_constraintdef(oid) LIKE '%status%'
  ) LOOP
    EXECUTE 'ALTER TABLE public.careflow_medication_alert_events DROP CONSTRAINT ' || quote_ident(v_con_name);
  END LOOP;
END $$;

ALTER TABLE public.careflow_medication_alert_events
  ADD CONSTRAINT careflow_alert_events_status_check
  CHECK (status IN ('created', 'attempted', 'processing', 'provider_accepted', 'delivered', 'failed', 'dose_resolved', 'pending_provider_config'));

CREATE INDEX IF NOT EXISTS idx_medication_alert_events_claimable
  ON public.careflow_medication_alert_events (status, next_retry_at, created_at)
  WHERE status IN ('created', 'attempted');

-- 3. ATOMIC OUTBOX CLAIMING RPC FOR MEDICATION ALERTS (FOR UPDATE SKIP LOCKED)
CREATE OR REPLACE FUNCTION public.careflow_claim_pending_alert_events(p_limit INT DEFAULT 50)
RETURNS SETOF public.careflow_medication_alert_events
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  UPDATE public.careflow_medication_alert_events
  SET status = 'processing',
      updated_at = now()
  WHERE id IN (
    SELECT id
    FROM public.careflow_medication_alert_events
    WHERE status IN ('created', 'attempted')
      AND (next_retry_at IS NULL OR next_retry_at <= now())
      AND retry_count < 5
    ORDER BY created_at ASC
    LIMIT p_limit
    FOR UPDATE SKIP LOCKED
  )
  RETURNING *;
END;
$$;

-- 4. ATOMIC OUTBOX CLAIMING RPC FOR GENERAL NOTIFICATIONS (FOR UPDATE SKIP LOCKED)
CREATE OR REPLACE FUNCTION public.careflow_claim_pending_notifications(p_limit INT DEFAULT 50)
RETURNS SETOF public.careflow_notifications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  UPDATE public.careflow_notifications
  SET fcm_status = 'processing',
      retry_count = COALESCE(retry_count, 0) + 1
  WHERE id IN (
    SELECT id
    FROM public.careflow_notifications
    WHERE fcm_status IN ('pending', 'failed')
      AND (next_retry_at IS NULL OR next_retry_at <= now())
      AND COALESCE(retry_count, 0) < 5
    ORDER BY created_at ASC
    LIMIT p_limit
    FOR UPDATE SKIP LOCKED
  )
  RETURNING *;
END;
$$;

-- 5. SAFE DEVICE TOKEN DEACTIVATION RPC (Solves signout RLS race condition)
CREATE OR REPLACE FUNCTION public.careflow_deactivate_device_token(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_token IS NULL OR trim(p_token) = '' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Token cannot be empty');
  END IF;

  IF auth.uid() IS NOT NULL THEN
    UPDATE public.careflow_device_tokens
    SET is_active = false,
        last_seen_at = now()
    WHERE user_id = auth.uid() AND fcm_token = p_token;
  ELSE
    UPDATE public.careflow_device_tokens
    SET is_active = false,
        last_seen_at = now()
    WHERE fcm_token = p_token;
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 6. UPDATE DOSE CLAIMING TO GENERATE PRIVACY-SAFE FCM OUTBOX EVENTS
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
    -- Transition status to unconfirmed
    UPDATE public.careflow_medication_adherence
    SET status = 'unconfirmed',
        reminder_sent_at = now(),
        caregiver_escalated_at = now(),
        escalation_status = 'escalated',
        updated_at = now()
    WHERE id = v_dose.id;

    -- 1. Create Patient In-App Reminder Event
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
      fcm_status,
      created_at
    ) VALUES (
      v_dose.patient_id,
      'Time for your medicine',
      'Your scheduled dose of ' || v_dose.medicine_name || ' is due. Please confirm your dose.',
      'medication_reminder',
      v_dose.id,
      'dose_confirmation',
      false,
      'skipped', -- FCM is dispatched via dedicated alert events table below
      now()
    );

    -- 2. Create Patient FCM Push Event (PRIVACY-SAFE: Excludes medication names from lock screen)
    IF EXISTS (
      SELECT 1 FROM public.careflow_device_tokens 
      WHERE user_id = v_dose.patient_id AND is_active = true
    ) THEN
      INSERT INTO public.careflow_medication_alert_events (
        dose_id,
        event_type,
        recipient_type,
        recipient_id,
        delivery_channel,
        payload,
        status,
        created_at
      ) VALUES (
        v_dose.id,
        'patient_reminder',
        'patient',
        v_dose.patient_id::TEXT,
        'fcm',
        jsonb_build_object(
          'title', 'CareFlow Reminder',
          'body', 'You have a scheduled dose due. Tap to confirm in CareFlow.',
          'dose_id', v_dose.id,
          'type', 'medication_reminder',
          'scheduled_time', v_dose.scheduled_time
        ),
        'created',
        now()
      ) ON CONFLICT (dose_id, event_type, recipient_type, recipient_id, delivery_channel) DO NOTHING;
    END IF;

    -- 3. ZERO GRACE PERIOD: Caregiver Escalation
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
      -- In-app notification for family member
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
          'body', 'A scheduled dose was not confirmed on schedule.',
          'dose_id', v_dose.id,
          'patient_id', v_dose.patient_id,
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
        fcm_status,
        created_at
      ) VALUES (
        v_family.family_user_id,
        'CareFlow — Medicine dose not confirmed',
        'A scheduled medication dose was not confirmed on schedule. Tap to review.',
        'caregiver_alert',
        v_dose.id,
        'escalation_review',
        false,
        'skipped',
        now()
      );

      -- FCM Push notification for family caregiver if active token exists (PRIVACY-SAFE)
      IF EXISTS (
        SELECT 1 FROM public.careflow_device_tokens 
        WHERE user_id = v_family.family_user_id AND is_active = true
      ) THEN
        INSERT INTO public.careflow_medication_alert_events (
          dose_id,
          event_type,
          recipient_type,
          recipient_id,
          delivery_channel,
          payload,
          status,
          created_at
        ) VALUES (
          v_dose.id,
          'caregiver_escalation',
          'family',
          v_family.family_user_id::TEXT,
          'fcm',
          jsonb_build_object(
            'title', 'CareFlow Caregiver Alert',
            'body', 'A scheduled dose was not confirmed. Tap to review in CareFlow.',
            'dose_id', v_dose.id,
            'patient_id', v_dose.patient_id,
            'type', 'caregiver_alert',
            'scheduled_time', v_dose.scheduled_time
          ),
          'created',
          now()
        ) ON CONFLICT (dose_id, event_type, recipient_type, recipient_id, delivery_channel) DO NOTHING;
      END IF;

      v_escalated_count := v_escalated_count + 1;
    END LOOP;

    -- B. Emergency contact alerts (SMS fallback)
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
          'body', 'A scheduled medication dose was not confirmed on schedule.'
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

-- 7. UPDATE DOSE CONFIRMATION TO STOP PENDING CAREGIVER ESCALATIONS
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

  -- Cancel any pending caregiver escalation events in outbox
  UPDATE public.careflow_medication_alert_events
  SET status = 'dose_resolved',
      failure_reason = 'Dose confirmed taken by patient before dispatch',
      updated_at = now()
  WHERE dose_id = p_dose_id
    AND event_type = 'caregiver_escalation'
    AND status IN ('created', 'attempted', 'processing');

  -- Create dose_resolved event for tracking
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
    jsonb_build_object(
      'title', 'Dose Confirmed',
      'body', 'You confirmed your scheduled dose as taken.',
      'dose_id', p_dose_id,
      'taken_at', now()
    ),
    'delivered',
    now()
  ) ON CONFLICT (dose_id, event_type, recipient_type, recipient_id, delivery_channel) DO NOTHING;

  RETURN jsonb_build_object(
    'success', true, 
    'status', 'taken', 
    'dose_id', p_dose_id, 
    'taken_at', now()
  );
END;
$$;

-- 8. APPOINTMENT REMINDER SCANNER PROCEDURE (24h & Day-of)
CREATE OR REPLACE FUNCTION public.careflow_scan_appointment_reminders()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_appt RECORD;
  v_count INT := 0;
BEGIN
  FOR v_appt IN (
    SELECT a.*
    FROM public.careflow_appointments a
    WHERE a.status IN ('confirmed', 'booked')
      AND a.appointment_date IN (CURRENT_DATE, CURRENT_DATE + 1)
      AND NOT EXISTS (
        SELECT 1 FROM public.careflow_notifications n
        WHERE n.reference_id = a.id
          AND n.type = 'appointment_reminder'
          AND n.created_at::date = CURRENT_DATE
      )
  ) LOOP
    -- Insert reminder into careflow_notifications with fcm_status = 'pending'
    INSERT INTO public.careflow_notifications (
      user_id,
      title,
      body,
      type,
      reference_id,
      is_read,
      fcm_status,
      created_at
    ) VALUES (
      v_appt.patient_id,
      CASE 
        WHEN v_appt.appointment_date = CURRENT_DATE THEN 'Appointment Today'
        ELSE 'Upcoming Appointment Tomorrow'
      END,
      'You have an appointment scheduled. Tap to view details in CareFlow.',
      'appointment_reminder',
      v_appt.id,
      false,
      'pending',
      now()
    );

    v_count := v_count + 1;
  END LOOP;

  RETURN jsonb_build_object('success', true, 'reminders_created', v_count);
END;
$$;

-- 9. SECURE VAULT-BACKED SCHEDULER DISPATCH FUNCTION
CREATE OR REPLACE FUNCTION public.careflow_cron_dispatch_scheduler()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, vault
AS $$
DECLARE
  v_secret text;
  v_url text;
BEGIN
  BEGIN
    SELECT decrypted_secret INTO v_secret FROM vault.decrypted_secrets WHERE name = 'careflow_cron_secret' LIMIT 1;
    SELECT decrypted_secret INTO v_url FROM vault.decrypted_secrets WHERE name = 'careflow_project_url' LIMIT 1;

    IF v_secret IS NOT NULL AND v_url IS NOT NULL THEN
      PERFORM net.http_post(
        url := v_url || '/functions/v1/medication-scheduler',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || v_secret
        ),
        body := '{"action": "scheduler_run"}'::jsonb
      );
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- Prevent cron job failure on network timeout
    NULL;
  END;
END;
$$;

-- 10. SAFE IDEMPOTENT CRON SCHEDULE REGISTRATION
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    BEGIN
      PERFORM cron.unschedule('careflow_medication_scheduler');
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;

    PERFORM cron.schedule(
      'careflow_medication_scheduler',
      '* * * * *',
      'SELECT public.careflow_cron_dispatch_scheduler();'
    );
  END IF;
END $$;

-- 11. FUNCTION PRIVILEGES & SECURITY HARDENING
REVOKE EXECUTE ON FUNCTION public.careflow_cron_dispatch_scheduler() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.careflow_claim_pending_alert_events(INT) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.careflow_claim_pending_notifications(INT) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.careflow_claim_and_process_due_doses(INT) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.careflow_scan_appointment_reminders() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.careflow_claim_pending_alert_events(INT) TO service_role;
GRANT EXECUTE ON FUNCTION public.careflow_claim_pending_notifications(INT) TO service_role;
GRANT EXECUTE ON FUNCTION public.careflow_claim_and_process_due_doses(INT) TO service_role;
GRANT EXECUTE ON FUNCTION public.careflow_scan_appointment_reminders() TO service_role;
GRANT EXECUTE ON FUNCTION public.careflow_cron_dispatch_scheduler() TO service_role, postgres;
GRANT EXECUTE ON FUNCTION public.careflow_confirm_dose_taken(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.careflow_deactivate_device_token(TEXT) TO authenticated, anon;
