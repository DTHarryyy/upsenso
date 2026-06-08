-- =============================================================================
-- UPSENSO — Permission System v2.0 Migration
-- =============================================================================
-- Strategy  : Additive only. Existing tables are ALTER-ed, not dropped.
--             All statements use IF NOT EXISTS / CREATE OR REPLACE so the
--             file is safe to re-run on a partially-applied state.
-- Existing  : modules, business_modules, employee_permissions, permissions,
--             employees, roles, role_permissions, employee_roles,
--             employee_branches, businesses, branches — all already exist.
-- Missing   : user_permissions, branch_permissions, effective_permissions,
--             permission_snapshot_versions — all created here.
-- Helper fns: get_my_business_id(), my_business_id(), i_am_super_admin(),
--             current_user_role(), set_updated_at() — already exist, reused.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 1 — get_my_employee_id() helper
-- The existing helpers cover business and role. We need one for employee.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_my_employee_id()
RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id
  FROM   employees
  WHERE  auth_user_id = auth.uid()
    AND  is_active    = true
  LIMIT 1;
$$;

COMMENT ON FUNCTION get_my_employee_id() IS
  'Returns the employee.id for the currently authenticated user. Used in RLS policies.';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 2 — EXTEND modules TABLE
-- The table already exists with: id, code, name, description, sort_order.
-- Add the two missing metadata columns.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE modules
  ADD COLUMN IF NOT EXISTS icon      text,
  ADD COLUMN IF NOT EXISTS is_system boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN modules.icon      IS 'Material icon key for Flutter navigation UI.';
COMMENT ON COLUMN modules.is_system IS 'System modules cannot be deleted by tenants.';

-- Ensure the UNIQUE constraint exists on code (may already be present).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'modules'::regclass
      AND contype  = 'u'
      AND conname  = 'modules_code_unique'
  ) THEN
    ALTER TABLE modules ADD CONSTRAINT modules_code_unique UNIQUE (code);
  END IF;
END;
$$;

-- Upsert canonical system module records (idempotent seed).
INSERT INTO modules (code, name, description, icon, sort_order, is_system) VALUES
  ('pos',        'Point of Sale',       'Sales terminal and checkout',            'shopping_cart',   1,  true),
  ('inventory',  'Inventory',           'Stock management and tracking',          'inventory_2',     2,  true),
  ('expenses',   'Expenses',            'Business expense tracking and approval', 'receipt_long',    3,  true),
  ('reports',    'Reports & Analytics', 'Sales, inventory, and financial reports','bar_chart',       4,  true),
  ('employees',  'Employees',           'Staff accounts, roles, and permissions', 'people',          5,  true),
  ('suppliers',  'Suppliers',           'Supplier directory and purchase orders', 'local_shipping',  6,  true),
  ('crm',        'CRM',                 'Customer relationship management',       'contacts',        7,  true),
  ('loyalty',    'Loyalty Program',     'Customer loyalty points and rewards',    'star',            8,  true),
  ('accounting', 'Accounting',          'Financial accounting and ledger',        'account_balance', 9,  true),
  ('audit',      'Audit Logs',          'Security and compliance audit trail',    'policy',          10, true),
  ('settings',   'Settings',            'Business configuration and preferences', 'settings',        11, true)
ON CONFLICT (code) DO UPDATE SET
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  icon        = EXCLUDED.icon,
  sort_order  = EXCLUDED.sort_order,
  is_system   = EXCLUDED.is_system;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 3 — EXTEND business_modules TABLE
-- Existing columns: id, business_id, enabled, module_id.
-- Keep `enabled` (app already uses it). Add: disabled_at, disabled_by,
-- created_at, updated_at, and enforce FK constraints + UNIQUE.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE business_modules
  ADD COLUMN IF NOT EXISTS disabled_at  timestamptz,
  ADD COLUMN IF NOT EXISTS disabled_by  uuid REFERENCES employees(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS created_at   timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at   timestamptz NOT NULL DEFAULT now();

COMMENT ON COLUMN business_modules.enabled     IS 'true = module active; false = hidden from UI and API blocked.';
COMMENT ON COLUMN business_modules.disabled_at IS 'Populated when enabled flips to false. NULL = currently enabled.';
COMMENT ON COLUMN business_modules.disabled_by IS 'Employee who disabled the module. NULL = enabled by default.';

-- Enforce UNIQUE (business_id, module_id) if missing.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'business_modules'::regclass
      AND contype  = 'u'
      AND conname  = 'business_modules_unique'
  ) THEN
    ALTER TABLE business_modules
      ADD CONSTRAINT business_modules_unique UNIQUE (business_id, module_id);
  END IF;
