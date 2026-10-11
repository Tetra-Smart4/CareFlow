CREATE TABLE IF NOT EXISTS public.careflow_medication_adherence (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    prescription_id UUID REFERENCES public.careflow_prescriptions(id) ON DELETE CASCADE,
    medicine_name TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('taken', 'missed')),
    scheduled_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.careflow_medication_adherence ENABLE ROW LEVEL SECURITY;

-- Policy: Patients can view and insert their own adherence records
CREATE POLICY "Patients can view own adherence" 
ON public.careflow_medication_adherence 
FOR SELECT 
USING (auth.uid() = patient_id);

CREATE POLICY "Patients can insert own adherence" 
ON public.careflow_medication_adherence 
FOR INSERT 
WITH CHECK (auth.uid() = patient_id);

-- Policy: Doctors can view their patients' adherence
CREATE POLICY "Doctors can view adherence" 
ON public.careflow_medication_adherence 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM public.careflow_appointments a
    WHERE a.patient_id = careflow_medication_adherence.patient_id 
      AND a.doctor_id = auth.uid()
  )
);
