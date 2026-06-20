-- =============================================================================
-- Refund feature: refunds (header) + refund_items (lines)
-- =============================================================================
-- Per CLAUDE.md "Database & Migration Safety" — pre-change checklist:
--   • Schema impact : two new tables only. No existing table, column, or
--                     constraint is altered. Column types mirror the live
--                     schema: transactions.id/transaction_items.id are uuid,
--                     transaction_items.variant_id and transactions.cashier_id
--                     are text — refund_items.variant_id and refunds.refunded_by
--                     match those types exactly (confirmed via live introspection,
--                     not assumed). A UNIQUE(refund_id, transaction_item_id)
--                     constraint on refund_items blocks a single refund event
--                     from double-counting the same original line.
--   • Offline impact: none by itself — Drift already has the matching local
--                     tables (refunds_table.dart / refund_items_table.dart,
--                     schema v45, including the restocked column and the
--                     matching local unique index); this migration just gives
--                     them a sync target.
--   • Sync impact   : refunds are append-only — the app only ever INSERTs
--                     (never UPDATEs/DELETEs) these rows, so grants are
--                     SELECT + INSERT only (least privilege, mirrors the
--                     audit_logs hardening in 20260619000006/20260619000001:
--                     append-only tables don't get UPDATE/DELETE grants).
--                     Retries of an already-pushed row hit the unique PK and
--                     are treated as success client-side (23505 → no-op),
--                     the same pattern audit_logs already uses — so no
--                     `ON CONFLICT DO UPDATE` (and therefore no UPDATE grant)
--                     is ever needed. No set_updated_at trigger either:
--                     updated_at / client_updated_at are written once at
--                     insert time by the app and read back unchanged.
--   • Existing data : untouched — purely additive.
--   • Rollback      : see ROLLBACK block at the bottom (run manually).
--
-- NOTE: not applied by Claude. Review, then run `supabase db push` yourself.
-- =============================================================================

BEGIN;

-- ── 1. refunds (header) ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.refunds (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id    uuid NOT NULL REFERENCES public.transactions(id),
  business_id       uuid NOT NULL REFERENCES public.businesses(id),
  branch_id         uuid REFERENCES public.branches(id),
  refunded_by       text NOT NULL,
  total_amount      numeric NOT NULL,
  tax_amount        numeric NOT NULL DEFAULT 0,
  reason            text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  client_updated_at timestamptz,
  deleted_at        timestamptz
);

CREATE INDEX IF NOT EXISTS idx_refunds_transaction
  ON public.refunds (transaction_id);
CREATE INDEX IF NOT EXISTS idx_refunds_business_created
  ON public.refunds (business_id, created_at);

-- ── 2. refund_items (lines) ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.refund_items (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  refund_id           uuid NOT NULL REFERENCES public.refunds(id),
  transaction_item_id uuid NOT NULL REFERENCES public.transaction_items(id),
  variant_id          text NOT NULL,
  qty                 numeric NOT NULL CHECK (qty > 0),
  amount              numeric NOT NULL CHECK (amount >= 0),
  -- Whether this line's qty was added back to sellable stock. Lets the
  -- refunder mark damaged/expired/opened returns as NOT restocked.
  restocked           boolean NOT NULL DEFAULT true,
  -- A single refund event can't refund the same original sale line twice.
  -- (Refunding the SAME line again in a LATER, separate refund event is the
  -- normal multi-partial-refund flow — that's a different refund_id, so this
  -- constraint doesn't block it.)
  UNIQUE (refund_id, transaction_item_id)
);

CREATE INDEX IF NOT EXISTS idx_refund_items_refund
  ON public.refund_items (refund_id);
CREATE INDEX IF NOT EXISTS idx_refund_items_transaction_item
  ON public.refund_items (transaction_item_id);

-- ── 3. RLS ───────────────────────────────────────────────────────────────────
-- Explicit per-verb policies (not FOR ALL) so the absence of an UPDATE/DELETE
-- policy is visible in the policy list itself, not just implied by the grants
-- below — mirrors the audit_logs_insert/audit_logs_update split pattern.
ALTER TABLE public.refunds      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refund_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS refunds_biz_isolation ON public.refunds;
DROP POLICY IF EXISTS refunds_select ON public.refunds;
DROP POLICY IF EXISTS refunds_insert ON public.refunds;

CREATE POLICY refunds_select ON public.refunds
  FOR SELECT TO authenticated
  USING (
    business_id = get_my_business_id()
    AND (
      EXISTS (
        SELECT 1 FROM public.businesses
        WHERE id = refunds.business_id AND owner_id = auth.uid()
      )
      OR i_am_super_admin()
      OR has_branch_access(branch_id)
    )
  );

CREATE POLICY refunds_insert ON public.refunds
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id = get_my_business_id()
    AND (
      EXISTS (
        SELECT 1 FROM public.businesses
        WHERE id = refunds.business_id AND owner_id = auth.uid()
      )
      OR i_am_super_admin()
      OR has_branch_access(branch_id)
    )
  );

-- refund_items: no business_id/branch_id of its own — access derives through
-- the parent refunds row, mirroring transaction_items_biz_isolation.
DROP POLICY IF EXISTS refund_items_biz_isolation ON public.refund_items;
DROP POLICY IF EXISTS refund_items_select ON public.refund_items;
DROP POLICY IF EXISTS refund_items_insert ON public.refund_items;

CREATE POLICY refund_items_select ON public.refund_items
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM   public.refunds r
      WHERE  r.id          = refund_items.refund_id
        AND  r.business_id = get_my_business_id()
        AND  has_branch_access(r.branch_id)
    )
  );

CREATE POLICY refund_items_insert ON public.refund_items
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM   public.refunds r
      WHERE  r.id          = refund_items.refund_id
        AND  r.business_id = get_my_business_id()
        AND  has_branch_access(r.branch_id)
    )
  );

-- ── 4. Grants ─────────────────────────────────────────────────────────────────
-- Least privilege: append-only tables get SELECT + INSERT only. No UPDATE,
-- no DELETE — there is no code path in the app that issues either.
GRANT SELECT, INSERT ON public.refunds      TO authenticated;
GRANT SELECT, INSERT ON public.refund_items TO authenticated;

-- ── PostgREST schema reload ───────────────────────────────────────────────────
SELECT pg_notify('pgrst', 'reload schema');

COMMIT;

-- =============================================================================
-- ROLLBACK (run manually only if you need to revert)
-- =============================================================================
-- DROP POLICY IF EXISTS refund_items_select ON public.refund_items;
-- DROP POLICY IF EXISTS refund_items_insert ON public.refund_items;
-- DROP POLICY IF EXISTS refunds_select      ON public.refunds;
-- DROP POLICY IF EXISTS refunds_insert      ON public.refunds;
-- DROP TABLE IF EXISTS public.refund_items;
-- DROP TABLE IF EXISTS public.refunds;
