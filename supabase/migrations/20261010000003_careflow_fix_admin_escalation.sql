-- ============================================================
-- CAREFLOW DATABASE MIGRATION: FIX ADMIN ESCALATION & SECURE RPCS
-- ============================================================

-- 1. Fix Profile Update Trigger
CREATE OR REPLACE FUNCTION public.careflow_secure_profile_update() RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    IF auth.role() = 'authenticated' THEN
      IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin') THEN RAISE EXCEPTION 'Unauthorized: Users cannot modify their own role.'; END IF;
    ELSIF auth.role() = 'anon' THEN RAISE EXCEPTION 'Unauthorized: Users cannot modify their own role.'; END IF;
  END IF;
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF auth.role() = 'authenticated' THEN
      IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin') THEN RAISE EXCEPTION 'Unauthorized: Users cannot modify their own profile status.'; END IF;
    ELSIF auth.role() = 'anon' THEN RAISE EXCEPTION 'Unauthorized: Users cannot modify their own profile status.'; END IF;
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS tr_secure_profile_update ON public.profiles;
CREATE TRIGGER tr_secure_profile_update BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.careflow_secure_profile_update();

-- 2. Fix Clinic Update Trigger
CREATE OR REPLACE FUNCTION public.careflow_secure_clinic_update() RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF auth.role() = 'authenticated' THEN
      IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin') THEN RAISE EXCEPTION 'Unauthorized: Only platform administrators can change clinic approval status.'; END IF;
    ELSIF auth.role() = 'anon' THEN RAISE EXCEPTION 'Unauthorized: Only platform administrators can change clinic approval status.'; END IF;
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS tr_secure_clinic_update ON public.clinics;
CREATE TRIGGER tr_secure_clinic_update BEFORE UPDATE ON public.clinics FOR EACH ROW EXECUTE FUNCTION public.careflow_secure_clinic_update();

-- 3. Secure Admin Approval RPCs
CREATE OR REPLACE FUNCTION public.careflow_admin_approve_clinic(p_clinic_id UUID) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin') THEN RAISE EXCEPTION 'Unauthorized: Only platform administrators can approve clinics.'; END IF;
  ELSIF auth.role() = 'service_role' THEN NULL; ELSE RAISE EXCEPTION 'Unauthorized: Invalid execution context.'; END IF;
  UPDATE public.clinics SET status = 'approved', approved_at = now(), rejection_reason = null WHERE id = p_clinic_id;
  RETURN jsonb_build_object('success', true, 'status', 'approved');
END;
$$;
REVOKE EXECUTE ON FUNCTION public.careflow_admin_approve_clinic(UUID) FROM PUBLIC, anon; GRANT EXECUTE ON FUNCTION public.careflow_admin_approve_clinic(UUID) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.careflow_admin_reject_clinic(p_clinic_id UUID, p_reason text) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin') THEN RAISE EXCEPTION 'Unauthorized: Only platform administrators can reject clinics.'; END IF;
  ELSIF auth.role() = 'service_role' THEN NULL; ELSE RAISE EXCEPTION 'Unauthorized: Invalid execution context.'; END IF;
  UPDATE public.clinics SET status = 'rejected', rejection_reason = p_reason WHERE id = p_clinic_id;
  RETURN jsonb_build_object('success', true, 'status', 'rejected', 'reason', p_reason);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.careflow_admin_reject_clinic(UUID, text) FROM PUBLIC, anon; GRANT EXECUTE ON FUNCTION public.careflow_admin_reject_clinic(UUID, text) TO authenticated, service_role;