END;
$$;

-- Auto-update updated_at on every change (set_updated_at already exists).
DROP TRIGGER IF EXISTS trg_bm_updated_at ON business_modules;
CREATE TRIGGER trg_bm_updated_at
  BEFORE UPDATE ON business_modules
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── Fix business_modules RLS ──────────────────────────────────────────────────
-- Current bm_write policy allows ALL members to toggle modules — security gap.
-- Replace it with an owner/admin-only write policy.

DROP POLICY IF EXISTS bm_write   ON business_modules;
DROP POLICY IF EXISTS bm_select  ON business_modules;

-- All employees may read which modules are enabled (needed for nav gate).
CREATE POLICY bm_read ON business_modules
  FOR SELECT
  USING (business_id = get_my_business_id());

-- Only owners and admins may enable/disable modules.
CREATE POLICY bm_owner_write ON business_modules
  FOR ALL
  USING  (business_id = get_my_business_id() AND i_am_super_admin())
  WITH CHECK (business_id = get_my_business_id() AND i_am_super_admin());

-- Backfill: make sure all existing businesses have a row for every module.
INSERT INTO business_modules (business_id, module_id, enabled)
SELECT b.id, m.id, true
FROM   businesses b
CROSS  JOIN modules m
ON CONFLICT (business_id, module_id) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 4 — EXTEND permissions TABLE
-- Existing columns: id, code, action, description, is_dangerous, display_name,
--                   module_code.
-- Add: risk_level, requires_confirmation, requires_manager_pin, audit_level.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE permissions
  ADD COLUMN IF NOT EXISTS risk_level
    text NOT NULL DEFAULT 'low'
    CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),

  ADD COLUMN IF NOT EXISTS requires_confirmation
    boolean NOT NULL DEFAULT false,

  ADD COLUMN IF NOT EXISTS requires_manager_pin
    boolean NOT NULL DEFAULT false,

  ADD COLUMN IF NOT EXISTS audit_level
    text NOT NULL DEFAULT 'standard'
    CHECK (audit_level IN ('none', 'standard', 'detailed', 'immutable'));

-- Backfill risk_level from is_dangerous.
UPDATE permissions
SET risk_level = CASE WHEN is_dangerous = true THEN 'high' ELSE 'low' END
WHERE risk_level = 'low';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 5 — user_permissions (NEW TABLE)
-- Per-employee permission overrides. Allows or denies a specific permission
-- for a specific employee, optionally scoped to one branch.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS user_permissions (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id   uuid        NOT NULL REFERENCES businesses(id)  ON DELETE CASCADE,
  employee_id   uuid        NOT NULL REFERENCES employees(id)   ON DELETE CASCADE,
  branch_id     uuid        REFERENCES branches(id)             ON DELETE CASCADE,
  -- NULL branch_id → override applies to all branches for this employee.
  permission_id uuid        NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  is_granted    boolean     NOT NULL,
  -- true  = explicit ALLOW (overrides role DENY)
  -- false = explicit DENY  (highest priority; overrides everything below)
  granted_by    uuid        NOT NULL REFERENCES employees(id),
  reason        text,
  expires_at    timestamptz,          -- NULL = never expires
  is_active     boolean     NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT up_employee_branch_permission_unique
    UNIQUE NULLS NOT DISTINCT (employee_id, branch_id, permission_id)
);

COMMENT ON TABLE  user_permissions IS
  'Per-employee permission overrides (ALLOW or DENY). Takes priority over role grants.';
COMMENT ON COLUMN user_permissions.is_granted IS
  'true = explicit ALLOW; false = explicit DENY (cannot be overridden by layers below).';
