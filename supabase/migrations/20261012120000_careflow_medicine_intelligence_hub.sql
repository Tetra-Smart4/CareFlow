-- ============================================================================
-- CAREFLOW MIGRATION: MEDICINE INTELLIGENCE HUB & CLINICAL TRIAGE CATALOGUE
-- Version: 20261012120000
-- ============================================================================

-- 1. MEDICINE CATALOGUE REFERENCE TABLE
CREATE TABLE IF NOT EXISTS public.careflow_medicine_catalogue (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  brand_name TEXT,
  generic_name TEXT NOT NULL,
  ingredients JSONB DEFAULT '[]'::jsonb,
  composition TEXT,
  strength TEXT NOT NULL,
  dosage_form TEXT NOT NULL,
  dosage_category TEXT DEFAULT 'solid_oral',
  route TEXT DEFAULT 'oral',
  manufacturer TEXT,
  classification TEXT NOT NULL DEFAULT 'Brand',
  overview TEXT NOT NULL,
  common_uses JSONB DEFAULT '[]'::jsonb,
  side_effects JSONB DEFAULT '[]'::jsonb,
  precautions JSONB DEFAULT '[]'::jsonb,
  contraindications JSONB DEFAULT '[]'::jsonb,
  drug_interactions JSONB DEFAULT '[]'::jsonb,
  storage_info TEXT,
  -- DUAL VERIFICATION ARCHITECTURE: Defaults to 'unverified'
  identity_verification_status TEXT NOT NULL DEFAULT 'unverified' CHECK (identity_verification_status IN ('unverified', 'source_confirmed', 'regulatory_registered', 'withdrawn')),
  clinical_verification_status TEXT NOT NULL DEFAULT 'unverified' CHECK (clinical_verification_status IN ('unverified', 'monograph_linked', 'clinically_reviewed', 'flagged_for_review')),
  verification_status TEXT NOT NULL DEFAULT 'not_verified' CHECK (verification_status IN ('verified', 'partially_verified', 'not_verified', 'under_review', 'withdrawn')),
  verification_scope TEXT NOT NULL DEFAULT 'Product monograph pending clinical review',
  source_references JSONB DEFAULT '[]'::jsonb,
  source_metadata JSONB DEFAULT '{}'::jsonb,
  mrp_inr NUMERIC(10,2),
  last_reviewed_date DATE DEFAULT CURRENT_DATE,
  is_prescription_required BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Search Indexes
CREATE INDEX IF NOT EXISTS idx_medicine_name ON public.careflow_medicine_catalogue (name);
CREATE INDEX IF NOT EXISTS idx_medicine_generic ON public.careflow_medicine_catalogue (generic_name);
CREATE INDEX IF NOT EXISTS idx_medicine_dosage_form ON public.careflow_medicine_catalogue (dosage_form);
CREATE INDEX IF NOT EXISTS idx_medicine_identity_verification ON public.careflow_medicine_catalogue (identity_verification_status);
CREATE INDEX IF NOT EXISTS idx_medicine_clinical_verification ON public.careflow_medicine_catalogue (clinical_verification_status);

-- 2. SYMPTOM TRIAGE & RED-FLAG SAFETY GUIDELINES TABLE
CREATE TABLE IF NOT EXISTS public.careflow_symptom_triage_guidelines (
  id TEXT PRIMARY KEY,
  symptom_name TEXT NOT NULL,
  category TEXT NOT NULL,
  is_emergency BOOLEAN NOT NULL DEFAULT false,
  emergency_warning TEXT,
  red_flags JSONB DEFAULT '[]'::jsonb,
  common_causes JSONB DEFAULT '[]'::jsonb,
  follow_up_questions JSONB DEFAULT '[]'::jsonb,
  safe_self_care JSONB DEFAULT '[]'::jsonb,
  when_to_seek_doctor TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_symptom_name ON public.careflow_symptom_triage_guidelines (symptom_name);
CREATE INDEX IF NOT EXISTS idx_symptom_emergency ON public.careflow_symptom_triage_guidelines (is_emergency);

-- 3. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.careflow_medicine_catalogue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.careflow_symptom_triage_guidelines ENABLE ROW LEVEL SECURITY;

-- Read policy: Public users may ONLY query clinically verified/monograph-linked and non-withdrawn records
DROP POLICY IF EXISTS "Allow public read access to medicine catalogue" ON public.careflow_medicine_catalogue;
DROP POLICY IF EXISTS "Allow public read access to verified medicine catalogue" ON public.careflow_medicine_catalogue;
CREATE POLICY "Allow public read access to verified medicine catalogue"
  ON public.careflow_medicine_catalogue FOR SELECT
  TO authenticated, anon
  USING (
    clinical_verification_status != 'unverified' AND
    identity_verification_status != 'withdrawn'
  );

-- Admin read policy: Platform administrators can view all records (including unverified drafts)
DROP POLICY IF EXISTS "Platform admins read all medicine catalogue" ON public.careflow_medicine_catalogue;
CREATE POLICY "Platform admins read all medicine catalogue"
  ON public.careflow_medicine_catalogue FOR SELECT
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin')
  );

DROP POLICY IF EXISTS "Allow public read access to symptom triage" ON public.careflow_symptom_triage_guidelines;
CREATE POLICY "Allow public read access to symptom triage"
  ON public.careflow_symptom_triage_guidelines FOR SELECT
  TO authenticated, anon
  USING (true);

-- Write policy: STRICTLY restricted to global platform_admin (Clinic admins must NOT write global catalogue)
DROP POLICY IF EXISTS "Platform admins manage medicine catalogue" ON public.careflow_medicine_catalogue;
CREATE POLICY "Platform admins manage medicine catalogue"
  ON public.careflow_medicine_catalogue FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin')
  );

