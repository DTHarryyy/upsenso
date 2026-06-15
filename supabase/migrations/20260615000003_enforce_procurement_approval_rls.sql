-- =============================================================================
-- Permission-aware RLS on purchase_orders — close the direct-API bypass of the
-- procurement approval workflow.
--
-- Audit (2026-06-15): the only policy on purchase_orders (po_biz_isolation) was
-- business-scope ONLY, so any authenticated user in the business could write any
-- column via PostgREST/REST — including status = 'approved' or 'received' —
-- bypassing the procurement.approve_po / .receive checks the app enforces in the
-- UI and cubits. This adds value-based WITH CHECK gates keyed on the row status.
--
-- OFFLINE-FIRST PRESERVED: there is no RPC and no online-only path. Writes still
-- flow through the normal Drift→Supabase upsert; the policy simply evaluates on
-- that synced write. It MIRRORS the app's own permission gating, so a legitimate
-- sync is never rejected — only a user whose ROLE lacks the permission is
-- blocked from producing the corresponding PO state directly via the API.
--
-- Enforcement is role-based via has_permission() (reads role_permissions). It is
-- intentionally targeted: each clause only restricts when the row is in that
-- state, and any unknown status stays business-scoped (no ELSE→false trap that
-- could wedge a sync). Verified before apply (read-only):
--   • all 8 active employees have user_id = auth_user_id (has_permission joins on
--     employees.user_id = auth.uid())
--   • has_permission resolves: create_po → 3, approve_po → 3, receive → 4,
--     manage → 3 active employees (the managers/owners), matching the matrix.
--
-- Rollback:
--   DROP POLICY IF EXISTS po_biz_isolation ON public.purchase_orders;
--   CREATE POLICY po_biz_isolation ON public.purchase_orders
--     FOR ALL TO authenticated
--     USING (business_id = my_business_id())
--     WITH CHECK (business_id = my_business_id());
-- =============================================================================

DROP POLICY IF EXISTS po_biz_isolation ON public.purchase_orders;

CREATE POLICY po_biz_isolation ON public.purchase_orders
  FOR ALL TO authenticated
  USING (business_id = my_business_id())
  WITH CHECK (
    business_id = my_business_id()
    -- Creating / routing a draft requires create-PO rights.
    AND (status NOT IN ('draft', 'submitted')
         OR has_permission('procurement.create_po'))
    -- Producing an approved PO requires approval rights (separation of duties).
    AND (status <> 'approved'
         OR has_permission('procurement.approve_po'))
    -- Marking goods received requires receiving rights.
    AND (status NOT IN ('partially_received', 'received')
         OR has_permission('procurement.receive'))
    -- Cancelling requires full procurement management.
    AND (status <> 'cancelled'
         OR has_permission('procurement.manage'))
  );
