-- =============================================================================
-- Fraud false-positive hardening (2026-07-03 incident)
--
-- Companion to the client changes in
-- docs/UPSENSO_FRAUD_FALSE_POSITIVE_FIX_PLAN.md. Three additive, reversible
-- pieces:
--   1. audit_logs.hash_version — records the canonicalization version a row's
--      hash was computed under, so the canonical form can evolve (v2 nulls
--      empty branch_id/user_id) WITHOUT mass-false-positiving pre-fix history.
--      Legacy rows stay NULL and are hash-exempt on the client verifier.
--   2. Query indexes that the on-device rules mirror server-side, so an owner
--      device (or a future server-side check) probing "records without an
--      audit row" and action-scoped chains stays cheap.
--   3. get_unaudited_record_ids() — an authoritative, online orphan check the
--      confirmation pipeline consults so a stale LOCAL mirror can never be the
--      sole basis for a "record with no audit trail" flag (the P0.2 / P1.7
--      fix; the exact 2026-07-03 false positive).
--
-- Nothing here rewrites existing rows or changes RLS on audit_logs
-- (SELECT stays owner/verify-gated; the RPC is SECURITY DEFINER + fraud-gated).
--
-- ROLLBACK:
--   DROP FUNCTION IF EXISTS public.get_unaudited_record_ids(uuid[], text);
--   DROP INDEX IF EXISTS public.idx_audit_logs_entity;
--   DROP INDEX IF EXISTS public.idx_audit_logs_action_scan;
--   ALTER TABLE public.audit_logs DROP COLUMN IF EXISTS hash_version;
-- =============================================================================

-- ── 1. Canonicalization version (additive; NULL = legacy/pre-v2) ─────────────
ALTER TABLE public.audit_logs
  ADD COLUMN IF NOT EXISTS hash_version int;

-- ── 2. Indexes mirroring the on-device fraud-rule queries ───────────────────
-- ORPHANED_RECORD probes audit_logs by entity_id; CONTROL_CHANGE / permission
-- rules scan (business_id, action_type, created_at).
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity
  ON public.audit_logs (entity_id)
  WHERE entity_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_audit_logs_action_scan
  ON public.audit_logs (business_id, action_type, created_at);

-- ── 3. Authoritative online orphan check ────────────────────────────────────
-- Returns the subset of [p_ids] that have NO matching audit_logs row of the
-- expected action for the caller's business. The client feeds candidate record
-- ids (refunds / stock_ledger) and treats server truth as decisive: present
-- server-side ⇒ drop the candidate; absent ⇒ a genuine orphan. This removes
-- the local mirror's staleness from the verdict entirely.
--
-- SECURITY DEFINER because audit_logs SELECT is owner/verify-gated; the
-- function gates on fraud.view and derives business from auth (never a param),
-- and only ever reveals which of the caller's OWN ids lack an audit row.
CREATE OR REPLACE FUNCTION public.get_unaudited_record_ids(
  p_ids  uuid[],
  p_kind text
)
RETURNS TABLE (id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_action text;
BEGIN
  IF NOT public.has_permission('fraud.view') THEN
    RAISE EXCEPTION 'PERMISSION_DENIED';
  END IF;

  v_action := CASE p_kind
                WHEN 'refund' THEN 'REFUND_CREATED'
                WHEN 'stock'  THEN 'STOCK_ADJUSTED'
                ELSE NULL
              END;
  IF v_action IS NULL THEN
    RAISE EXCEPTION 'UNKNOWN_KIND: %', p_kind;
  END IF;

  RETURN QUERY
  SELECT candidate_id
  FROM   unnest(p_ids) AS candidate_id
  WHERE  NOT EXISTS (
           SELECT 1
           FROM   public.audit_logs a
           WHERE  a.entity_id   = candidate_id
             AND  a.business_id = public.get_my_business_id()
             AND  a.action_type = v_action
         );
END;
$$;

REVOKE ALL ON FUNCTION public.get_unaudited_record_ids(uuid[], text) FROM public;
GRANT EXECUTE ON FUNCTION public.get_unaudited_record_ids(uuid[], text) TO authenticated;
