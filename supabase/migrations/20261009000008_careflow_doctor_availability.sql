-- Table: careflow_doctor_availability
CREATE TABLE IF NOT EXISTS public.careflow_doctor_availability (
  id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  doctor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  clinic_id UUID REFERENCES public.clinics(id) ON DELETE CASCADE,
  day_of_week INT NOT NULL CHECK (day_of_week >= 1 AND day_of_week <= 7), -- 1=Monday, 7=Sunday
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  slot_duration_minutes INT DEFAULT 30,
  break_start TIME,
  break_end TIME,
  UNIQUE(doctor_id, clinic_id, day_of_week)
);

ALTER TABLE public.careflow_doctor_availability ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Availability readable by all"
ON public.careflow_doctor_availability FOR SELECT TO authenticated USING (true);

CREATE POLICY "Doctors can manage their availability"
ON public.careflow_doctor_availability FOR ALL TO authenticated
USING (doctor_id = auth.uid() OR clinic_id = auth.uid())
WITH CHECK (doctor_id = auth.uid() OR clinic_id = auth.uid());


-- Table: careflow_doctor_exceptions
CREATE TABLE IF NOT EXISTS public.careflow_doctor_exceptions (
  id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  doctor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  exception_date DATE NOT NULL,
  is_leave BOOLEAN DEFAULT false,
  start_time TIME, -- If not leave, custom start
  end_time TIME,   -- If not leave, custom end
  reason TEXT,
  UNIQUE(doctor_id, exception_date)
);

ALTER TABLE public.careflow_doctor_exceptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Exceptions readable by all"
ON public.careflow_doctor_exceptions FOR SELECT TO authenticated USING (true);

CREATE POLICY "Doctors can manage their exceptions"
ON public.careflow_doctor_exceptions FOR ALL TO authenticated
USING (doctor_id = auth.uid() OR EXISTS (SELECT 1 FROM public.careflow_doctor_availability WHERE doctor_id = careflow_doctor_exceptions.doctor_id AND clinic_id = auth.uid()))
WITH CHECK (doctor_id = auth.uid() OR EXISTS (SELECT 1 FROM public.careflow_doctor_availability WHERE doctor_id = careflow_doctor_exceptions.doctor_id AND clinic_id = auth.uid()));


-- Update RPC: careflow_get_available_slots
CREATE OR REPLACE FUNCTION public.careflow_get_available_slots(
  p_doctor_id UUID,
  p_date DATE,
  p_clinic_id UUID DEFAULT NULL
)
RETURNS TABLE (slot_time TEXT, is_available BOOLEAN)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_dow INT;
  v_avail RECORD;
  v_exc RECORD;
  v_current_time TIME;
  v_end_time TIME;
  v_booked_count INT;
  v_is_leave BOOLEAN := false;
BEGIN
  -- 1. Check for exceptions
  SELECT * INTO v_exc FROM public.careflow_doctor_exceptions WHERE doctor_id = p_doctor_id AND exception_date = p_date;
  
  IF FOUND AND v_exc.is_leave THEN
    -- Doctor is on leave
    RETURN;
  END IF;

  -- 2. Get standard availability for the day of week (1=Monday, 7=Sunday in PostgreSQL extract(isodow))
  v_dow := EXTRACT(ISODOW FROM p_date);
  
  IF p_clinic_id IS NOT NULL THEN
    SELECT * INTO v_avail FROM public.careflow_doctor_availability WHERE doctor_id = p_doctor_id AND clinic_id = p_clinic_id AND day_of_week = v_dow;
  ELSE
    -- Just pick the first one if clinic not specified (or limit to one clinic per day)
    SELECT * INTO v_avail FROM public.careflow_doctor_availability WHERE doctor_id = p_doctor_id AND day_of_week = v_dow LIMIT 1;
  END IF;

  IF NOT FOUND THEN
    -- Return immediately if no availability configured instead of defaulting
    RETURN;
  ELSE
    v_current_time := v_avail.start_time;
    v_end_time := v_avail.end_time;
  END IF;

  -- Override with exception if not leave
  IF FOUND AND v_exc.start_time IS NOT NULL THEN
    v_current_time := v_exc.start_time;
    v_end_time := v_exc.end_time;
  END IF;

  -- Generate slots
  WHILE v_current_time < v_end_time LOOP
    -- Check break time
    IF v_avail.break_start IS NOT NULL AND v_avail.break_end IS NOT NULL THEN
      IF v_current_time >= v_avail.break_start AND v_current_time < v_avail.break_end THEN
        v_current_time := v_current_time + (COALESCE(v_avail.slot_duration_minutes, 30) || ' minutes')::INTERVAL;
        CONTINUE;
      END IF;
    END IF;

    -- Check if booked
    SELECT COUNT(*) INTO v_booked_count
    FROM public.careflow_appointments
    WHERE doctor_id = p_doctor_id
      AND appointment_date = p_date
      AND appointment_time = v_current_time
      AND status NOT IN ('cancelled', 'rejected');

    slot_time := to_char(v_current_time, 'HH12:MI AM');
    is_available := (v_booked_count = 0);
    RETURN NEXT;

    -- Advance time
    v_current_time := v_current_time + (COALESCE(v_avail.slot_duration_minutes, 30) || ' minutes')::INTERVAL;
  END LOOP;
END;
$$;


-- Update RPC: careflow_book_appointment (to ensure it enforces availability)
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
BEGIN
  -- 1. Check Exceptions (Leave)
  SELECT * INTO v_exc FROM public.careflow_doctor_exceptions WHERE doctor_id = p_doctor_id AND exception_date = p_date;
  IF FOUND AND v_exc.is_leave THEN
    RAISE EXCEPTION 'Doctor is on leave on this date.';
  END IF;

  -- 2. Check Availability Bounds
  v_dow := EXTRACT(ISODOW FROM p_date);
  SELECT * INTO v_avail FROM public.careflow_doctor_availability WHERE doctor_id = p_doctor_id AND clinic_id = p_clinic_id AND day_of_week = v_dow;
  
  IF NOT FOUND THEN
    -- If there's an exception granting availability, that's fine.
    IF v_exc.start_time IS NULL THEN
      RAISE EXCEPTION 'Doctor is not available on this day.';
    END IF;
  ELSE
    IF p_time < v_avail.start_time OR p_time >= v_avail.end_time THEN
       -- Unless overridden by exception
       IF v_exc.start_time IS NULL OR (p_time < v_exc.start_time OR p_time >= v_exc.end_time) THEN
         RAISE EXCEPTION 'Selected time is outside doctor working hours.';
       END IF;
    END IF;
    
    IF v_avail.break_start IS NOT NULL AND p_time >= v_avail.break_start AND p_time < v_avail.break_end THEN
       RAISE EXCEPTION 'Selected time is during doctor break.';
    END IF;
  END IF;

  -- Validate caller (patient, doctor, or clinic manager)
  IF auth.uid() NOT IN (p_patient_id, p_doctor_id, p_clinic_id) THEN
    RAISE EXCEPTION 'Not authorized to book this appointment.';
  END IF;

  -- 3. Double booking check
  SELECT COUNT(*) INTO v_existing_count
  FROM public.careflow_appointments
  WHERE doctor_id = p_doctor_id
    AND appointment_date = p_date
    AND appointment_time = p_time
    AND status NOT IN ('cancelled', 'rejected');

  IF v_existing_count > 0 THEN
    RAISE EXCEPTION 'This time slot is already booked. Please choose another time slot.';
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