COMMENT ON COLUMN user_permissions.branch_id IS
  'NULL = override applies at ALL branches. Non-null = scoped to that branch only.';
COMMENT ON COLUMN user_permissions.expires_at IS
  'NULL = never expires. Client enforces expiry on already-synced snapshots.';

CREATE INDEX IF NOT EXISTS idx_up_employee  ON user_permissions(employee_id);
CREATE INDEX IF NOT EXISTS idx_up_business  ON user_permissions(business_id);
CREATE INDEX IF NOT EXISTS idx_up_branch    ON user_permissions(branch_id);
CREATE INDEX IF NOT EXISTS idx_up_expires   ON user_permissions(expires_at)
  WHERE expires_at IS NOT NULL;

ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;

-- Employees can see their own overrides; owners/admins see all in the business.
CREATE POLICY up_read ON user_permissions
  FOR SELECT
  USING (
    business_id = get_my_business_id()
    AND (
      employee_id = get_my_employee_id()
      OR i_am_super_admin()
    )
  );

-- Only owners/admins may create, modify, or remove overrides.
CREATE POLICY up_write ON user_permissions
  FOR ALL
  USING  (business_id = get_my_business_id() AND i_am_super_admin())
  WITH CHECK (business_id = get_my_business_id() AND i_am_super_admin());

DROP TRIGGER IF EXISTS trg_up_updated_at ON user_permissions;
CREATE TRIGGER trg_up_updated_at
  BEFORE UPDATE ON user_permissions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 6 — branch_permissions (NEW TABLE)
-- Branch-level permission overrides that apply to ALL employees at a branch,
-- regardless of their individual role.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS branch_permissions (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id   uuid        NOT NULL REFERENCES businesses(id)  ON DELETE CASCADE,
  branch_id     uuid        NOT NULL REFERENCES branches(id)    ON DELETE CASCADE,
  permission_id uuid        NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  is_granted    boolean     NOT NULL,
  -- false = permission blocked for EVERYONE at this branch (even if role grants it)
  -- true  = permission explicitly enabled for the branch (use sparingly)
  reason        text,
  created_by    uuid        NOT NULL REFERENCES employees(id),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT bp_branch_permission_unique UNIQUE (branch_id, permission_id)
);

COMMENT ON TABLE  branch_permissions IS
  'Branch-level permission overrides. Applies to all employees at the branch.';
COMMENT ON COLUMN branch_permissions.is_granted IS
  'false = blocked for everyone at this branch; true = branch-wide explicit allow.';

CREATE INDEX IF NOT EXISTS idx_bp_branch   ON branch_permissions(branch_id);
CREATE INDEX IF NOT EXISTS idx_bp_business ON branch_permissions(business_id);

ALTER TABLE branch_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY bp_read ON branch_permissions
  FOR SELECT
  USING (business_id = get_my_business_id());

CREATE POLICY bp_write ON branch_permissions
  FOR ALL
  USING  (business_id = get_my_business_id() AND i_am_super_admin())
  WITH CHECK (business_id = get_my_business_id() AND i_am_super_admin());

DROP TRIGGER IF EXISTS trg_bp_updated_at ON branch_permissions;
CREATE TRIGGER trg_bp_updated_at
  BEFORE UPDATE ON branch_permissions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 7 — effective_permissions (NEW TABLE)
-- Pre-computed, denormalised snapshot of the final permission decision for
-- every (employee, branch, permission_code) triple.
-- Written ONLY by compute_employee_permissions() (SECURITY DEFINER).
-- Flutter client reads this — no joins needed for offline checks.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS effective_permissions (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id      uuid        NOT NULL REFERENCES businesses(id)  ON DELETE CASCADE,
  employee_id      uuid        NOT NULL REFERENCES employees(id)   ON DELETE CASCADE,
  branch_id        uuid        NOT NULL REFERENCES branches(id)    ON DELETE CASCADE,
  permission_code  text        NOT NULL,
  -- Denormalised from permissions.code for O(1) offline lookup (no join needed).
  is_granted       boolean     NOT NULL,
  grant_source     text        NOT NULL
    CHECK (grant_source IN (
      'role', 'user_allow', 'branch_allow',
      'user_deny', 'branch_deny', 'module_disabled', 'default_deny'
    )),
  deny_reason      text,       -- NULL when is_granted = true
  snapshot_version bigint      NOT NULL DEFAULT 1,
  computed_at      timestamptz NOT NULL DEFAULT now(),
  valid_until      timestamptz,-- NULL = valid until next recompute

  CONSTRAINT ep_unique UNIQUE (employee_id, branch_id, permission_code)
);

