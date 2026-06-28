-- Phase 4 — tie stock_ledger movements to their real source documents, and
-- close the upsert-conflict UPDATE bypass.
-- WHY: stock_ledger_perm_insert (20260627000012) already gates INSERT by
--   permission keyed on source_type, but trusts source_type/source_id at
--   face value — a client could label a manual draw-down as source_type
--   'sale' (cheaper permission: pos.use vs inventory.adjust) or, more
--   seriously, point source_id at an arbitrary string with no real backing
--   row at all. There was no way to verify a stock_ledger row's claimed
--   source actually exists.
--   Blocked on this until the app layer reliably populated real ids: before
--   this change, recordSaleDeductions() (the sale path) and
--   RecipeConsumptionService had no sourceId parameter at all for the OUT
--   (sale) direction — only the refund/reverse path threaded one through.
--   Fixed in the same change as this migration: recordSaleDeductions() now
--   requires the sale's real transaction id and threads it through every
--   completeSale() call site (POS, product checkout, AI assistant);
--   RecipeConsumptionService.consume()/restore() now require a real
--   transaction/refund id instead of stamping the product variant id
--   (consume) or silently falling back to it when absent (restore).
-- APPROACH: a RESTRICTIVE FOR INSERT policy, AND'd on top of the existing
--   permissive set, that cross-references source_id against the real source
--   table for every source_type the app ever writes. 'adjustment' and
--   'opening_stock' (manual/no-source-by-design) fall through to true since
--   they're already gated by inventory.adjust and carry no source_id.
--   recipe_consumption is grouped with sale rather than given its own table
--   check: RecipeConsumptionService.consume() (the OUT/sale-driven
--   direction) is the only place that writes source_type='recipe_consumption',
--   and it always stamps the sale's transaction id; the IN/refund-driven
--   restore() path writes source_type='refund' directly (same as the
--   non-recipe refund restock), so it's already covered by the refund
--   branch. This mirrors stock_ledger_perm_insert's own grouping (sale and
--   recipe_consumption already share the pos.use permission check there).
--   Bolted on as new policies rather than editing stock_ledger_perm_insert in
--   place, per this codebase's established convention (see 20260627000003,
--   20260627000009, 20260627000014) for low-blast-radius RLS changes.
-- ADDITIONAL HARDENING (beyond the literal source-document check — flagged
--   here, and called out separately to the user before this applies to
--   prod): stock_ledger had no UPDATE or DELETE policy beyond the permissive
--   business-id-only FOR ALL (stock_ledger_biz_isolation). The remote
--   datasource uploads rows via .upsert(), and Postgres routes an
--   INSERT ... ON CONFLICT DO UPDATE's conflict path through UPDATE
--   policies, not INSERT policies — so a row that already synced once could,
--   if a client tampered with its local copy and re-triggered upload (e.g.
--   by resetting sync_status), have its source_type/source_id/quantity
--   silently rewritten on the server while completely bypassing both
--   stock_ledger_perm_insert and the new check above. stock_ledger's own doc
--   comment calls it an "immutable history of every stock movement" — these
--   two RESTRICTIVE deny-all policies make that true at the RLS layer, not
--   just by Dart convention. Tradeoff: the one legitimate case this
--   forecloses is a rare crash-window retry of an already-synced row, which
--   will now hard-fail as SyncStatus.failed instead of silently no-op
--   succeeding — consistent with this codebase's stated conflict philosophy
--   ("log conflicts, never silently discard").
-- ROLLOUT NOTE: devices on an app build older than this change still call
--   the old code paths with no real sourceId for the sale/recipe direction.
--   Until those devices update, their stock_ledger sale/recipe_consumption
--   rows will fail this INSERT check on sync (logged + retried as
--   SyncStatus.failed; the sale itself is unaffected — recordSaleDeductions
--   already completed locally before sync ever runs, per offline-first).
--   Ship the app update before or together with this migration to avoid
--   that transient failure window for stragglers.
-- SCOPE: stock_ledger only. No changes to existing policies.
-- ROLLBACK:
--   DROP POLICY IF EXISTS stock_ledger_source_document_check ON public.stock_ledger;
--   DROP POLICY IF EXISTS stock_ledger_no_update ON public.stock_ledger;
--   DROP POLICY IF EXISTS stock_ledger_no_delete ON public.stock_ledger;

DROP POLICY IF EXISTS stock_ledger_source_document_check ON public.stock_ledger;
CREATE POLICY stock_ledger_source_document_check ON public.stock_ledger
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (
    CASE
      WHEN source_type = ANY (ARRAY['sale', 'recipe_consumption']) THEN
        EXISTS (SELECT 1 FROM public.transactions t WHERE t.id::text = source_id)
      WHEN source_type = 'refund' THEN
        EXISTS (SELECT 1 FROM public.refunds r WHERE r.id::text = source_id)
      WHEN source_type = 'purchase_order' THEN
        EXISTS (SELECT 1 FROM public.purchase_orders po WHERE po.id = source_id)
      ELSE true -- 'adjustment', 'opening_stock', NULL, etc.: no source document by design
    END
  );

DROP POLICY IF EXISTS stock_ledger_no_update ON public.stock_ledger;
CREATE POLICY stock_ledger_no_update ON public.stock_ledger
  AS RESTRICTIVE FOR UPDATE TO authenticated
  USING (false);

DROP POLICY IF EXISTS stock_ledger_no_delete ON public.stock_ledger;
CREATE POLICY stock_ledger_no_delete ON public.stock_ledger
  AS RESTRICTIVE FOR DELETE TO authenticated
  USING (false);
