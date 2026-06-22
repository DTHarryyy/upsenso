-- =============================================================================
-- Procurement: approval-threshold settings + self-approve RLS hardening
-- =============================================================================
-- 1. procurement_settings — per-business PO approval threshold (server copy of
--    the local Drift table). Above the threshold a non-owner cannot approve
--    their own PO.
-- 2. Replaces purchase_orders' po_biz_isolation WITH CHECK to add a
--    separation-of-duties clause on the approve transition, mirroring the
--    app-layer ApprovalPolicy exactly. Uses the existing i_am_owner_of() helper
--    so owners are exempt and a solo founder is never dead-ended.
--
-- Reversibility: the policy change is a DROP+CREATE of one policy (the prior
-- definition is preserved in this file's header for rollback). Additive table.
--
-- Rollback:
--   DROP TABLE IF EXISTS public.procurement_settings;
--   -- and restore the previous po_biz_isolation WITH CHECK (no self-approve clause):
--   DROP POLICY IF EXISTS po_biz_isolation ON public.purchase_orders;
--   CREATE POLICY po_biz_isolation ON public.purchase_orders FOR ALL
--     USING (business_id = my_business_id())
--     WITH CHECK (
--       business_id = my_business_id()
--       AND ((status <> ALL (ARRAY['draft','submitted'])) OR has_permission('procurement.create_po'))
--       AND ((status <> 'approved') OR has_permission('procurement.approve_po'))
--       AND ((status <> ALL (ARRAY['partially_received','received'])) OR has_permission('procurement.receive'))
--       AND ((status <> 'cancelled') OR has_permission('procurement.manage'))
--     );
-- =============================================================================

-- ── 1. procurement_settings ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.procurement_settings (
  business_id        uuid PRIMARY KEY REFERENCES public.businesses(id) ON DELETE CASCADE,
  approval_threshold numeric,           -- null = unset (self-approve any amount)
  updated_at         timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.procurement_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS proc_settings_select ON public.procurement_settings;
CREATE POLICY proc_settings_select ON public.procurement_settings
  FOR SELECT TO authenticated
  USING (business_id = my_business_id());

-- Only procurement managers/owners may write the threshold.
DROP POLICY IF EXISTS proc_settings_write ON public.procurement_settings;
CREATE POLICY proc_settings_write ON public.procurement_settings
  FOR ALL TO authenticated
  USING (business_id = my_business_id() AND has_permission('procurement.manage'))
  WITH CHECK (business_id = my_business_id() AND has_permission('procurement.manage'));

GRANT SELECT, INSERT, UPDATE ON public.procurement_settings TO authenticated;

-- ── 2. purchase_orders RLS — add self-approve separation-of-duties ─────────────
DROP POLICY IF EXISTS po_biz_isolation ON public.purchase_orders;
CREATE POLICY po_biz_isolation ON public.purchase_orders
  FOR ALL
  USING (business_id = my_business_id())
  WITH CHECK (
    business_id = my_business_id()
    AND ((status <> ALL (ARRAY['draft'::text, 'submitted'::text])) OR has_permission('procurement.create_po'))
    AND ((status <> 'approved'::text) OR has_permission('procurement.approve_po'))
    AND ((status <> ALL (ARRAY['partially_received'::text, 'received'::text])) OR has_permission('procurement.receive'))
    AND ((status <> 'cancelled'::text) OR has_permission('procurement.manage'))
    -- Separation of duties on approval: a non-owner may not approve their own PO
    -- above the business threshold. Owners are exempt; an unset threshold (no
    -- row) makes COALESCE fall back to total_amount so the check always passes.
    AND (
      status <> 'approved'::text
      OR approved_by_id IS DISTINCT FROM created_by_id
      OR i_am_owner_of(business_id)
      OR total_amount <= COALESCE(
           (SELECT ps.approval_threshold FROM public.procurement_settings ps
             WHERE ps.business_id = purchase_orders.business_id),
           total_amount)
    )
  );

SELECT pg_notify('pgrst', 'reload schema');
