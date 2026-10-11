-- 1. Add reference_id to notifications table
ALTER TABLE public.careflow_notifications ADD COLUMN IF NOT EXISTS reference_id UUID;

-- 1b. Deduplicate existing appointments to allow unique index creation
UPDATE public.careflow_appointments
SET status = 'cancelled'
WHERE id IN (
  SELECT a.id
  FROM public.careflow_appointments a
  JOIN public.careflow_appointments b
    ON a.doctor_id = b.doctor_id 
   AND a.appointment_date = b.appointment_date 
   AND a.appointment_time = b.appointment_time
   AND a.id > b.id
  WHERE a.status NOT IN ('cancelled', 'rejected') 
    AND b.status NOT IN ('cancelled', 'rejected')
);

-- 1c. Add unique index to prevent double bookings
CREATE UNIQUE INDEX IF NOT EXISTS careflow_unique_doctor_booking 
ON public.careflow_appointments(doctor_id, appointment_date, appointment_time) 
WHERE status NOT IN ('cancelled', 'rejected');

-- 2. Update careflow_book_appointment RPC to include patient name and reference_id
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
BEGIN
  -- Validate caller
  IF auth.uid() NOT IN (p_patient_id, p_doctor_id, p_clinic_id) THEN
    RAISE EXCEPTION 'Not authorized to book this appointment.';
  END IF;

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
