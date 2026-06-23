-- =============================================================================
-- Purchase orders: short-close support
-- =============================================================================
-- 1. Allow the 'closed' status (short-close: finalise a PO with outstanding qty).
-- 2. Gate the 'closed' transition on procurement.manage in RLS (alongside
--    'cancelled'), so it can't be set via direct API without authority. The rest
--    of po_biz_isolation (incl. the self-approve clause) is preserved.
--
-- Rollback:
--   ALTER TABLE public.purchase_orders DROP CONSTRAINT po_status_valid;
--   ALTER TABLE public.purchase_orders ADD CONSTRAINT po_status_valid
--     CHECK (status = ANY (ARRAY['draft','submitted','approved','partially_received','received','cancelled']));
--   -- and restore the prior po_biz_isolation (cancelled-only manage gate).
-- =============================================================================

ALTER TABLE public.purchase_orders DROP CONSTRAINT IF EXISTS po_status_valid;
ALTER TABLE public.purchase_orders ADD CONSTRAINT po_status_valid
  CHECK (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'approved'::text,
    'partially_received'::text, 'received'::text, 'cancelled'::text, 'closed'::text]));

DROP POLICY IF EXISTS po_biz_isolation ON public.purchase_orders;
CREATE POLICY po_biz_isolation ON public.purchase_orders
  FOR ALL
  USING (business_id = my_business_id())
  WITH CHECK (
    business_id = my_business_id()
    AND ((status <> ALL (ARRAY['draft'::text, 'submitted'::text])) OR has_permission('procurement.create_po'))
    AND ((status <> 'approved'::text) OR has_permission('procurement.approve_po'))
    AND ((status <> ALL (ARRAY['partially_received'::text, 'received'::text])) OR has_permission('procurement.receive'))
    AND ((status <> ALL (ARRAY['cancelled'::text, 'closed'::text])) OR has_permission('procurement.manage'))
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
