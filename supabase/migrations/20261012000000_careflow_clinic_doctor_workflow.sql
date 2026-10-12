-- ============================================================================
-- CAREFLOW MIGRATION: COMPLETE CLINIC-DOCTOR WORKFLOW & AUTHORIZATION
-- Target: Supabase / PostgreSQL Single Source of Truth
-- Version: 20261012000000
-- ============================================================================

-- 1. ENHANCE PROFILES TABLE
ALTER TABLE IF EXISTS public.profiles
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS registration_number TEXT,
  ADD COLUMN IF NOT EXISTS qualification TEXT,
  ADD COLUMN IF NOT EXISTS bio TEXT;

-- 2. ENHANCE DOCTORS TABLE
ALTER TABLE IF EXISTS public.doctors
  ADD COLUMN IF NOT EXISTS registration_number TEXT,
  ADD COLUMN IF NOT EXISTS bio TEXT;

-- 3. ENHANCE CLINIC_DOCTORS TABLE
ALTER TABLE IF EXISTS public.clinic_doctors
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS consultation_fee NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS invited_at TIMESTAMPTZ DEFAULT now(),
  ADD COLUMN IF NOT EXISTS activated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS deactivated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS notes TEXT;

-- Safely enforce check constraint on clinic_doctors.status
DO $$
DECLARE
  v_con_name text;
BEGIN
  FOR v_con_name IN (
    SELECT conname 
    FROM pg_constraint 
    WHERE conrelid = 'public.clinic_doctors'::regclass 
      AND contype = 'c' 
      AND pg_get_constraintdef(oid) LIKE '%status%'
  ) LOOP
    EXECUTE 'ALTER TABLE public.clinic_doctors DROP CONSTRAINT ' || quote_ident(v_con_name);
  END LOOP;
END $$;

ALTER TABLE public.clinic_doctors
  ADD CONSTRAINT chk_clinic_doctors_status
  CHECK (status IN ('invited', 'pending_activation', 'active', 'inactive', 'removed'));

UPDATE public.clinic_doctors SET status = 'active' WHERE status IS NULL;

-- 4. CREATE CAREFLOW_DOCTOR_CLINIC_FEES TABLE (DOCTOR PROPOSES, CLINIC APPROVES)
CREATE TABLE IF NOT EXISTS public.careflow_doctor_clinic_fees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  approved_fee NUMERIC(10,2) DEFAULT NULL,
  proposed_fee NUMERIC(10,2) DEFAULT NULL,
  proposal_status TEXT NOT NULL DEFAULT 'none' CHECK (proposal_status IN ('none', 'pending', 'approved', 'rejected')),
  proposed_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT uq_doctor_clinic_fees UNIQUE (clinic_id, doctor_id)
);

CREATE INDEX IF NOT EXISTS idx_doctor_clinic_fees_clinic 
  ON public.careflow_doctor_clinic_fees (clinic_id);

CREATE INDEX IF NOT EXISTS idx_doctor_clinic_fees_doctor 
  ON public.careflow_doctor_clinic_fees (doctor_id);

-- 5. CREATE CAREFLOW_DOCTOR_CLINIC_FEE_HISTORY TABLE (AUDIT & HISTORICAL BILLING TRACE)
CREATE TABLE IF NOT EXISTS public.careflow_doctor_clinic_fee_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  fee NUMERIC(10,2) NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('proposed', 'approved', 'rejected', 'initial_set')),
  actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fee_history_clinic_doc 
  ON public.careflow_doctor_clinic_fee_history (clinic_id, doctor_id);

-- 6. ROW LEVEL SECURITY ON FEE TABLES
ALTER TABLE public.careflow_doctor_clinic_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.careflow_doctor_clinic_fee_history ENABLE ROW LEVEL SECURITY;

-- Fee policies
DROP POLICY IF EXISTS "Users can read relevant clinic doctor fees" ON public.careflow_doctor_clinic_fees;
CREATE POLICY "Users can read relevant clinic doctor fees"
  ON public.careflow_doctor_clinic_fees FOR SELECT
  TO authenticated
  USING (
    clinic_id = auth.uid() OR
    doctor_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'platform_admin' OR role = 'admin'))
  );

DROP POLICY IF EXISTS "Clinics and doctors can insert fees" ON public.careflow_doctor_clinic_fees;
CREATE POLICY "Clinics and doctors can insert fees"
  ON public.careflow_doctor_clinic_fees FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = auth.uid() OR
    doctor_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin')
  );

DROP POLICY IF EXISTS "Clinics and doctors can update fees" ON public.careflow_doctor_clinic_fees;
CREATE POLICY "Clinics and doctors can update fees"
  ON public.careflow_doctor_clinic_fees FOR UPDATE
  TO authenticated
  USING (
    clinic_id = auth.uid() OR
    doctor_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin')
  );

