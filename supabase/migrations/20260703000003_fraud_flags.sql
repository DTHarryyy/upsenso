-- =============================================================================
-- M1 Phase 2 — fraud_flags table + RLS + the fraud.* permission seeds.
--
-- The on-device FraudDetectionEngine writes flags locally (Drift) and syncs
-- them here. Flags are LEADS whose evidence is the linked records — they are
-- append-mostly: INSERT tenant-scoped, UPDATE restricted to triage fields by
-- BOTH policy and a freeze trigger, DELETE denied entirely (soft-delete only).
--
-- Insider-hardening decisions encoded here (see the M1 hardened plan):
--   • Self-resolution block: has_permission('fraud.resolve') alone is not
--     enough to UPDATE — the caller must not be the flag's implicated
--     subject (subject_user_id stores auth.uid()::text, same id space as
--     transactions.cashier_id / refunds.refunded_by). Owner is exempt.
--   • Branch scoping: non-owners only see/resolve their own branches' flags
--     (my_branch_ids() / can_read_all_branches(), the 20260627000014
--     pattern). NULL-branch flags (business-wide, e.g. AUDIT_TAMPER) are
--     owner-only.
--   • Evidence rewrite block (T10): a BEFORE UPDATE trigger freezes every
--     forensic column — only status / resolved_by / resolution_note /
--     deleted_at / client_updated_at may change.
--   • Permission codes seeded HERE (permissions + role_permissions +
--     business_template_role_permissions + recompute) — the exact missing
--     step that broke CRM/recipes/procurement three times before.
--
-- Role grants mirror the client matrices exactly:
--   Business Owner  → fraud.view, fraud.resolve, nav.fraud
--   Branch Manager  → fraud.view, fraud.resolve, nav.fraud
--   Cashier         → none
--   Inventory Staff → none
--
-- ROLLBACK (note: prod's fraud_flags predates this migration — an empty
-- AI_CONTEXT-era scaffold that this migration adopts in place; roll back the
-- ADDED pieces, don't drop the table):
--   DROP TRIGGER IF EXISTS trg_fraud_flags_freeze ON public.fraud_flags;
--   DROP FUNCTION IF EXISTS public.fraud_flags_freeze_immutable();
--   DROP POLICY IF EXISTS fraud_flags_select ON public.fraud_flags;
--   DROP POLICY IF EXISTS fraud_flags_select_branch_scope ON public.fraud_flags;
--   DROP POLICY IF EXISTS fraud_flags_insert ON public.fraud_flags;
--   DROP POLICY IF EXISTS fraud_flags_update ON public.fraud_flags;
--   DROP INDEX IF EXISTS public.ux_fraud_flags_dedupe;
--   DROP INDEX IF EXISTS public.idx_fraud_flags_business_status;
--   ALTER TABLE public.fraud_flags
--     DROP COLUMN IF EXISTS branch_id, DROP COLUMN IF EXISTS status,
--     DROP COLUMN IF EXISTS title, DROP COLUMN IF EXISTS subject_user_id,
--     DROP COLUMN IF EXISTS evidence, DROP COLUMN IF EXISTS related_ids,
--     DROP COLUMN IF EXISTS resolved_by, DROP COLUMN IF EXISTS resolution_note,
--     DROP COLUMN IF EXISTS detected_at, DROP COLUMN IF EXISTS updated_at,
--     DROP COLUMN IF EXISTS client_updated_at, DROP COLUMN IF EXISTS deleted_at,
--     DROP COLUMN IF EXISTS dedupe_key;
--   DELETE FROM role_permissions rp USING permissions p
--     WHERE rp.permission_id = p.id
--       AND p.code IN ('fraud.view','fraud.resolve','nav.fraud');
--   DELETE FROM business_template_role_permissions
--     WHERE permission_code IN ('fraud.view','fraud.resolve','nav.fraud');
--   DELETE FROM permissions WHERE code IN ('fraud.view','fraud.resolve','nav.fraud');
-- =============================================================================

-- ── 1. Seed the fraud.* permission codes ────────────────────────────────────
-- module_code 'audit': fraud shares the audit module gate (client
-- _moduleCodeForKey does the same) — no separate toggle an insider can flip.
INSERT INTO permissions (code, action, module_code, display_name, is_dangerous)
SELECT v.code, v.action, v.module_code, v.display_name, false
FROM (VALUES
  ('fraud.view',    'view',     'audit', 'View Fraud Alerts'),
  ('fraud.resolve', 'resolve',  'audit', 'Resolve Fraud Alerts'),
  ('nav.fraud',     'navigate', 'audit', 'Navigate to Fraud Alerts')
) AS v(code, action, module_code, display_name)
WHERE NOT EXISTS (SELECT 1 FROM permissions p WHERE p.code = v.code);

INSERT INTO role_permissions (role_id, permission_id, allowed)
SELECT r.id, p.id, true
FROM   roles r
CROSS  JOIN permissions p
WHERE  r.name IN ('Business Owner', 'Branch Manager')
  AND  p.code IN ('fraud.view', 'fraud.resolve', 'nav.fraud')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Cashier / Inventory Staff intentionally get no fraud.* grant.

INSERT INTO business_template_role_permissions (template_role_id, permission_code, is_granted)
SELECT tr.id, v.code, true
FROM   business_template_roles tr
CROSS  JOIN (VALUES
  ('fraud.view'), ('fraud.resolve'), ('nav.fraud')
) AS v(code)
WHERE  tr.name IN ('Business Owner', 'Branch Manager')
  AND  NOT EXISTS (
    SELECT 1 FROM business_template_role_permissions x
    WHERE x.template_role_id = tr.id AND x.permission_code = v.code
  );

-- ── 2. fraud_flags table ─────────────────────────────────────────────────────
-- NOTE (discovered on apply, 2026-07-03): prod already had an EMPTY
-- AI_CONTEXT-era `fraud_flags` scaffold (id, business_id, employee_id,
-- severity, rule_code, description, resolved, created_at — 0 rows) plus one
-- legacy role-name SELECT policy. Adopted in place, same as audit_logs'
-- previous_hash/hash: CREATE TABLE IF NOT EXISTS covers fresh environments,
-- the ALTERs below bring the legacy shape up to date (safe: table is empty),
-- and the legacy employee_id/resolved columns stay as harmless cruft.
CREATE TABLE IF NOT EXISTS public.fraud_flags (
  id                uuid PRIMARY KEY,
  business_id       uuid NOT NULL REFERENCES public.businesses(id),
  branch_id         uuid REFERENCES public.branches(id),
  rule_code         text NOT NULL,
  severity          text NOT NULL CHECK (severity IN ('low','medium','high','critical')),
  status            text NOT NULL DEFAULT 'new'
                      CHECK (status IN ('new','investigating','resolved','dismissed')),
  title             text NOT NULL,
  description       text NOT NULL,
  -- auth.uid()::text of the implicated employee, matching cashier_id /
  -- refunded_by on the source rows. NULL when no single subject.
  subject_user_id   text,
  evidence          jsonb NOT NULL DEFAULT '{}'::jsonb,
  related_ids       jsonb NOT NULL DEFAULT '[]'::jsonb,
  resolved_by       text,
  resolution_note   text,
  detected_at       timestamptz NOT NULL DEFAULT now(),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  client_updated_at timestamptz,
  deleted_at        timestamptz,
  -- Deterministic per-incident key: re-sweeps and other devices upsert the
  -- same incident instead of duplicating it.
  dedupe_key        text NOT NULL
);

-- Adopt-in-place ALTERs for the legacy scaffold (no-ops on fresh installs).
-- Empty-string defaults on title/dedupe_key exist only so the ADD COLUMN can
-- never fail; the app always writes real values.
ALTER TABLE public.fraud_flags
  ADD COLUMN IF NOT EXISTS branch_id         uuid REFERENCES public.branches(id),
  ADD COLUMN IF NOT EXISTS status            text NOT NULL DEFAULT 'new',
  ADD COLUMN IF NOT EXISTS title             text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS subject_user_id   text,
  ADD COLUMN IF NOT EXISTS evidence          jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS related_ids       jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS resolved_by       text,
  ADD COLUMN IF NOT EXISTS resolution_note   text,
  ADD COLUMN IF NOT EXISTS detected_at       timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at        timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS client_updated_at timestamptz,
  ADD COLUMN IF NOT EXISTS deleted_at        timestamptz,
  ADD COLUMN IF NOT EXISTS dedupe_key        text NOT NULL DEFAULT '';

-- The legacy scaffold predates CHECK constraints; add them idempotently.
DO $$
BEGIN
  ALTER TABLE public.fraud_flags
    ADD CONSTRAINT fraud_flags_severity_check
    CHECK (severity IN ('low','medium','high','critical'));
EXCEPTION WHEN duplicate_object THEN NULL;
END;
$$;
DO $$
BEGIN
  ALTER TABLE public.fraud_flags
    ADD CONSTRAINT fraud_flags_status_check
    CHECK (status IN ('new','investigating','resolved','dismissed'));
EXCEPTION WHEN duplicate_object THEN NULL;
END;
$$;

-- The legacy PERMISSIVE role-name policy would OR past the has_permission
-- gates below — it must not survive.
DROP POLICY IF EXISTS fraud_admin_only ON public.fraud_flags;

CREATE UNIQUE INDEX IF NOT EXISTS ux_fraud_flags_dedupe
  ON public.fraud_flags (business_id, dedupe_key);
CREATE INDEX IF NOT EXISTS idx_fraud_flags_business_status
  ON public.fraud_flags (business_id, status, detected_at DESC);

GRANT SELECT, INSERT, UPDATE ON public.fraud_flags TO authenticated;
-- No DELETE grant, no DELETE policy: flags are never hard-deleted.

-- ── 3. RLS ───────────────────────────────────────────────────────────────────
ALTER TABLE public.fraud_flags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS fraud_flags_select ON public.fraud_flags;
CREATE POLICY fraud_flags_select ON public.fraud_flags
  AS PERMISSIVE FOR SELECT TO authenticated
  USING (
    business_id = get_my_business_id()
    AND has_permission('fraud.view')
  );

-- Branch scoping (RESTRICTIVE, ANDed on top): a Branch Manager must not read
-- another branch's HR-sensitive flags. NULL-branch flags are owner-only.
DROP POLICY IF EXISTS fraud_flags_select_branch_scope ON public.fraud_flags;
CREATE POLICY fraud_flags_select_branch_scope ON public.fraud_flags
  AS RESTRICTIVE FOR SELECT TO authenticated
  USING (
    can_read_all_branches()
    OR (branch_id IS NOT NULL AND branch_id IN (SELECT my_branch_ids()))
  );

-- Any authenticated device in the tenant may INSERT — the engine runs on
-- every device. Flags are leads, not verdicts; fabrication is mitigated by
-- evidence living in the linked records, not prevented here.
DROP POLICY IF EXISTS fraud_flags_insert ON public.fraud_flags;
CREATE POLICY fraud_flags_insert ON public.fraud_flags
  AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (business_id = get_my_business_id());

-- Triage requires fraud.resolve, the caller's branch (or owner), and — the
-- self-resolution block — that the caller is NOT the implicated subject.
DROP POLICY IF EXISTS fraud_flags_update ON public.fraud_flags;
CREATE POLICY fraud_flags_update ON public.fraud_flags
  AS PERMISSIVE FOR UPDATE TO authenticated
  USING (
    business_id = get_my_business_id()
    AND has_permission('fraud.resolve')
    AND (
      can_read_all_branches()
      OR (branch_id IS NOT NULL AND branch_id IN (SELECT my_branch_ids()))
    )
    AND (
      i_am_super_admin()
      OR subject_user_id IS NULL
      OR subject_user_id <> auth.uid()::text
    )
  )
  WITH CHECK (business_id = get_my_business_id());

-- ── 4. Freeze trigger (T10 — evidence rewrite block) ─────────────────────────
CREATE OR REPLACE FUNCTION public.fraud_flags_freeze_immutable()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.business_id     IS DISTINCT FROM OLD.business_id
     OR NEW.branch_id       IS DISTINCT FROM OLD.branch_id
     OR NEW.rule_code       IS DISTINCT FROM OLD.rule_code
     OR NEW.severity        IS DISTINCT FROM OLD.severity
     OR NEW.title           IS DISTINCT FROM OLD.title
     OR NEW.description     IS DISTINCT FROM OLD.description
     OR NEW.subject_user_id IS DISTINCT FROM OLD.subject_user_id
     OR NEW.evidence        IS DISTINCT FROM OLD.evidence
     OR NEW.related_ids     IS DISTINCT FROM OLD.related_ids
     OR NEW.detected_at     IS DISTINCT FROM OLD.detected_at
     OR NEW.created_at      IS DISTINCT FROM OLD.created_at
     OR NEW.dedupe_key      IS DISTINCT FROM OLD.dedupe_key
  THEN
    RAISE EXCEPTION 'FRAUD_FLAG_IMMUTABLE: only status/resolution fields may change';
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_fraud_flags_freeze ON public.fraud_flags;
CREATE TRIGGER trg_fraud_flags_freeze
  BEFORE UPDATE ON public.fraud_flags
  FOR EACH ROW EXECUTE FUNCTION public.fraud_flags_freeze_immutable();

-- ── 5. Recompute effective_permissions so grants apply without re-login ─────
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT DISTINCT e.id AS employee_id, eb.branch_id
    FROM   employees        e
    JOIN   employee_branches eb ON eb.employee_id = e.id
    WHERE  e.is_active = true
  LOOP
    BEGIN
      PERFORM compute_employee_permissions(r.employee_id, r.branch_id);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'recompute skipped employee=% branch=%: %',
        r.employee_id, r.branch_id, SQLERRM;
    END;
  END LOOP;
END;
$$;