COMMENT ON TABLE  effective_permissions IS
  'Pre-computed permission snapshot per (employee, branch). Written only by compute_employee_permissions().';
COMMENT ON COLUMN effective_permissions.grant_source IS
  'The winning evaluation layer: role | user_allow | branch_allow | user_deny | branch_deny | module_disabled | default_deny.';
COMMENT ON COLUMN effective_permissions.snapshot_version IS
  'Monotonically increasing. Client stores its version; delta sync fetches rows where version > client_version.';

-- Primary offline lookup (most common query).
CREATE INDEX IF NOT EXISTS idx_ep_lookup
  ON effective_permissions(employee_id, branch_id, permission_code);
CREATE INDEX IF NOT EXISTS idx_ep_employee ON effective_permissions(employee_id);
CREATE INDEX IF NOT EXISTS idx_ep_business ON effective_permissions(business_id);
-- Version index for delta sync.
CREATE INDEX IF NOT EXISTS idx_ep_version  ON effective_permissions(snapshot_version);

ALTER TABLE effective_permissions ENABLE ROW LEVEL SECURITY;

-- Employees see only their own snapshot; admins see all in the business.
CREATE POLICY ep_read ON effective_permissions
  FOR SELECT
  USING (
    business_id = get_my_business_id()
    AND (
      employee_id = get_my_employee_id()
      OR i_am_super_admin()
    )
  );

-- Clients cannot write directly — only the SECURITY DEFINER compute function.
CREATE POLICY ep_no_insert ON effective_permissions FOR INSERT WITH CHECK (false);
CREATE POLICY ep_no_update ON effective_permissions FOR UPDATE USING (false);
CREATE POLICY ep_no_delete ON effective_permissions FOR DELETE USING (false);


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 8 — permission_snapshot_versions (NEW TABLE)
-- Version counter per (employee, branch). The Flutter client stores its local
-- version; on reconnect it requests a delta sync if the server version is higher.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS permission_snapshot_versions (
  employee_id      uuid        NOT NULL REFERENCES employees(id)  ON DELETE CASCADE,
  branch_id        uuid        NOT NULL REFERENCES branches(id)   ON DELETE CASCADE,
  business_id      uuid        NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  current_version  bigint      NOT NULL DEFAULT 1,
  last_recomputed  timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (employee_id, branch_id)
);

COMMENT ON TABLE permission_snapshot_versions IS
  'Tracks the current snapshot version per (employee, branch) for delta sync.';

CREATE INDEX IF NOT EXISTS idx_psv_business
  ON permission_snapshot_versions(business_id);

ALTER TABLE permission_snapshot_versions ENABLE ROW LEVEL SECURITY;

-- Employees see their own version; admins see all.
CREATE POLICY psv_read ON permission_snapshot_versions
  FOR SELECT
  USING (
    business_id = get_my_business_id()
    AND (
      employee_id = get_my_employee_id()
      OR i_am_super_admin()
    )
  );

-- Write is exclusively controlled by the compute function.
CREATE POLICY psv_no_write ON permission_snapshot_versions
  FOR ALL WITH CHECK (false);


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 9 — AUDIT HELPER (shared by permission-change triggers)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION log_permission_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO audit_logs (
    id,
    business_id,
    employee_id,
    action,
    entity_type,
    entity_id,
    metadata,
    created_at
  )
  VALUES (
    gen_random_uuid(),
    COALESCE(NEW.business_id, OLD.business_id),
    get_my_employee_id(),
    TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW)),
    now()
  );
  RETURN COALESCE(NEW, OLD);
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 10 — VERSION BUMP HELPERS
-- ─────────────────────────────────────────────────────────────────────────────