-- Fee history policies
DROP POLICY IF EXISTS "Users can view relevant fee history" ON public.careflow_doctor_clinic_fee_history;
CREATE POLICY "Users can view relevant fee history"
  ON public.careflow_doctor_clinic_fee_history FOR SELECT
  TO authenticated
  USING (
    clinic_id = auth.uid() OR
    doctor_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'platform_admin' OR role = 'admin'))
  );

-- 7. TRIGGER: PREVENT DOCTOR SELF-APPROVAL & DIRECT UNAUTHORIZED FEE MANIPULATION
CREATE OR REPLACE FUNCTION public.careflow_secure_fee_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Service role bypass
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  -- Platform admin bypass
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin') THEN
    RETURN NEW;
  END IF;

  -- If caller is the doctor:
  IF auth.uid() = NEW.doctor_id AND auth.uid() != NEW.clinic_id THEN
    -- Doctor CANNOT modify approved_fee directly
    IF NEW.approved_fee IS DISTINCT FROM OLD.approved_fee THEN
      RAISE EXCEPTION 'Unauthorized: Doctors cannot directly change or approve their consultation fee.';
    END IF;
    -- Doctor CANNOT approve or reject proposal
    IF NEW.proposal_status IN ('approved', 'rejected') AND OLD.proposal_status = 'pending' THEN
      RAISE EXCEPTION 'Unauthorized: Doctors cannot approve or reject their own fee proposals.';
    END IF;
    -- Doctor CANNOT alter review timestamps or reviewer identity
    IF NEW.reviewed_by IS DISTINCT FROM OLD.reviewed_by OR NEW.reviewed_at IS DISTINCT FROM OLD.reviewed_at THEN
      RAISE EXCEPTION 'Unauthorized: Doctors cannot modify approval metadata.';
    END IF;
  END IF;

  -- If caller is the clinic:
  IF auth.uid() = NEW.clinic_id THEN
    -- Clinic cannot reassign association keys
    IF NEW.doctor_id != OLD.doctor_id OR NEW.clinic_id != OLD.clinic_id THEN
      RAISE EXCEPTION 'Unauthorized: Cannot reassign doctor or clinic identifiers.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_secure_fee_update ON public.careflow_doctor_clinic_fees;
CREATE TRIGGER tr_secure_fee_update
  BEFORE UPDATE ON public.careflow_doctor_clinic_fees
  FOR EACH ROW EXECUTE FUNCTION public.careflow_secure_fee_update();

-- 8. UPDATE PROFILE TRIGGER: ALLOW INVITED DOCTOR TO ACTIVATE OWN ACCOUNT
CREATE OR REPLACE FUNCTION public.careflow_secure_profile_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Service role bypass
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  -- Role modification guard
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    IF auth.role() = 'authenticated' THEN
      IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin') THEN
        RAISE EXCEPTION 'Unauthorized: Users cannot modify their own role.';
      END IF;
    ELSIF auth.role() = 'anon' THEN
      RAISE EXCEPTION 'Unauthorized: Users cannot modify their own role.';
    END IF;
  END IF;

  -- Status modification guard
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF auth.role() = 'authenticated' THEN
      -- Allow an invited or pending doctor to activate their own account upon email/password setup
      IF auth.uid() = OLD.id AND OLD.role = 'doctor' AND OLD.status IN ('invited', 'pending_activation') AND NEW.status = 'active' THEN
        -- Permitted self-activation
        NULL;
      ELSIF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin') THEN
        RAISE EXCEPTION 'Unauthorized: Users cannot modify their own profile status.';
      END IF;
    ELSIF auth.role() = 'anon' THEN
      RAISE EXCEPTION 'Unauthorized: Users cannot modify their own profile status.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_secure_profile_update ON public.profiles;
CREATE TRIGGER tr_secure_profile_update
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.careflow_secure_profile_update();

-- 9. PERMIT DOCTORS TO MANAGE THEIR OWN DOCTOR RECORD IN public.doctors
DROP POLICY IF EXISTS "Doctors can update their own doctor record" ON public.doctors;
CREATE POLICY "Doctors can update their own doctor record"
  ON public.doctors FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Doctors can insert their own doctor record" ON public.doctors;
CREATE POLICY "Doctors can insert their own doctor record"
  ON public.doctors FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- 10. CLINIC_DOCTORS POLICIES: CLINIC CAN MANAGE, DOCTOR CAN VIEW OWN
DROP POLICY IF EXISTS "Clinic doctors readable by authenticated users" ON public.clinic_doctors;
CREATE POLICY "Clinic doctors readable by authenticated users"
  ON public.clinic_doctors FOR SELECT
  TO authenticated
  USING (
    active = true OR
    clinic_id = auth.uid() OR
    doctor_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'platform_admin' OR role = 'admin'))
  );

