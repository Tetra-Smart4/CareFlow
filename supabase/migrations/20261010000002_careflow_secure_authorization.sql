-- ============================================================
-- CAREFLOW DATABASE MIGRATION: SECURE AUTHORIZATION
-- Prevents users from elevating roles and clinics from self-approving.
-- ============================================================

-- 1. Prevent users from changing their own role or status
CREATE OR REPLACE FUNCTION public.careflow_secure_profile_update()
RETURNS TRIGGER AS $$
BEGIN
  -- If the role is being changed
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    IF current_setting('request.jwt.claims', true) IS NOT NULL THEN
      IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'platform_admin')) THEN
        RAISE EXCEPTION 'Unauthorized: Users cannot modify their own role.';
      END IF;
    END IF;
  END IF;

  -- If the status is being changed
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF current_setting('request.jwt.claims', true) IS NOT NULL THEN
      IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'platform_admin')) THEN
        RAISE EXCEPTION 'Unauthorized: Users cannot modify their own profile status.';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_secure_profile_update ON public.profiles;
CREATE TRIGGER tr_secure_profile_update
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.careflow_secure_profile_update();

-- 2. Prevent clinics from changing their own approval status
CREATE OR REPLACE FUNCTION public.careflow_secure_clinic_update()
RETURNS TRIGGER AS $$
BEGIN
  -- If the status is being changed
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF current_setting('request.jwt.claims', true) IS NOT NULL THEN
      IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'platform_admin')) THEN
        RAISE EXCEPTION 'Unauthorized: Clinics cannot modify their own approval status.';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_secure_clinic_update ON public.clinics;
CREATE TRIGGER tr_secure_clinic_update
BEFORE UPDATE ON public.clinics
FOR EACH ROW
EXECUTE FUNCTION public.careflow_secure_clinic_update();
