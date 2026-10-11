-- ============================================================
-- CAREFLOW SCHEDULING, REAL AVAILABLE SLOTS & DOUBLE-BOOKING PREVENTION
-- ============================================================

-- 1. Prevent double-booking for the same doctor at the same date and time
-- Exclude cancelled or rejected appointments
CREATE UNIQUE INDEX IF NOT EXISTS careflow_unique_doctor_booking
  ON public.careflow_appointments (doctor_id, appointment_date, appointment_time)
  WHERE status NOT IN ('cancelled', 'rejected');

-- 2. RPC: careflow_get_available_slots
-- Returns real available slots for a doctor on a specific date,
-- checking against active appointments to exclude already booked times.
CREATE OR REPLACE FUNCTION public.careflow_get_available_slots(
  p_doctor_id UUID,
  p_date DATE
)
RETURNS TABLE (slot_time TEXT, is_available BOOLEAN)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_default_slots TEXT[] := ARRAY[
    '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM',
    '11:00 AM', '11:30 AM', '02:00 PM', '02:30 PM',
    '03:00 PM', '03:30 PM', '04:00 PM', '04:30 PM'
  ];
  v_slot TEXT;
  v_booked_count INT;
  v_time_val TIME;
  v_hour INT;
  v_minute INT;
  v_period TEXT;
BEGIN
  FOREACH v_slot IN ARRAY v_default_slots
  LOOP
    -- Parse 12-hour slot into TIME
    v_period := split_part(v_slot, ' ', 2);
    v_hour := split_part(split_part(v_slot, ' ', 1), ':', 1)::INT;
    v_minute := split_part(split_part(v_slot, ' ', 1), ':', 2)::INT;
    
    IF v_period = 'PM' AND v_hour < 12 THEN
      v_hour := v_hour + 12;
    ELSIF v_period = 'AM' AND v_hour = 12 THEN
      v_hour := 0;
    END IF;
    
    v_time_val := make_time(v_hour, v_minute, 0);

    -- Check if booked
    SELECT COUNT(*) INTO v_booked_count
    FROM public.careflow_appointments
    WHERE doctor_id = p_doctor_id
      AND appointment_date = p_date
      AND appointment_time = v_time_val
      AND status NOT IN ('cancelled', 'rejected');

    slot_time := v_slot;
    is_available := (v_booked_count = 0);
    RETURN NEXT;
  END LOOP;
END;
$$;

-- Grant execution to authenticated users
GRANT EXECUTE ON FUNCTION public.careflow_get_available_slots(UUID, DATE) TO authenticated;

-- 3. RPC: careflow_book_appointment
-- Safely books an appointment, verifying that the slot is still open
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
AS $$
DECLARE
  v_existing_count INT;
  v_new_appt RECORD;
BEGIN
  -- Double booking check
  SELECT COUNT(*) INTO v_existing_count
  FROM public.careflow_appointments
  WHERE doctor_id = p_doctor_id
    AND appointment_date = p_date
    AND appointment_time = p_time
    AND status NOT IN ('cancelled', 'rejected');

  IF v_existing_count > 0 THEN
    RAISE EXCEPTION 'This time slot is already booked. Please choose another time slot.';
  END IF;

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

  -- Create notification for doctor
  INSERT INTO public.careflow_notifications (
    user_id,
    title,
    message,
    type,
    created_at
  ) VALUES (
    p_doctor_id,
    'New Appointment Booked',
    'A new appointment has been scheduled for ' || to_char(p_date, 'Mon DD, YYYY') || '.',
    'appointment',
    now()
  );

  RETURN to_jsonb(v_new_appt);
END;
$$;

GRANT EXECUTE ON FUNCTION public.careflow_book_appointment(UUID, UUID, UUID, DATE, TIME, TEXT) TO authenticated;