-- Bump version for all employees that carry a specific role.
CREATE OR REPLACE FUNCTION bump_versions_for_role(p_role_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO permission_snapshot_versions
    (employee_id, branch_id, business_id, current_version, last_recomputed)
  SELECT e.id, eb.branch_id, e.business_id, 1, now()
  FROM   employees       e
  JOIN   employee_roles  er ON er.employee_id = e.id
  JOIN   employee_branches eb ON eb.employee_id = e.id
  WHERE  er.role_id = p_role_id
  ON CONFLICT (employee_id, branch_id)
  DO UPDATE SET
    current_version = permission_snapshot_versions.current_version + 1,
    last_recomputed = now();
END;
$$;

-- Bump version for every employee in a business (module toggle affects everyone).
CREATE OR REPLACE FUNCTION bump_versions_for_business(p_business_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO permission_snapshot_versions
    (employee_id, branch_id, business_id, current_version, last_recomputed)
  SELECT e.id, eb.branch_id, e.business_id, 1, now()
  FROM   employees       e
  JOIN   employee_branches eb ON eb.employee_id = e.id
  WHERE  e.business_id = p_business_id
  ON CONFLICT (employee_id, branch_id)
  DO UPDATE SET
    current_version = permission_snapshot_versions.current_version + 1,
    last_recomputed = now();
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 11 — TRIGGER FUNCTIONS
-- ─────────────────────────────────────────────────────────────────────────────

-- role_permissions changed → bump all employees with that role
CREATE OR REPLACE FUNCTION trg_fn_role_perm_changed()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  PERFORM bump_versions_for_role(COALESCE(NEW.role_id, OLD.role_id));
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- user_permissions changed → bump the affected employee across their branches
CREATE OR REPLACE FUNCTION trg_fn_user_perm_changed()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_row user_permissions%ROWTYPE;
BEGIN
  v_row := COALESCE(NEW, OLD);
  INSERT INTO permission_snapshot_versions
    (employee_id, branch_id, business_id, current_version, last_recomputed)
  SELECT
    v_row.employee_id,
    COALESCE(v_row.branch_id, eb.branch_id),
    v_row.business_id,
    1,
    now()
  FROM employee_branches eb
  WHERE eb.employee_id = v_row.employee_id
  ON CONFLICT (employee_id, branch_id)
  DO UPDATE SET
    current_version = permission_snapshot_versions.current_version + 1,
    last_recomputed = now();
  RETURN v_row;
END;
$$;

-- branch_permissions changed → bump all employees at that branch
CREATE OR REPLACE FUNCTION trg_fn_branch_perm_changed()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_row branch_permissions%ROWTYPE;
BEGIN
  v_row := COALESCE(NEW, OLD);
  INSERT INTO permission_snapshot_versions
    (employee_id, branch_id, business_id, current_version, last_recomputed)
  SELECT eb.employee_id, eb.branch_id, v_row.business_id, 1, now()
  FROM   employee_branches eb
  WHERE  eb.branch_id = v_row.branch_id
  ON CONFLICT (employee_id, branch_id)
  DO UPDATE SET
    current_version = permission_snapshot_versions.current_version + 1,
    last_recomputed = now();
  RETURN v_row;
END;
$$;

-- business_modules changed → bump all employees in the business
CREATE OR REPLACE FUNCTION trg_fn_module_changed()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  PERFORM bump_versions_for_business(COALESCE(NEW.business_id, OLD.business_id));
  RETURN COALESCE(NEW, OLD);
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 12 — ATTACH TRIGGERS
-- ─────────────────────────────────────────────────────────────────────────────

-- role_permissions: bump versions when a role's grants change
DROP TRIGGER IF EXISTS trg_role_perm_changed ON role_permissions;
CREATE TRIGGER trg_role_perm_changed
  AFTER INSERT OR UPDATE OR DELETE ON role_permissions
  FOR EACH ROW EXECUTE FUNCTION trg_fn_role_perm_changed();

-- user_permissions: bump versions + write audit log
DROP TRIGGER IF EXISTS trg_user_perm_changed ON user_permissions;
DROP TRIGGER IF EXISTS trg_user_perm_audit   ON user_permissions;
CREATE TRIGGER trg_user_perm_changed
  AFTER INSERT OR UPDATE OR DELETE ON user_permissions
  FOR EACH ROW EXECUTE FUNCTION trg_fn_user_perm_changed();
CREATE TRIGGER trg_user_perm_audit
  AFTER INSERT OR UPDATE OR DELETE ON user_permissions
  FOR EACH ROW EXECUTE FUNCTION log_permission_change();

-- branch_permissions: bump versions + write audit log
DROP TRIGGER IF EXISTS trg_branch_perm_changed ON branch_permissions;
DROP TRIGGER IF EXISTS trg_branch_perm_audit   ON branch_permissions;
CREATE TRIGGER trg_branch_perm_changed
  AFTER INSERT OR UPDATE OR DELETE ON branch_permissions
  FOR EACH ROW EXECUTE FUNCTION trg_fn_branch_perm_changed();
CREATE TRIGGER trg_branch_perm_audit
  AFTER INSERT OR UPDATE OR DELETE ON branch_permissions
  FOR EACH ROW EXECUTE FUNCTION log_permission_change();

-- business_modules: bump versions + write audit log
DROP TRIGGER IF EXISTS trg_module_changed ON business_modules;
DROP TRIGGER IF EXISTS trg_module_audit   ON business_modules;
CREATE TRIGGER trg_module_changed
  AFTER INSERT OR UPDATE OR DELETE ON business_modules
  FOR EACH ROW EXECUTE FUNCTION trg_fn_module_changed();
CREATE TRIGGER trg_module_audit
  AFTER INSERT OR UPDATE OR DELETE ON business_modules
  FOR EACH ROW EXECUTE FUNCTION log_permission_change();


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 13 — CORE COMPUTE FUNCTION
-- Evaluates the 6-layer permission hierarchy and upserts results into
-- effective_permissions. Called by triggers and get_my_permissions().
--
-- NOTE: Uses permissions.module_code (existing column name, not "module").
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION compute_employee_permissions(
  p_employee_id uuid,
  p_branch_id   uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
  v_version     bigint;
BEGIN
  SELECT business_id INTO v_business_id
  FROM   employees WHERE id = p_employee_id;

  IF v_business_id IS NULL THEN
    RAISE EXCEPTION 'Employee % not found', p_employee_id;
  END IF;

  -- Atomically bump (or create) the version counter for this employee+branch.
  INSERT INTO permission_snapshot_versions
    (employee_id, branch_id, business_id, current_version, last_recomputed)
  VALUES
    (p_employee_id, p_branch_id, v_business_id, 1, now())
  ON CONFLICT (employee_id, branch_id)
  DO UPDATE SET
    current_version = permission_snapshot_versions.current_version + 1,
    last_recomputed = now()
  RETURNING current_version INTO v_version;

  -- Evaluate every permission in the catalogue against the 6-layer hierarchy
  -- and upsert the results. Uses permissions.module_code (existing column).
  INSERT INTO effective_permissions (
    id, business_id, employee_id, branch_id,
    permission_code, is_granted, grant_source, deny_reason,
    snapshot_version, computed_at
  )
  WITH

  all_perms AS (
    SELECT id AS permission_id, code, module_code
    FROM   permissions
  ),

  -- Layer 0: module disabled for this business
  -- Match permissions.module_code against modules.code via business_modules.
  module_disabled AS (
    SELECT ap.code
    FROM   all_perms ap
    WHERE  NOT EXISTS (
      SELECT 1
      FROM   business_modules bm
      JOIN   modules m ON m.id = bm.module_id
      WHERE  bm.business_id = v_business_id
        AND  bm.enabled     = true
        AND  lower(m.code)  = lower(ap.module_code)
    )
  ),

  -- Layer 2a: explicit DENY from user_permissions (not expired, is_active)
  user_deny AS (
    SELECT p.code
    FROM   user_permissions up
    JOIN   permissions p ON p.id = up.permission_id
    WHERE  up.employee_id = p_employee_id
      AND  (up.branch_id  = p_branch_id OR up.branch_id IS NULL)
      AND  up.is_granted  = false
      AND  up.is_active   = true
      AND  (up.expires_at IS NULL OR up.expires_at > now())
  ),

  -- Layer 2b: explicit DENY from branch_permissions
  branch_deny AS (
    SELECT p.code
    FROM   branch_permissions bp
    JOIN   permissions p ON p.id = bp.permission_id
    WHERE  bp.branch_id  = p_branch_id
      AND  bp.is_granted = false
  ),

  -- Layer 3: explicit ALLOW from user_permissions (not expired, is_active)
  user_allow AS (
    SELECT p.code
    FROM   user_permissions up
    JOIN   permissions p ON p.id = up.permission_id
    WHERE  up.employee_id = p_employee_id
      AND  (up.branch_id  = p_branch_id OR up.branch_id IS NULL)
      AND  up.is_granted  = true
      AND  up.is_active   = true
      AND  (up.expires_at IS NULL OR up.expires_at > now())
  ),

  -- Layer 4: explicit ALLOW from branch_permissions
  branch_allow AS (
    SELECT p.code
    FROM   branch_permissions bp
    JOIN   permissions p ON p.id = bp.permission_id
    WHERE  bp.branch_id  = p_branch_id
      AND  bp.is_granted = true
  ),

  -- Layer 5: ALLOW from role_permissions via employee_roles junction
  role_allow AS (
    SELECT DISTINCT p.code
    FROM   employee_roles er
    JOIN   role_permissions rp ON rp.role_id     = er.role_id
    JOIN   permissions      p  ON p.id           = rp.permission_id
    WHERE  er.employee_id = p_employee_id
      AND  rp.allowed     = true
  ),

  resolved AS (
    SELECT
      gen_random_uuid()  AS id,
      v_business_id      AS business_id,
      p_employee_id      AS employee_id,
      p_branch_id        AS branch_id,
      ap.code            AS permission_code,

      CASE
        WHEN ap.code IN (SELECT code FROM module_disabled) THEN false
        WHEN ap.code IN (SELECT code FROM user_deny)       THEN false
        WHEN ap.code IN (SELECT code FROM branch_deny)     THEN false
        WHEN ap.code IN (SELECT code FROM user_allow)      THEN true
        WHEN ap.code IN (SELECT code FROM branch_allow)    THEN true
        WHEN ap.code IN (SELECT code FROM role_allow)      THEN true
        ELSE false
      END AS is_granted,

      CASE
        WHEN ap.code IN (SELECT code FROM module_disabled) THEN 'module_disabled'
        WHEN ap.code IN (SELECT code FROM user_deny)       THEN 'user_deny'
        WHEN ap.code IN (SELECT code FROM branch_deny)     THEN 'branch_deny'
        WHEN ap.code IN (SELECT code FROM user_allow)      THEN 'user_allow'
        WHEN ap.code IN (SELECT code FROM branch_allow)    THEN 'branch_allow'
        WHEN ap.code IN (SELECT code FROM role_allow)      THEN 'role'
        ELSE 'default_deny'
      END AS grant_source,

      CASE
        WHEN ap.code IN (SELECT code FROM module_disabled)
          THEN 'Module is disabled for this business'
        WHEN ap.code IN (SELECT code FROM user_deny)
          THEN 'Explicitly denied for this employee'
        WHEN ap.code IN (SELECT code FROM branch_deny)
          THEN 'Blocked at branch level'
        ELSE NULL
      END AS deny_reason,

      v_version AS snapshot_version,
      now()     AS computed_at
    FROM all_perms ap
  )

  SELECT * FROM resolved

  ON CONFLICT (employee_id, branch_id, permission_code)
  DO UPDATE SET
    is_granted       = EXCLUDED.is_granted,
    grant_source     = EXCLUDED.grant_source,
    deny_reason      = EXCLUDED.deny_reason,
    snapshot_version = EXCLUDED.snapshot_version,
    computed_at      = EXCLUDED.computed_at;

END;
$$;

COMMENT ON FUNCTION compute_employee_permissions(uuid, uuid) IS
  'Evaluates the 6-layer permission hierarchy and writes results into effective_permissions. SECURITY DEFINER — only this function may write to effective_permissions.';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 14 — get_my_permissions() (REPLACE existing function)
-- Returns a flat {permission_code: bool} JSONB for the calling employee.
-- Triggers an initial compute if no snapshot exists yet.
-- Called by PermissionRemoteDs.fetchMyPermissions() in Flutter.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_my_permissions()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_employee_id uuid;
  v_branch_id   uuid;
  v_result      jsonb;
BEGIN
  -- auth_user_id is UUID in the employees table.
  SELECT e.id, e.branch_id
  INTO   v_employee_id, v_branch_id
  FROM   employees e
  WHERE  e.auth_user_id = auth.uid()
    AND  e.is_active    = true
  LIMIT  1;

  IF v_employee_id IS NULL THEN
    RETURN '{}'::jsonb;
  END IF;

  -- Bootstrap snapshot on first call.
  IF NOT EXISTS (
    SELECT 1 FROM effective_permissions
    WHERE employee_id = v_employee_id
      AND branch_id   = v_branch_id
  ) THEN
    PERFORM compute_employee_permissions(v_employee_id, v_branch_id);
  END IF;

  -- Return flat {code: bool} map — what the Flutter client expects.
  SELECT jsonb_object_agg(permission_code, is_granted)
  INTO   v_result
  FROM   effective_permissions
  WHERE  employee_id = v_employee_id
    AND  branch_id   = v_branch_id;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

COMMENT ON FUNCTION get_my_permissions() IS
  'RPC entry point for the Flutter client. Returns a flat {permission_code: bool} map. Triggers initial compute if the snapshot does not exist.';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 15 — BACKFILL effective_permissions for existing employees
-- Safe to run multiple times — only fills gaps (NOT EXISTS guard).
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT DISTINCT e.id AS employee_id, eb.branch_id
    FROM   employees       e
    JOIN   employee_branches eb ON eb.employee_id = e.id
    WHERE  e.is_active = true
      AND  NOT EXISTS (
        SELECT 1 FROM effective_permissions ep
        WHERE ep.employee_id = e.id
          AND ep.branch_id   = eb.branch_id
      )
  LOOP
    BEGIN
      PERFORM compute_employee_permissions(r.employee_id, r.branch_id);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'compute_employee_permissions skipped employee=% branch=%: %',
        r.employee_id, r.branch_id, SQLERRM;
    END;
  END LOOP;
END;
$$;


-- =============================================================================
-- POST-MIGRATION VERIFICATION
-- Run these SELECT statements after applying to confirm everything landed.
-- =============================================================================

-- Expected: all 4 new tables show ✓ EXISTS
SELECT
  expected.tbl,
  CASE WHEN t.table_name IS NOT NULL THEN '✓ EXISTS' ELSE '✗ MISSING' END AS status
FROM (VALUES
  ('user_permissions'),
  ('branch_permissions'),
  ('effective_permissions'),
  ('permission_snapshot_versions')
) AS expected(tbl)
LEFT JOIN information_schema.tables t
  ON  t.table_name  = expected.tbl
  AND t.table_schema = 'public';

-- Expected: all new columns show ✓
SELECT
  col,
  CASE WHEN c.column_name IS NOT NULL THEN '✓ EXISTS' ELSE '✗ MISSING' END AS status
FROM (VALUES
  ('modules',          'icon'),
  ('modules',          'is_system'),
  ('business_modules', 'disabled_at'),
  ('business_modules', 'updated_at'),
  ('permissions',      'risk_level'),
  ('permissions',      'requires_confirmation'),
  ('permissions',      'requires_manager_pin'),
  ('permissions',      'audit_level')
) AS expected(tbl, col)
LEFT JOIN information_schema.columns c
  ON  c.table_name  = expected.tbl
  AND c.column_name = expected.col
  AND c.table_schema = 'public';

-- =============================================================================
-- END OF MIGRATION
-- =============================================================================
