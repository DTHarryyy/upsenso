-- =============================================================================
-- M1 Phase 1 — Tamper-evident audit chain: server-side columns, immutability
-- index, chain-head RPCs, and the audit_logs.verify permission seed.
--
-- Design: docs/UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md (hardened plan 2026-07).
-- Chains are scoped per (business_id, device_uid); each device allocates a
-- monotonic seq and hashes SHA256(prev_hash || '|' || canonical_payload).
-- The pre-existing `previous_hash` / `hash` columns (AI_CONTEXT-era, never
-- populated) are ADOPTED as-is: the client maps prevHash→previous_hash and
-- entryHash→hash. Only seq / device_uid / synced_at are new.
--
-- Why the server matters: a hash chain has no secret — an attacker with local
-- DB access can recompute it. The server is the anchor: audit_logs is already
-- append-only (no UPDATE/DELETE policy since 20260627000006), and the partial
-- unique index below makes every synced (business, device, seq) slot
-- permanent: a locally rewritten chain then CONFLICTS on push instead of
-- silently replacing history.
--
-- ROLLBACK:
--   DROP FUNCTION IF EXISTS public.get_audit_chain_heads();
--   DROP FUNCTION IF EXISTS public.get_my_device_chain_head(text);
--   DROP INDEX IF EXISTS public.ux_audit_chain;
--   ALTER TABLE public.audit_logs
--     DROP COLUMN IF EXISTS seq,
--     DROP COLUMN IF EXISTS device_uid,
--     DROP COLUMN IF EXISTS synced_at;
--   DELETE FROM role_permissions rp USING permissions p
--     WHERE rp.permission_id = p.id AND p.code = 'audit_logs.verify';
--   DELETE FROM business_template_role_permissions
--     WHERE permission_code = 'audit_logs.verify';
--   DELETE FROM permissions WHERE code = 'audit_logs.verify';
--   (previous_hash / hash predate this migration — leave them.)
-- =============================================================================

-- ── 1. Chain columns (additive; previous_hash + hash already exist) ─────────
ALTER TABLE public.audit_logs
  ADD COLUMN IF NOT EXISTS seq        bigint,
  ADD COLUMN IF NOT EXISTS device_uid text,
  -- Trusted server receive-time. Client clocks are attacker-controlled in an
  -- offline-first app; this column cannot be backfilled later, so it ships
  -- now even though the claimed-vs-received analysis lands in Phase 3.
  ADD COLUMN IF NOT EXISTS synced_at  timestamptz DEFAULT now();

-- ── 2. Chain immutability: one row per (business, device, seq), forever ─────
-- Partial: pre-chain rows (NULL seq/device_uid) are exempt.
CREATE UNIQUE INDEX IF NOT EXISTS ux_audit_chain
  ON public.audit_logs (business_id, device_uid, seq)
  WHERE seq IS NOT NULL AND device_uid IS NOT NULL;

-- ── 3. Chain-head RPCs ───────────────────────────────────────────────────────
-- Both SECURITY DEFINER: audit_logs SELECT RLS is super-admin-only, but chain
-- verification (Branch Manager) and genesis-resume (any device) need narrow,
-- aggregate-only reads. Business is always derived from auth, never a param.

-- All device chain heads for the caller's business. Powers the "Verify
-- integrity" truncation check: local head < server head ⇒ synced tail was
-- deleted locally. Gated by audit_logs.verify (owner bypass in has_permission).
CREATE OR REPLACE FUNCTION public.get_audit_chain_heads()
RETURNS TABLE (device_uid text, max_seq bigint, head_hash text, last_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.has_permission('audit_logs.verify') THEN
    RAISE EXCEPTION 'PERMISSION_DENIED';
  END IF;

  RETURN QUERY
  SELECT a.device_uid,
         MAX(a.seq)                                              AS max_seq,
         (ARRAY_AGG(a.hash ORDER BY a.seq DESC))[1]              AS head_hash,
         MAX(a.created_at)                                       AS last_at
  FROM   public.audit_logs a
  WHERE  a.business_id = public.get_my_business_id()
    AND  a.seq IS NOT NULL
    AND  a.device_uid IS NOT NULL
  GROUP  BY a.device_uid;
END;
$$;

-- One device's own head, for genesis-resume after a reinstall (iOS Keychain
-- keeps the uid while the local DB is wiped): the device continues from
-- head+1 instead of restarting at seq 1 and flooding ux_audit_chain
-- conflicts. Tenant-scoped only — a device learns nothing it didn't write.
CREATE OR REPLACE FUNCTION public.get_my_device_chain_head(p_device_uid text)
RETURNS TABLE (max_seq bigint, head_hash text)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT a.seq AS max_seq, a.hash AS head_hash
  FROM   public.audit_logs a
  WHERE  a.business_id = public.get_my_business_id()
    AND  a.device_uid = p_device_uid
    AND  a.seq IS NOT NULL
  ORDER  BY a.seq DESC
  LIMIT  1;
$$;

REVOKE ALL ON FUNCTION public.get_audit_chain_heads() FROM public;
REVOKE ALL ON FUNCTION public.get_my_device_chain_head(text) FROM public;
GRANT EXECUTE ON FUNCTION public.get_audit_chain_heads() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_device_chain_head(text) TO authenticated;

-- ── 4. Seed audit_logs.verify (same pattern as 20260703000001 CRM seed) ─────
-- OWNER-ONLY by default, exactly like audit_logs.view / audit_logs.delete
-- (all three client role blocks deny audit access; audit SELECT RLS is
-- super-admin-only). A business can still grant a trusted manager
-- view+verify via per-employee overrides — seeding the code here is what
-- makes that override resolvable.
INSERT INTO permissions (code, action, module_code, display_name, is_dangerous)
SELECT 'audit_logs.verify', 'verify', 'audit', 'Verify Audit Chain', false
WHERE NOT EXISTS (SELECT 1 FROM permissions p WHERE p.code = 'audit_logs.verify');

INSERT INTO role_permissions (role_id, permission_id, allowed)
SELECT r.id, p.id, true
FROM   roles r
CROSS  JOIN permissions p
WHERE  r.name = 'Business Owner'
  AND  p.code = 'audit_logs.verify'
ON CONFLICT (role_id, permission_id) DO NOTHING;

INSERT INTO business_template_role_permissions (template_role_id, permission_code, is_granted)
SELECT tr.id, 'audit_logs.verify', true
FROM   business_template_roles tr
WHERE  tr.name = 'Business Owner'
  AND  NOT EXISTS (
    SELECT 1 FROM business_template_role_permissions x
    WHERE x.template_role_id = tr.id AND x.permission_code = 'audit_logs.verify'
  );

-- ── 5. Recompute effective_permissions so the grant applies without re-login ─
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