DROP POLICY IF EXISTS "Platform admins manage symptom triage" ON public.careflow_symptom_triage_guidelines;
CREATE POLICY "Platform admins manage symptom triage"
  ON public.careflow_symptom_triage_guidelines FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'platform_admin')
  );

-- 4. SEED REFERENCE MEDICINES WITH DUAL VERIFICATION
INSERT INTO public.careflow_medicine_catalogue (
  id, name, brand_name, generic_name, ingredients, composition, strength, dosage_form, dosage_category, route, manufacturer, classification, overview, common_uses, side_effects, precautions, contraindications, drug_interactions, storage_info, identity_verification_status, clinical_verification_status, verification_status, verification_scope, source_references, source_metadata, mrp_inr, last_reviewed_date, is_prescription_required
)
VALUES
(
  'med_dolo_650', 'Dolo 650', 'Dolo', 'Paracetamol',
  '["Paracetamol (Acetaminophen) 650mg"]'::jsonb,
  'Paracetamol (Acetaminophen) 650mg', '650 mg', 'Tablet', 'solid_oral', 'oral', 'Micro Labs Ltd', 'Brand',
  'Analgesic and antipyretic medication indicated for mild to moderate pain relief and fever reduction in adults.',
  '["Fever reduction", "Mild to moderate headaches", "Body aches", "Post-vaccination pyrexia"]'::jsonb,
  '["Nausea", "Allergic skin reaction (rare)", "Hepatotoxicity with excessive dosage (>4000mg/day)"]'::jsonb,
  '["Do not exceed 4000 mg in 24 hours across all paracetamol sources.", "Use with caution in chronic alcoholics or patients with underlying hepatic impairment."]'::jsonb,
  '["Known hypersensitivity to paracetamol", "Severe active hepatic impairment"]'::jsonb,
  '[{"interacting_drug": "Warfarin", "severity": "Moderate", "clinical_effect": "Prolonged regular use of paracetamol may enhance the anticoagulant effect of warfarin.", "management": "Monitor INR if taken daily for more than 4-5 consecutive days.", "evidence_source": "Indian Pharmacopoeia (IP 2022)"}]'::jsonb,
  'Store below 30°C in a dry place. Protect from moisture and direct sunlight.',
  'source_confirmed', 'monograph_linked', 'partially_verified',
  'Product identity confirmed via CDSCO/IP; clinical interaction monograph linked to IP 2022.',
  '["CDSCO Approved Formulations List", "Indian Pharmacopoeia (IP 2022)", "NLEM 2022"]'::jsonb,
  '{"source_name": "CDSCO_NLEM_IP2022", "retrieved_at": "2026-10-12T10:00:00Z"}'::jsonb,
  34.00, '2026-08-15', false
),
(
  'med_augmentin_625', 'Augmentin 625 Duo', 'Augmentin', 'Amoxicillin + Clavulanic Acid',
  '["Amoxicillin Trihydrate 500mg", "Potassium Clavulanate 125mg"]'::jsonb,
  'Amoxicillin Trihydrate 500mg + Potassium Clavulanate 125mg', '500 mg / 125 mg', 'Tablet', 'solid_oral', 'oral', 'GlaxoSmithKline Pharmaceuticals Ltd', 'Combination',
  'Broad-spectrum beta-lactam antibacterial combined with a beta-lactamase inhibitor for bacterial infections.',
  '["Acute bacterial sinusitis", "Otitis media", "Lower respiratory tract infections", "Skin & soft tissue infections"]'::jsonb,
  '["Diarrhea", "Nausea", "Oral or vaginal candidiasis", "Urticaria / rash"]'::jsonb,
  '["Complete the full prescribed course even if symptoms resolve early.", "Take at the start of a meal to minimize gastrointestinal intolerance."]'::jsonb,
  '["History of hypersensitivity to beta-lactam antibacterials", "Previous history of amoxicillin-clavulanate-associated jaundice"]'::jsonb,
  '[{"interacting_drug": "Methotrexate", "severity": "Major", "clinical_effect": "Penicillins may reduce the excretion of methotrexate, causing increased toxicity.", "management": "Carefully monitor methotrexate serum levels or avoid co-administration.", "evidence_source": "WHO Formulary"}]'::jsonb,
  'Store in airtight blister strip below 25°C. Sensitive to moisture.',
  'source_confirmed', 'monograph_linked', 'partially_verified',
  'Schedule H1 antibacterial regulatory compliance verified; monograph linked to IP 2022.',
  '["CDSCO Schedule H1 Antibacterial Registry", "Indian Pharmacopoeia (IP 2022)"]'::jsonb,
  '{"source_name": "CDSCO_SCHEDULE_H1", "retrieved_at": "2026-10-12T10:00:00Z"}'::jsonb,
  125.00, '2026-09-01', true
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  brand_name = EXCLUDED.brand_name,
  generic_name = EXCLUDED.generic_name,
  ingredients = EXCLUDED.ingredients,
  composition = EXCLUDED.composition,
  strength = EXCLUDED.strength,
  dosage_form = EXCLUDED.dosage_form,
  dosage_category = EXCLUDED.dosage_category,
  route = EXCLUDED.route,
  manufacturer = EXCLUDED.manufacturer,
  overview = EXCLUDED.overview,
  identity_verification_status = EXCLUDED.identity_verification_status,
  clinical_verification_status = EXCLUDED.clinical_verification_status,
  verification_status = EXCLUDED.verification_status,
  updated_at = now();

-- ============================================================================
-- ROLLBACK INSTRUCTIONS (Non-destructive):
-- DROP TABLE IF EXISTS public.careflow_symptom_triage_guidelines;
-- DROP TABLE IF EXISTS public.careflow_medicine_catalogue;
-- ============================================================================