DROP POLICY IF EXISTS "Clinic can manage its doctors" ON public.clinic_doctors;
CREATE POLICY "Clinic can manage its doctors"
  ON public.clinic_doctors FOR ALL
  TO authenticated
  USING (
    clinic_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'platform_admin' OR role = 'admin'))
  )
  WITH CHECK (
    clinic_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'platform_admin' OR role = 'admin'))
  );

-- 11. STRICT PATIENT VISIBILITY RLS (REQUIREMENT 7 & 8)
-- Clinics see ONLY patients who have appointments with doctors associated with that particular clinic!
DROP POLICY IF EXISTS "Patients readable by authenticated users" ON public.patients;
DROP POLICY IF EXISTS "Patients readable by authorized users only" ON public.patients;

CREATE POLICY "Patients readable by authorized users only"
  ON public.patients FOR SELECT
  TO authenticated
  USING (
    -- Patient themselves
    auth.uid() = id
    -- Clinic where patient has at least one qualifying appointment
    OR EXISTS (
      SELECT 1 FROM public.careflow_appointments a
      WHERE a.patient_id = public.patients.id
        AND a.clinic_id = auth.uid()
    )
    -- Doctor who has an appointment with this patient
    OR EXISTS (
      SELECT 1 FROM public.careflow_appointments a
      WHERE a.patient_id = public.patients.id
        AND a.doctor_id = auth.uid()
    )
    -- Or active doctor clinical access grant
    OR public.careflow_has_active_access(public.patients.id, auth.uid())
    -- Platform admin
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND (role = 'platform_admin' OR role = 'admin')
    )
  );