-- 4. Secure Queue RPC
CREATE OR REPLACE FUNCTION public.careflow_call_next_patient(p_clinic_id UUID) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_now_serving INT; v_next_appointment RECORD; v_is_authorized BOOLEAN := false;
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF auth.uid() = p_clinic_id THEN v_is_authorized := true;
    ELSIF EXISTS (SELECT 1 FROM public.clinic_doctors WHERE doctor_id = auth.uid() AND clinic_id = p_clinic_id) THEN v_is_authorized := true;
    ELSIF EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin') THEN v_is_authorized := true; END IF;
    IF NOT v_is_authorized THEN RAISE EXCEPTION 'Unauthorized: Caller is not authorized for this clinic.'; END IF;
  ELSIF auth.role() = 'service_role' THEN v_is_authorized := true; ELSE RAISE EXCEPTION 'Unauthorized: Invalid execution context.'; END IF;
  
  -- Find the next eligible appointment in the queue
  -- Lock the queue counter to serialize concurrent calls for this clinic
  SELECT now_serving INTO v_now_serving FROM public.careflow_queue_counters WHERE clinic_id = p_clinic_id FOR UPDATE;
  
  SELECT * INTO v_next_appointment FROM public.careflow_appointments WHERE clinic_id = p_clinic_id AND status IN ('checked_in', 'waiting') AND token_number > 0 ORDER BY token_number ASC LIMIT 1;
  IF NOT FOUND THEN RETURN jsonb_build_object('success', false, 'message', 'No patients waiting in queue.'); END IF;
  
  -- Advance now_serving in queue counter to match this patient's token
  UPDATE public.careflow_queue_counters SET now_serving = v_next_appointment.token_number, updated_at = now() WHERE clinic_id = p_clinic_id RETURNING now_serving INTO v_now_serving;
  
  UPDATE public.careflow_appointments SET status = 'in_consultation' WHERE id = v_next_appointment.id;
  INSERT INTO public.careflow_notifications(user_id, title, body, type, is_read, created_at) VALUES (v_next_appointment.patient_id, 'Your Turn: Now Serving #' || v_now_serving, 'Please proceed to the doctor consultation room.', 'queue', false, now());
  
  RETURN jsonb_build_object('success', true, 'clinic_id', p_clinic_id, 'now_serving', v_now_serving, 'appointment_id', v_next_appointment.id);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.careflow_call_next_patient(UUID) FROM PUBLIC, anon; GRANT EXECUTE ON FUNCTION public.careflow_call_next_patient(UUID) TO authenticated, service_role;

-- 5. Secure QR Check-in RPC
CREATE OR REPLACE FUNCTION public.careflow_clinic_scan_qr(p_qr_token UUID, p_clinic_id UUID) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_appointment RECORD; v_token INT; v_is_authorized BOOLEAN := false;
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF auth.uid() = p_clinic_id THEN v_is_authorized := true;
    ELSIF EXISTS (SELECT 1 FROM public.clinic_doctors WHERE doctor_id = auth.uid() AND clinic_id = p_clinic_id) THEN v_is_authorized := true;
    ELSIF EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin') THEN v_is_authorized := true; END IF;
    IF NOT v_is_authorized THEN RAISE EXCEPTION 'Unauthorized: Caller is not authorized for this clinic.'; END IF;
  ELSIF auth.role() = 'service_role' THEN v_is_authorized := true; ELSE RAISE EXCEPTION 'Unauthorized: Invalid execution context.'; END IF;
  
  SELECT * INTO v_appointment FROM public.careflow_appointments WHERE qr_token = p_qr_token FOR UPDATE SKIP LOCKED;
  IF NOT FOUND THEN RETURN jsonb_build_object('success', false, 'message', 'Invalid QR code or appointment not found.'); END IF;
  IF v_appointment.clinic_id != p_clinic_id THEN RETURN jsonb_build_object('success', false, 'message', 'Access denied. Appointment does not belong to this clinic.'); END IF;
  IF v_appointment.appointment_date != CURRENT_DATE THEN RETURN jsonb_build_object('success', false, 'message', 'Check-in failed. Appointment is not scheduled for today.'); END IF;
  IF v_appointment.status = 'cancelled' OR v_appointment.status = 'rejected' THEN RETURN jsonb_build_object('success', false, 'message', 'Check-in rejected. Appointment is cancelled.'); END IF;
  IF v_appointment.status = 'checked_in' OR v_appointment.status = 'waiting' OR v_appointment.status = 'in_consultation' OR v_appointment.status = 'completed' THEN RETURN jsonb_build_object('success', false, 'message', 'Appointment already checked in.'); END IF;
  
  UPDATE public.careflow_queue_counters SET current_token = current_token + 1, updated_at = now() WHERE clinic_id = p_clinic_id RETURNING current_token INTO v_token;
  IF v_token IS NULL THEN 
    BEGIN
      INSERT INTO public.careflow_queue_counters (clinic_id, current_token, now_serving, updated_at) VALUES (p_clinic_id, 1, 0, now()) RETURNING current_token INTO v_token; 
    EXCEPTION WHEN unique_violation THEN
      UPDATE public.careflow_queue_counters SET current_token = current_token + 1, updated_at = now() WHERE clinic_id = p_clinic_id RETURNING current_token INTO v_token;
    END;
  END IF;
  
  UPDATE public.careflow_appointments SET status = 'checked_in', token_number = v_token WHERE id = v_appointment.id;
  RETURN jsonb_build_object('success', true, 'appointment_id', v_appointment.id, 'token_number', v_token, 'patient_id', v_appointment.patient_id, 'doctor_id', v_appointment.doctor_id, 'clinic_id', v_appointment.clinic_id, 'queue_status', 'checked_in', 'appointment_time', v_appointment.appointment_time);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.careflow_clinic_scan_qr(UUID, UUID) FROM PUBLIC, anon; GRANT EXECUTE ON FUNCTION public.careflow_clinic_scan_qr(UUID, UUID) TO authenticated, service_role;
