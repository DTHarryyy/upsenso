-- =============================================================================
-- Fix: use first name only (from email) when creating the public.users row
--      on new auth sign-ups.
-- Before: full username "john.doe" was stored as-is.
-- After:  only the first segment before any separator is used, title-cased
--         e.g. "john.doe@gmail.com" → "John"
-- =============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
  RETURNS trigger LANGUAGE plpgsql
  SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_username   text;
  v_first_name text;
BEGIN
  -- Extract the local part of the email address (before @)
  v_username := split_part(COALESCE(NEW.email, ''), '@', 1);

  -- Take only the first segment (before any '.', '_', or '-') and title-case it
  -- e.g. "john.doe" → "john" → "John"
  v_first_name := initcap(
    split_part(
      regexp_replace(v_username, '[._\-]', '.', 'g'),
      '.',
      1
    )
  );

  INSERT INTO public.users (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NULLIF(NEW.raw_user_meta_data->>'full_name', ''),
      NULLIF(NEW.raw_user_meta_data->>'name', ''),
      NULLIF(v_first_name, ''),
      v_username
    )
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;
