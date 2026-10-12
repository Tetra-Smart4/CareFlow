-- ============================================================================
-- CAREFLOW MIGRATION: CLINIC MEDICINE INVENTORY & AUDITABLE TRANSACTIONS
-- Version: 20261012100000
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.careflow_inventory_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  medicine_name TEXT NOT NULL,
  generic_name TEXT,
  composition TEXT,
  dosage_form TEXT DEFAULT 'Tablet',
  pack_size TEXT DEFAULT '10 tablets',
  batch_number TEXT,
  expiry_date DATE,
  stock_quantity INT NOT NULL DEFAULT 0,
  reorder_threshold INT NOT NULL DEFAULT 10,
  purchase_price NUMERIC(10,2),
  selling_price NUMERIC(10,2),
  supplier TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_inventory_clinic ON public.careflow_inventory_items(clinic_id);
CREATE INDEX IF NOT EXISTS idx_inventory_expiry ON public.careflow_inventory_items(expiry_date);

CREATE TABLE IF NOT EXISTS public.careflow_inventory_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES public.careflow_inventory_items(id) ON DELETE CASCADE,
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('received', 'issued', 'dispensed', 'return', 'adjustment', 'wastage')),
  quantity INT NOT NULL,
  previous_stock INT NOT NULL,
  new_stock INT NOT NULL,
  batch_number TEXT,
  notes TEXT,
  actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_inventory_trans_clinic ON public.careflow_inventory_transactions(clinic_id);
CREATE INDEX IF NOT EXISTS idx_inventory_trans_item ON public.careflow_inventory_transactions(item_id);

-- ROW LEVEL SECURITY
ALTER TABLE public.careflow_inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.careflow_inventory_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Clinics can manage own inventory" ON public.careflow_inventory_items;
CREATE POLICY "Clinics can manage own inventory"
  ON public.careflow_inventory_items FOR ALL
  TO authenticated
  USING (
    clinic_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'platform_admin' OR role = 'admin'))
  )
  WITH CHECK (
    clinic_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'platform_admin' OR role = 'admin'))
  );

DROP POLICY IF EXISTS "Clinics can manage own inventory transactions" ON public.careflow_inventory_transactions;
CREATE POLICY "Clinics can manage own inventory transactions"
  ON public.careflow_inventory_transactions FOR ALL
  TO authenticated
  USING (
    clinic_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'platform_admin' OR role = 'admin'))
  )
  WITH CHECK (
    clinic_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'platform_admin' OR role = 'admin'))
  );
