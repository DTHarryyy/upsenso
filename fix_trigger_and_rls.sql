-- =====================================================
-- FIX TRIGGER: Use owner_id as users.id to match auth.uid()
-- This fixes the circular RLS dependency issue
-- =====================================================

DROP TRIGGER IF EXISTS user_creation_trigger ON public.businesses;
DROP FUNCTION IF EXISTS create_user_for_new_business() CASCADE;

CREATE OR REPLACE FUNCTION create_user_for_new_business()
RETURNS TRIGGER AS $$
DECLARE
  v_full_name TEXT;
  v_role_id UUID;
  v_owner_email TEXT;
BEGIN
  -- Get owner's email from auth.users
  SELECT email INTO v_owner_email
  FROM auth.users
  WHERE id = NEW.owner_id;

  -- Extract full name from email (e.g., "john.doe@example.com" -> "John Doe")
  v_full_name := INITCAP(
    REPLACE(REPLACE(SPLIT_PART(v_owner_email, '@', 1), '.', ' '), '_', ' ')
  );

  -- Create Super Admin role for this business
  INSERT INTO public.roles (business_id, name, permissions)
  VALUES (NEW.id, 'Super Admin', '["all"]'::jsonb)
  RETURNING id INTO v_role_id;

  -- CRITICAL FIX: Use owner_id as users.id (not gen_random_uuid())
  -- This makes users.id = auth.uid(), which the RLS policies require
  INSERT INTO public.users (id, business_id, full_name, email, role_id, is_active)
  VALUES (
    NEW.owner_id,  -- Use owner_id to match auth.uid()
    NEW.id,
    v_full_name,
    v_owner_email,
    v_role_id,
    true
  )
  ON CONFLICT (id) DO UPDATE
  SET 
    business_id = EXCLUDED.business_id,
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    role_id = EXCLUDED.role_id,
    is_active = EXCLUDED.is_active;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER user_creation_trigger
AFTER INSERT ON public.businesses
FOR EACH ROW
EXECUTE FUNCTION create_user_for_new_business();

-- Enable the trigger
ALTER TABLE public.businesses ENABLE TRIGGER user_creation_trigger;

-- =====================================================
-- CLEANUP: Fix existing data
-- =====================================================
-- For existing businesses, update users.id to match owner_id

DO $$
DECLARE
  business_rec RECORD;
  v_role_id UUID;
  v_full_name TEXT;
BEGIN
  FOR business_rec IN 
    SELECT b.id as business_id, b.owner_id, au.email
    FROM businesses b
    JOIN auth.users au ON au.id = b.owner_id
    LEFT JOIN users u ON u.business_id = b.id
    WHERE u.id IS NULL OR u.id != b.owner_id
  LOOP
    -- Extract full name from email
    v_full_name := INITCAP(
      REPLACE(REPLACE(SPLIT_PART(business_rec.email, '@', 1), '.', ' '), '_', ' ')
    );

    -- Get or create Super Admin role
    SELECT id INTO v_role_id
    FROM roles
    WHERE business_id = business_rec.business_id AND name = 'Super Admin';

    IF v_role_id IS NULL THEN
      INSERT INTO roles (business_id, name, permissions)
      VALUES (business_rec.business_id, 'Super Admin', '["all"]'::jsonb)
      RETURNING id INTO v_role_id;
    END IF;

    -- Delete old user record if exists with wrong id
    DELETE FROM users 
    WHERE business_id = business_rec.business_id 
      AND id != business_rec.owner_id;

    -- Insert user with correct id = owner_id
    INSERT INTO users (id, business_id, full_name, email, role_id, is_active)
    VALUES (
      business_rec.owner_id,
      business_rec.business_id,
      v_full_name,
      business_rec.email,
      v_role_id,
      true
    )
    ON CONFLICT (id) DO UPDATE
    SET 
      business_id = EXCLUDED.business_id,
      full_name = EXCLUDED.full_name,
      email = EXCLUDED.email,
      role_id = EXCLUDED.role_id,
      is_active = EXCLUDED.is_active;

    RAISE NOTICE 'Fixed user for business % with owner %', business_rec.business_id, business_rec.owner_id;
  END LOOP;
END $$;

-- =====================================================
-- VERIFY: Check if users.id = owner_id
-- =====================================================
SELECT 
  b.name as business_name,
  b.owner_id,
  u.id as user_id,
  u.email,
  CASE WHEN b.owner_id = u.id THEN '✓ MATCHED' ELSE '✗ MISMATCH' END as status
FROM businesses b
LEFT JOIN users u ON u.business_id = b.id
ORDER BY b.created_at DESC
LIMIT 10;

-- =====================================================
-- DONE!
-- =====================================================
-- After running this SQL:
-- 1. Sign out from your app
-- 2. Sign in again
-- 3. Check Inventory screen - data should now populate!
