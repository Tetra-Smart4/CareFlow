-- ============================================================
-- CAREFLOW MIGRATION: QR Code Check-in
-- ============================================================

-- 1. Add qr_token to appointments
ALTER TABLE IF EXISTS public.careflow_appointments
  ADD COLUMN IF NOT EXISTS qr_token UUID UNIQUE DEFAULT gen_random_uuid();

-- 2. Create the Clinic Check-in RPC
CREATE OR REPLACE FUNCTION public.careflow_clinic_scan_qr(p_qr_token UUID, p_clinic_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment RECORD;
  v_token INT;
BEGIN
  -- Find the appointment with row lock
  SELECT * INTO v_appointment
  FROM public.careflow_appointments
  WHERE qr_token = p_qr_token
  FOR UPDATE SKIP LOCKED;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'Invalid QR code or appointment not found.');
  END IF;

  -- Validate clinic
  IF v_appointment.clinic_id != p_clinic_id THEN
    RETURN jsonb_build_object('success', false, 'message', 'Access denied. Appointment does not belong to this clinic.');
  END IF;

  -- Validate status
  IF v_appointment.status = 'cancelled' OR v_appointment.status = 'rejected' THEN
    RETURN jsonb_build_object('success', false, 'message', 'Check-in rejected. Appointment is cancelled.');
  END IF;

  IF v_appointment.status = 'checked_in' OR v_appointment.status = 'waiting' OR v_appointment.status = 'in_consultation' OR v_appointment.status = 'completed' THEN
    RETURN jsonb_build_object('success', false, 'message', 'Appointment already checked in.');
  END IF;

  -- Validate check-in window (must be today)
  IF v_appointment.appointment_date != CURRENT_DATE THEN
    RETURN jsonb_build_object('success', false, 'message', 'Check-in failed. Appointment is not scheduled for today.');
  END IF;

  -- Generate token safely
  UPDATE public.careflow_queue_counters
  SET current_token = current_token + 1,
      updated_at = now()
  WHERE clinic_id = p_clinic_id
  RETURNING current_token INTO v_token;

  IF v_token IS NULL THEN
    INSERT INTO public.careflow_queue_counters (clinic_id, current_token, now_serving, updated_at)
    VALUES (p_clinic_id, 1, 0, now())
    RETURNING current_token INTO v_token;
  END IF;

  -- Update appointment status and token
  UPDATE public.careflow_appointments
  SET status = 'checked_in',
      token_number = v_token
  WHERE id = v_appointment.id;

  RETURN jsonb_build_object(
    'success', true,
    'appointment_id', v_appointment.id,
    'token_number', v_token,
    'patient_id', v_appointment.patient_id,
    'doctor_id', v_appointment.doctor_id,
    'appointment_time', v_appointment.appointment_time
  );
END;
$$;
