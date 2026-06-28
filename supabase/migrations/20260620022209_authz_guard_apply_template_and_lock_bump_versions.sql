-- Reconciliation note (2026-06-28): applied to prod on 2026-06-20, captured
-- here verbatim because it was missing from this repo. This is the most
-- important backfilled migration in the Phase 7 reconciliation: without it, a
-- fresh `supabase db reset` would rebuild apply_business_template() with NO
-- caller authorization at all, reopening a cross-tenant privilege-escalation
-- hole (any authenticated user could pass an arbitrary business_id and
-- overwrite that business's roles, permissions, modules, categories, and
-- receipt settings).

-- 1. apply_business_template had NO caller authorization: any authenticated
-- user could pass another business's id and overwrite its roles, permissions,
-- modules, categories and receipt settings. Add an owner/super-admin guard at
-- the top (onboarding creates the business with owner_id = auth.uid() before
-- calling this, so legitimate signup still passes). Body otherwise unchanged.
CREATE OR REPLACE FUNCTION public.apply_business_template(p_business_id uuid, p_template_id uuid, p_branch_id uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_owner_role_id  uuid;
  v_new_role_id    uuid;
  v_role_row       RECORD;
  v_perm_code      text;
  v_perm_id        uuid;
  v_mod_row        RECORD;
  v_mod_id         uuid;
  v_cat_row        RECORD;
  v_paper_size     text := '80mm';
  v_branch_id      uuid;
  v_employee_id    uuid;
BEGIN

  -- Authorization: only the business owner (or a super admin) may apply a
  -- template to a business. Checked first so it doubles as an existence-hiding
  -- guard for businesses the caller doesn't own.
  IF NOT (public.i_am_owner_of(p_business_id) OR public.i_am_super_admin()) THEN
    RAISE EXCEPTION 'Permission denied: only the business owner may apply a template'
      USING ERRCODE = '42501';
  END IF;

  -- 0. Validate inputs
  IF NOT EXISTS (SELECT 1 FROM public.businesses WHERE id = p_business_id) THEN
    RAISE EXCEPTION 'Business % not found', p_business_id USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.business_templates WHERE id = p_template_id) THEN
    RAISE EXCEPTION 'Template % not found', p_template_id USING ERRCODE = '22023';
  END IF;
  IF p_branch_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.branches WHERE id = p_branch_id AND business_id = p_business_id
  ) THEN
    RAISE EXCEPTION 'Branch % does not belong to business %', p_branch_id, p_business_id USING ERRCODE = '22023';
  END IF;

  -- 1. Link template to business
  UPDATE public.businesses
     SET template_id = p_template_id
   WHERE id = p_business_id
     AND template_id IS DISTINCT FROM p_template_id;

  -- 2. Create roles and wire up role_permissions
  FOR v_role_row IN
    SELECT id, role_key, name, level
      FROM public.business_template_roles
     WHERE template_id = p_template_id
     ORDER BY level
  LOOP
    INSERT INTO public.roles (business_id, name, level, is_system)
    VALUES (p_business_id, v_role_row.name, v_role_row.level, true)
    ON CONFLICT (business_id, name) DO UPDATE
      SET level = EXCLUDED.level, is_system = true
    RETURNING id INTO v_new_role_id;

    IF v_role_row.level = 1 THEN
      v_owner_role_id := v_new_role_id;
    END IF;

    -- Seed role_permissions from template
    FOR v_perm_code IN
      SELECT permission_code
        FROM public.business_template_role_permissions
       WHERE template_role_id = v_role_row.id AND is_granted = true
    LOOP
      SELECT id INTO v_perm_id FROM public.permissions WHERE code = v_perm_code;
      IF v_perm_id IS NOT NULL THEN
        INSERT INTO public.role_permissions (role_id, permission_id, allowed)
        VALUES (v_new_role_id, v_perm_id, true)
        ON CONFLICT (role_id, permission_id) DO UPDATE SET allowed = true;
      END IF;
    END LOOP;
  END LOOP;

  -- 3. Enable modules (resolve module_code → module_id via modules table)
  FOR v_mod_row IN
    SELECT module_code
      FROM public.business_template_modules
     WHERE template_id = p_template_id
     ORDER BY sort_order
  LOOP
    SELECT id INTO v_mod_id FROM public.modules WHERE code = v_mod_row.module_code;
    IF v_mod_id IS NOT NULL THEN
      INSERT INTO public.business_modules (business_id, module_id, enabled)
      VALUES (p_business_id, v_mod_id, true)
      ON CONFLICT (business_id, module_id) DO UPDATE SET enabled = true;
    END IF;
  END LOOP;

  -- 4. Seed categories (no sort_order column in categories table)
  FOR v_cat_row IN
    SELECT name
      FROM public.business_template_categories
     WHERE template_id = p_template_id
     ORDER BY sort_order
  LOOP
    INSERT INTO public.categories (id, business_id, name)
    VALUES (gen_random_uuid(), p_business_id, v_cat_row.name)
    ON CONFLICT (business_id, name) DO NOTHING;
  END LOOP;

  -- 5. Read paper size from template settings
  SELECT setting_value #>> '{}'
    INTO v_paper_size
    FROM public.business_template_settings
   WHERE template_id = p_template_id AND setting_key = 'receipt.paper_size';
  v_paper_size := COALESCE(v_paper_size, '80mm');

  -- 6. Initialise receipt_settings (only columns that exist)
  INSERT INTO public.receipt_settings (id, business_id, show_logo, show_tax, paper_size)
  VALUES (gen_random_uuid(), p_business_id, false, false, v_paper_size)
  ON CONFLICT (business_id) DO NOTHING;

  -- 7. Audit log (use actual columns: employee_id, action, entity_type, entity_id)
  SELECT id INTO v_branch_id FROM public.branches
   WHERE business_id = p_business_id LIMIT 1;
  v_branch_id := COALESCE(p_branch_id, v_branch_id);

  SELECT id INTO v_employee_id FROM public.employees
   WHERE auth_user_id = auth.uid() OR user_id = auth.uid() LIMIT 1;

  IF auth.uid() IS NOT NULL THEN
    INSERT INTO public.audit_logs (
      business_id, employee_id, action, entity_type, entity_id, metadata
    ) VALUES (
      p_business_id,
      v_employee_id,
      'template_applied',
      'business',
      p_business_id,
      jsonb_build_object(
        'template_id',       p_template_id,
        'roles_created',     (SELECT count(*) FROM public.business_template_roles WHERE template_id = p_template_id),
        'categories_seeded', (SELECT count(*) FROM public.business_template_categories WHERE template_id = p_template_id)
      )
    );
  END IF;

  RETURN v_owner_role_id;
END;
$function$;

-- 2. bump_versions_* are invoked only by triggers (trg_fn_module_changed,
-- trg_fn_role_perm_changed); the app never calls them. Remove direct EXECUTE so
-- a signed-in user can't force permission-cache churn for an arbitrary business
-- or role. Triggers still fire (SECURITY DEFINER, owned by postgres).
-- Rollback: GRANT EXECUTE ON FUNCTION ... TO authenticated.
REVOKE EXECUTE ON FUNCTION public.bump_versions_for_business(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.bump_versions_for_role(uuid) FROM PUBLIC, anon, authenticated;