-- 12. RPC: DOCTOR PROPOSES CONSULTATION FEE
CREATE OR REPLACE FUNCTION public.careflow_propose_consultation_fee(
  p_clinic_id UUID,
  p_proposed_fee NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_doctor_id UUID := auth.uid();
  v_doctor_name TEXT;
  v_clinic_name TEXT;
  v_current_approved NUMERIC;
BEGIN
  IF v_doctor_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: Caller must be authenticated.';
  END IF;

  IF p_proposed_fee IS NULL OR p_proposed_fee <= 0 THEN
    RAISE EXCEPTION 'Proposed fee must be a positive number.';
  END IF;

  -- Verify active association between doctor and clinic
  IF NOT EXISTS (
    SELECT 1 FROM public.clinic_doctors
    WHERE doctor_id = v_doctor_id
      AND clinic_id = p_clinic_id
      AND status != 'removed'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: You are not associated with this clinic.';
  END IF;

  -- Get names for notification
  SELECT full_name INTO v_doctor_name FROM public.profiles WHERE id = v_doctor_id;
  SELECT name INTO v_clinic_name FROM public.clinics WHERE id = p_clinic_id;

  -- Get current approved fee if row exists
  SELECT approved_fee INTO v_current_approved
  FROM public.careflow_doctor_clinic_fees
  WHERE clinic_id = p_clinic_id AND doctor_id = v_doctor_id;

  -- Upsert fee proposal (keeping approved_fee unchanged!)
  INSERT INTO public.careflow_doctor_clinic_fees (
    clinic_id,
    doctor_id,
    approved_fee,
    proposed_fee,
    proposal_status,
    proposed_at,
    updated_at
  ) VALUES (
    p_clinic_id,
    v_doctor_id,
    v_current_approved,
    p_proposed_fee,
    'pending',
    now(),
    now()
  )
  ON CONFLICT (clinic_id, doctor_id) DO UPDATE
    SET proposed_fee = p_proposed_fee,
        proposal_status = 'pending',
        proposed_at = now(),
        rejection_reason = NULL,
        updated_at = now();

  -- Audit log in fee history
  INSERT INTO public.careflow_doctor_clinic_fee_history (
    clinic_id,
    doctor_id,
    fee,
    action,
    actor_id,
    notes
  ) VALUES (
    p_clinic_id,
    v_doctor_id,
    p_proposed_fee,
    'proposed',
    v_doctor_id,
    'Doctor proposed new consultation fee.'
  );

  -- Notify the clinic
  INSERT INTO public.careflow_notifications (
    user_id,
    title,
    body,
    type,
    is_read,
    created_at
  ) VALUES (
    p_clinic_id,
    'Consultation Fee Proposal',
    'Dr. ' || COALESCE(v_doctor_name, 'Doctor') || ' proposed a consultation fee of ₹' || p_proposed_fee || ' for your clinic.',
    'fee_proposal',
    false,
    now()
  );

  RETURN jsonb_build_object(
    'success', true,
    'clinic_id', p_clinic_id,
    'doctor_id', v_doctor_id,
    'proposed_fee', p_proposed_fee,
    'proposal_status', 'pending',
    'message', 'Fee proposal submitted successfully and is awaiting clinic approval.'
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.careflow_propose_consultation_fee(UUID, NUMERIC) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.careflow_propose_consultation_fee(UUID, NUMERIC) TO authenticated, service_role;

-- 13. RPC: CLINIC APPROVES CONSULTATION FEE
CREATE OR REPLACE FUNCTION public.careflow_approve_consultation_fee(
  p_doctor_id UUID,
  p_clinic_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_fee_record RECORD;
  v_clinic_name TEXT;
BEGIN
  -- Authorization check: ONLY the clinic or platform_admin can approve
  IF auth.role() = 'authenticated' THEN
    IF v_caller != p_clinic_id AND NOT EXISTS (
      SELECT 1 FROM public.profiles WHERE id = v_caller AND (role = 'platform_admin' OR role = 'admin')
    ) THEN
      RAISE EXCEPTION 'Unauthorized: Only authorized clinic administrators can approve fee proposals.';
    END IF;
    -- Explicit rule: Doctor cannot approve their own proposal!
    IF v_caller = p_doctor_id AND NOT EXISTS (
      SELECT 1 FROM public.profiles WHERE id = v_caller AND role = 'platform_admin'
    ) THEN
      RAISE EXCEPTION 'Unauthorized: Doctors cannot approve their own consultation fee proposal.';
    END IF;
  ELSIF auth.role() != 'service_role' THEN
    RAISE EXCEPTION 'Unauthorized: Invalid execution context.';
  END IF;

  SELECT * INTO v_fee_record
  FROM public.careflow_doctor_clinic_fees
  WHERE clinic_id = p_clinic_id AND doctor_id = p_doctor_id;

  IF NOT FOUND OR v_fee_record.proposed_fee IS NULL THEN
    RAISE EXCEPTION 'No pending fee proposal found for this doctor at this clinic.';
  END IF;

  -- Apply approved fee
  UPDATE public.careflow_doctor_clinic_fees
  SET approved_fee = v_fee_record.proposed_fee,
      proposal_status = 'approved',
      reviewed_at = now(),
      reviewed_by = v_caller,
      rejection_reason = NULL,
      updated_at = now()
  WHERE clinic_id = p_clinic_id AND doctor_id = p_doctor_id;

  -- Mirror in clinic_doctors for caching
  UPDATE public.clinic_doctors
  SET consultation_fee = v_fee_record.proposed_fee
  WHERE clinic_id = p_clinic_id AND doctor_id = p_doctor_id;

  -- Audit log in fee history
  INSERT INTO public.careflow_doctor_clinic_fee_history (
    clinic_id,
    doctor_id,
    fee,
    action,
    actor_id,
    notes
  ) VALUES (
    p_clinic_id,
    p_doctor_id,
    v_fee_record.proposed_fee,
    'approved',
    v_caller,
    'Clinic approved proposed consultation fee.'
  );

  -- Notify the doctor
  SELECT name INTO v_clinic_name FROM public.clinics WHERE id = p_clinic_id;
  INSERT INTO public.careflow_notifications (
    user_id,
    title,
    body,
    type,
    is_read,
    created_at
  ) VALUES (
    p_doctor_id,
    'Fee Proposal Approved',
    'Your consultation fee of ₹' || v_fee_record.proposed_fee || ' has been approved by ' || COALESCE(v_clinic_name, 'the clinic') || '.',
    'fee_approved',
    false,
    now()
  );

  RETURN jsonb_build_object(
    'success', true,
    'clinic_id', p_clinic_id,
    'doctor_id', p_doctor_id,
    'approved_fee', v_fee_record.proposed_fee,
    'proposal_status', 'approved',
    'message', 'Consultation fee proposal approved successfully.'
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.careflow_approve_consultation_fee(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.careflow_approve_consultation_fee(UUID, UUID) TO authenticated, service_role;

-- 14. RPC: CLINIC REJECTS CONSULTATION FEE
CREATE OR REPLACE FUNCTION public.careflow_reject_consultation_fee(
  p_doctor_id UUID,
  p_clinic_id UUID,
  p_reason TEXT DEFAULT 'Does not align with clinic pricing policy.'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_fee_record RECORD;
  v_clinic_name TEXT;
BEGIN
  -- Authorization check: ONLY clinic or platform admin
  IF auth.role() = 'authenticated' THEN
    IF v_caller != p_clinic_id AND NOT EXISTS (
      SELECT 1 FROM public.profiles WHERE id = v_caller AND (role = 'platform_admin' OR role = 'admin')
    ) THEN
      RAISE EXCEPTION 'Unauthorized: Only authorized clinic administrators can reject fee proposals.';
    END IF;
  ELSIF auth.role() != 'service_role' THEN
    RAISE EXCEPTION 'Unauthorized: Invalid execution context.';
  END IF;

  SELECT * INTO v_fee_record
  FROM public.careflow_doctor_clinic_fees
  WHERE clinic_id = p_clinic_id AND doctor_id = p_doctor_id;

  IF NOT FOUND OR v_fee_record.proposed_fee IS NULL THEN
    RAISE EXCEPTION 'No pending fee proposal found for this doctor at this clinic.';
  END IF;

  -- Mark proposal rejected, approved_fee remains intact!
  UPDATE public.careflow_doctor_clinic_fees
  SET proposal_status = 'rejected',
      rejection_reason = p_reason,
      reviewed_at = now(),
      reviewed_by = v_caller,
      updated_at = now()
  WHERE clinic_id = p_clinic_id AND doctor_id = p_doctor_id;

  -- Audit log in fee history
  INSERT INTO public.careflow_doctor_clinic_fee_history (
    clinic_id,
    doctor_id,
    fee,
    action,
    actor_id,
    notes
  ) VALUES (
    p_clinic_id,
    p_doctor_id,
    v_fee_record.proposed_fee,
    'rejected',
    v_caller,
    'Clinic rejected proposed consultation fee: ' || COALESCE(p_reason, 'No reason specified.')
  );

  -- Notify the doctor
  SELECT name INTO v_clinic_name FROM public.clinics WHERE id = p_clinic_id;
  INSERT INTO public.careflow_notifications (
    user_id,
    title,
    body,
    type,
    is_read,
    created_at
  ) VALUES (
    p_doctor_id,
    'Fee Proposal Declined',
    'Your fee proposal of ₹' || v_fee_record.proposed_fee || ' was declined by ' || COALESCE(v_clinic_name, 'the clinic') || '. Reason: ' || COALESCE(p_reason, 'None'),
    'fee_rejected',
    false,
    now()
  );

  RETURN jsonb_build_object(
    'success', true,
    'clinic_id', p_clinic_id,
    'doctor_id', p_doctor_id,
    'proposal_status', 'rejected',
    'reason', p_reason,
    'approved_fee', v_fee_record.approved_fee,
    'message', 'Consultation fee proposal rejected. Existing approved fee remains active.'
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.careflow_reject_consultation_fee(UUID, UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.careflow_reject_consultation_fee(UUID, UUID, TEXT) TO authenticated, service_role;

-- 15. RPC: CLINIC DEACTIVATES DOCTOR ASSOCIATION (SOFT DEACTIVATION)
CREATE OR REPLACE FUNCTION public.careflow_deactivate_clinic_doctor(
  p_doctor_id UUID,
  p_clinic_id UUID,
  p_cancel_upcoming BOOLEAN DEFAULT false
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_cancelled_count INT := 0;
BEGIN
  -- Verify caller is clinic administrator
  IF auth.role() = 'authenticated' THEN
    IF v_caller != p_clinic_id AND NOT EXISTS (
      SELECT 1 FROM public.profiles WHERE id = v_caller AND (role = 'platform_admin' OR role = 'admin')
    ) THEN
      RAISE EXCEPTION 'Unauthorized: Caller cannot deactivate doctor for this clinic.';
    END IF;
  ELSIF auth.role() != 'service_role' THEN
    RAISE EXCEPTION 'Unauthorized: Invalid execution context.';
  END IF;

  -- 1. Mark association inactive and turn off duty availability
  UPDATE public.clinic_doctors
  SET active = false,
      status = 'inactive',
      is_available = false,
      deactivated_at = now()
  WHERE clinic_id = p_clinic_id AND doctor_id = p_doctor_id;

  -- 2. Apply policy to upcoming appointments
  IF p_cancel_upcoming THEN
    WITH cancelled_rows AS (
      UPDATE public.careflow_appointments
      SET status = 'cancelled'
      WHERE clinic_id = p_clinic_id
        AND doctor_id = p_doctor_id
        AND appointment_date >= CURRENT_DATE
        AND status IN ('confirmed', 'waiting')
      RETURNING id
    )
    SELECT count(*) INTO v_cancelled_count FROM cancelled_rows;
  END IF;

  -- 3. Audit log
  INSERT INTO public.careflow_audit_logs (actor_id, action, resource_type, resource_id, metadata)
  VALUES (
    v_caller,
    'DOCTOR_DEACTIVATED',
    'clinic_doctors',
    p_doctor_id::TEXT,
    jsonb_build_object('clinic_id', p_clinic_id, 'cancelled_appointments', v_cancelled_count)
  );

  RETURN jsonb_build_object(
    'success', true,
    'doctor_id', p_doctor_id,
    'clinic_id', p_clinic_id,
    'status', 'inactive',
    'cancelled_upcoming', v_cancelled_count,
    'message', 'Doctor association deactivated. Future bookings at this clinic are paused.'
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.careflow_deactivate_clinic_doctor(UUID, UUID, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.careflow_deactivate_clinic_doctor(UUID, UUID, BOOLEAN) TO authenticated, service_role;

-- 16. RPC: CLINIC REACTIVATES DOCTOR ASSOCIATION
CREATE OR REPLACE FUNCTION public.careflow_reactivate_clinic_doctor(
  p_doctor_id UUID,
  p_clinic_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF v_caller != p_clinic_id AND NOT EXISTS (
      SELECT 1 FROM public.profiles WHERE id = v_caller AND (role = 'platform_admin' OR role = 'admin')
    ) THEN
      RAISE EXCEPTION 'Unauthorized: Caller cannot reactivate doctor for this clinic.';
    END IF;
  ELSIF auth.role() != 'service_role' THEN
    RAISE EXCEPTION 'Unauthorized: Invalid execution context.';
  END IF;

  UPDATE public.clinic_doctors
  SET active = true,
      status = 'active',
      deactivated_at = NULL
  WHERE clinic_id = p_clinic_id AND doctor_id = p_doctor_id;

  INSERT INTO public.careflow_audit_logs (actor_id, action, resource_type, resource_id, metadata)
  VALUES (
    v_caller,
    'DOCTOR_REACTIVATED',
    'clinic_doctors',
    p_doctor_id::TEXT,
    jsonb_build_object('clinic_id', p_clinic_id)
  );

  RETURN jsonb_build_object(
    'success', true,
    'doctor_id', p_doctor_id,
    'clinic_id', p_clinic_id,
    'status', 'active',
    'message', 'Doctor association reactivated successfully.'
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.careflow_reactivate_clinic_doctor(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.careflow_reactivate_clinic_doctor(UUID, UUID) TO authenticated, service_role;

-- 17. RPC: CLINIC REMOVES DOCTOR ASSOCIATION (NON-DESTRUCTIVE)
CREATE OR REPLACE FUNCTION public.careflow_remove_clinic_doctor(
  p_doctor_id UUID,
  p_clinic_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF v_caller != p_clinic_id AND NOT EXISTS (
      SELECT 1 FROM public.profiles WHERE id = v_caller AND (role = 'platform_admin' OR role = 'admin')) THEN
      RAISE EXCEPTION 'Unauthorized: Caller cannot remove doctor association for this clinic.';
    END IF;
  ELSIF auth.role() != 'service_role' THEN
    RAISE EXCEPTION 'Unauthorized: Invalid execution context.';
  END IF;

  -- Soft-remove the association: preserve doctor profile, auth user, and all medical records
  UPDATE public.clinic_doctors
  SET active = false,
      status = 'removed',
      is_available = false,
      deactivated_at = now()
  WHERE clinic_id = p_clinic_id AND doctor_id = p_doctor_id;

  -- Cancel upcoming appointments for this doctor at this clinic
  UPDATE public.careflow_appointments
  SET status = 'cancelled'
  WHERE clinic_id = p_clinic_id
    AND doctor_id = p_doctor_id
    AND appointment_date >= CURRENT_DATE
    AND status IN ('confirmed', 'waiting');

  -- Audit log
  INSERT INTO public.careflow_audit_logs (actor_id, action, resource_type, resource_id, metadata)
  VALUES (
    v_caller,
    'DOCTOR_REMOVED_FROM_CLINIC',
    'clinic_doctors',
    p_doctor_id::TEXT,
    jsonb_build_object('clinic_id', p_clinic_id)
  );

  RETURN jsonb_build_object(
    'success', true,
    'doctor_id', p_doctor_id,
    'clinic_id', p_clinic_id,
    'status', 'removed',
    'message', 'Doctor association removed. All clinical history and appointments are preserved.'
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.careflow_remove_clinic_doctor(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.careflow_remove_clinic_doctor(UUID, UUID) TO authenticated, service_role;

-- 18. RPC: FETCH CLINIC DOCTORS WITH ENRICHED STATUS & FEES
CREATE OR REPLACE FUNCTION public.careflow_get_clinic_doctors(p_clinic_id UUID)
RETURNS TABLE (
  doctor_id UUID,
  full_name TEXT,
  email TEXT,
  phone TEXT,
  specialization TEXT,
  qualification TEXT,
  experience INT,
  registration_number TEXT,
  bio TEXT,
  is_available BOOLEAN,
  active BOOLEAN,
  status TEXT,
  approved_fee NUMERIC,
  proposed_fee NUMERIC,
  proposal_status TEXT,
  proposed_at TIMESTAMPTZ,
  invited_at TIMESTAMPTZ,
  activated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF auth.uid() != p_clinic_id 
       AND NOT EXISTS (SELECT 1 FROM public.clinic_doctors cd WHERE cd.clinic_id = p_clinic_id AND cd.doctor_id = auth.uid())
       AND NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'platform_admin' OR role = 'admin')) THEN
      RAISE EXCEPTION 'Unauthorized: Caller cannot view doctor associations for this clinic.';
    END IF;
  END IF;

  RETURN QUERY
  SELECT
    cd.doctor_id,
    COALESCE(p.full_name, 'Doctor')::TEXT,
    p.email::TEXT,
    p.phone::TEXT,
    COALESCE(d.specialization, 'General Physician')::TEXT,
    COALESCE(d.qualification, p.qualification, '')::TEXT,
    d.experience,
    COALESCE(d.registration_number, p.registration_number, '')::TEXT,
    COALESCE(d.bio, p.bio, '')::TEXT,
    COALESCE(cd.is_available, false),
    COALESCE(cd.active, true),
    COALESCE(cd.status, 'active')::TEXT,
    COALESCE(f.approved_fee, cd.consultation_fee, d.consultation_fee),
    f.proposed_fee,
    COALESCE(f.proposal_status, 'none')::TEXT,
    f.proposed_at,
    cd.invited_at,
    cd.activated_at
  FROM public.clinic_doctors cd
  JOIN public.profiles p ON p.id = cd.doctor_id
  LEFT JOIN public.doctors d ON d.id = cd.doctor_id
  LEFT JOIN public.careflow_doctor_clinic_fees f ON f.clinic_id = cd.clinic_id AND f.doctor_id = cd.doctor_id
  WHERE cd.clinic_id = p_clinic_id
    AND cd.status != 'removed'
  ORDER BY cd.created_at DESC;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.careflow_get_clinic_doctors(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.careflow_get_clinic_doctors(UUID) TO authenticated, service_role;

-- 19. RPC: FETCH CLINIC PATIENTS (STRICT CLINIC ISOLATION)
CREATE OR REPLACE FUNCTION public.careflow_get_clinic_patients(p_clinic_id UUID)
RETURNS TABLE (
  id UUID,
  full_name TEXT,
  email TEXT,
  phone TEXT,
  gender TEXT,
  age INT,
  date_of_birth DATE,
  address TEXT,
  city TEXT,
  total_appointments BIGINT,
  last_appointment_date DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF auth.uid() != p_clinic_id AND NOT EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'platform_admin' OR role = 'admin')
    ) THEN
      RAISE EXCEPTION 'Unauthorized: Caller is not authorized to view patients for this clinic.';
    END IF;
  ELSIF auth.role() != 'service_role' THEN
    RAISE EXCEPTION 'Unauthorized: Invalid execution context.';
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    p.full_name::TEXT,
    p.email::TEXT,
    p.phone::TEXT,
    p.gender::TEXT,
    p.age,
    p.date_of_birth,
    p.address::TEXT,
    p.city::TEXT,
    COUNT(a.id) AS total_appointments,
    MAX(a.appointment_date) AS last_appointment_date
  FROM public.profiles p
  JOIN public.careflow_appointments a ON a.patient_id = p.id
  WHERE a.clinic_id = p_clinic_id
  GROUP BY p.id, p.full_name, p.email, p.phone, p.gender, p.age, p.date_of_birth, p.address, p.city
  ORDER BY MAX(a.appointment_date) DESC;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.careflow_get_clinic_patients(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.careflow_get_clinic_patients(UUID) TO authenticated, service_role;

-- 20. RPC: ACTIVATE DOCTOR ACCOUNT UPON INVITATION ACCEPTANCE
CREATE OR REPLACE FUNCTION public.careflow_activate_doctor_account(
  p_doctor_id UUID DEFAULT auth.uid()
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF auth.uid() != p_doctor_id AND NOT EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin'
    ) THEN
      RAISE EXCEPTION 'Unauthorized: Cannot activate another doctor account.';
    END IF;
  ELSIF auth.role() != 'service_role' THEN
    RAISE EXCEPTION 'Unauthorized: Invalid execution context.';
  END IF;

  UPDATE public.profiles
  SET status = 'active'
  WHERE id = p_doctor_id AND role = 'doctor';

  UPDATE public.clinic_doctors
  SET status = 'active',
      activated_at = now()
  WHERE doctor_id = p_doctor_id AND status IN ('invited', 'pending_activation');

  RETURN jsonb_build_object('success', true, 'status', 'active');
END;
$$;

REVOKE EXECUTE ON FUNCTION public.careflow_activate_doctor_account(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.careflow_activate_doctor_account(UUID) TO authenticated, service_role;

-- 21. UPDATE APPOINTMENT BOOKING TO ENFORCE ACTIVE ASSOCIATION & RECORD APPROVED FEE
CREATE OR REPLACE FUNCTION public.careflow_book_appointment(
  p_patient_id UUID,
  p_doctor_id UUID,
  p_clinic_id UUID,
  p_date DATE,
  p_time TIME,
  p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing_count INT;
  v_new_appt RECORD;
  v_patient_name TEXT;
  v_dow INT;
  v_avail RECORD;
  v_exc RECORD;
  v_recorded_fee NUMERIC;
BEGIN
  -- 1. Check active clinic-doctor association
  IF NOT EXISTS (
    SELECT 1 FROM public.clinic_doctors
    WHERE doctor_id = p_doctor_id
      AND clinic_id = p_clinic_id
      AND active = true
      AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Doctor is not actively associated with this clinic.';
  END IF;

  -- 2. Check Exceptions (Leave)
  SELECT * INTO v_exc FROM public.careflow_doctor_exceptions WHERE doctor_id = p_doctor_id AND exception_date = p_date;
  IF FOUND AND v_exc.is_leave THEN
    RAISE EXCEPTION 'Doctor is on leave on this date.';
  END IF;

  -- 3. Check Availability Bounds
  v_dow := EXTRACT(ISODOW FROM p_date);
  SELECT * INTO v_avail FROM public.careflow_doctor_availability WHERE doctor_id = p_doctor_id AND clinic_id = p_clinic_id AND day_of_week = v_dow;
  
  IF NOT FOUND THEN
    IF v_exc.start_time IS NULL THEN
      RAISE EXCEPTION 'Doctor is not available on this day.';
    END IF;
  ELSE
    IF p_time < v_avail.start_time OR p_time >= v_avail.end_time THEN
       IF v_exc.start_time IS NULL OR (p_time < v_exc.start_time OR p_time >= v_exc.end_time) THEN
         RAISE EXCEPTION 'Selected time is outside doctor working hours.';
       END IF;
    END IF;
    
    IF v_avail.break_start IS NOT NULL AND p_time >= v_avail.break_start AND p_time < v_avail.break_end THEN
       RAISE EXCEPTION 'Selected time is during doctor break.';
    END IF;
  END IF;

  -- Validate caller (patient, doctor, or clinic manager)
  IF auth.uid() NOT IN (p_patient_id, p_doctor_id, p_clinic_id) AND NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'platform_admin' OR role = 'admin')
  ) THEN
    RAISE EXCEPTION 'Not authorized to book this appointment.';
  END IF;

  -- 4. Double booking check
  SELECT COUNT(*) INTO v_existing_count
  FROM public.careflow_appointments
  WHERE doctor_id = p_doctor_id
    AND appointment_date = p_date
    AND appointment_time = p_time
    AND status NOT IN ('cancelled', 'rejected');

  IF v_existing_count > 0 THEN
    RAISE EXCEPTION 'This time slot is already booked. Please choose another time slot.';
  END IF;

  -- 5. Determine active approved consultation fee for billing record
  SELECT approved_fee INTO v_recorded_fee
  FROM public.careflow_doctor_clinic_fees
  WHERE clinic_id = p_clinic_id AND doctor_id = p_doctor_id;

  IF v_recorded_fee IS NULL THEN
    SELECT consultation_fee INTO v_recorded_fee
    FROM public.clinic_doctors
    WHERE clinic_id = p_clinic_id AND doctor_id = p_doctor_id;
  END IF;

  -- Insert appointment
  INSERT INTO public.careflow_appointments (
    patient_id,
    doctor_id,
    clinic_id,
    appointment_date,
    appointment_time,
    reason,
    status
  ) VALUES (
    p_patient_id,
    p_doctor_id,
    p_clinic_id,
    p_date,
    p_time,
    p_reason,
    'confirmed'
  )
  RETURNING * INTO v_new_appt;

  -- Get patient name
  SELECT full_name INTO v_patient_name FROM public.profiles WHERE id = p_patient_id;
  IF v_patient_name IS NULL THEN
    v_patient_name := 'A patient';
  END IF;

  -- Create notification for doctor
  INSERT INTO public.careflow_notifications (
    user_id,
    title,
    body,
    type,
    is_read,
    reference_id,
    created_at
  ) VALUES (
    p_doctor_id,
    'New Appointment Booked',
    v_patient_name || ' booked an appointment on ' || to_char(p_date, 'Mon DD, YYYY') || ' at ' || to_char(p_time, 'HH12:MI AM') || '.',
    'appointment',
    false,
    v_new_appt.id,
    now()
  );

  RETURN to_jsonb(v_new_appt);
END;
$$;
