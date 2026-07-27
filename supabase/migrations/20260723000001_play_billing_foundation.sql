-- =============================================================================
-- M7.1 → Google Play Billing: acquisition-layer swap (Phase P1, additive only).
--
-- Decision (2026-07-23): billing is Android-only via Google Play. Play Billing
-- replaces the PayMongo hosted checkout on Android; Web keeps a read-only
-- plan/status view (no purchase). The ENTITLEMENT ENGINE is unchanged — the
-- status oracle, effective_limits, has_cloud_access and admin_grant_subscription
-- (20260707000001/2) stay exactly as-is. Play purchases funnel into the SAME
-- admin_grant_subscription, so a Play grant and a manual admin grant are
-- indistinguishable to the engine (the §11 invariant still holds).
--
-- This migration adds ONLY the Play acquisition + RTDN linkage surface:
--   * play_product_map      — product_id/base_plan_id → plan (client reads it to
--                             know which SKUs to query; server reads it to grant)
--   * play_purchase_tokens  — durable purchaseToken → business index. RTDN only
--                             carries the token, never our business_id, so we
--                             must be able to resolve it (incl. upgrade chains).
--   * subscriptions         + provider / play_product_id / play_purchase_token
--   * billing_payments      + product_id / base_plan_id / purchase_token
--
-- Non-destructive: only ADD COLUMN IF NOT EXISTS / CREATE TABLE IF NOT EXISTS.
-- No DROP, no UPDATE, no data rewrite. Existing PayMongo rows keep working while
-- the two providers coexist during the transition (PayMongo retired in P7).
--
-- billing_payments.provider already has NO check constraint, so 'google_play'
-- is accepted without altering it.
--
-- ROLLBACK (all reversible, additive):
--   DROP TABLE  IF EXISTS public.play_purchase_tokens;
--   DROP TABLE  IF EXISTS public.play_product_map;
--   ALTER TABLE public.subscriptions   DROP COLUMN IF EXISTS provider;
--   ALTER TABLE public.subscriptions   DROP COLUMN IF EXISTS play_product_id;
--   ALTER TABLE public.subscriptions   DROP COLUMN IF EXISTS play_purchase_token;
--   ALTER TABLE public.billing_payments DROP COLUMN IF EXISTS product_id;
--   ALTER TABLE public.billing_payments DROP COLUMN IF EXISTS base_plan_id;
--   ALTER TABLE public.billing_payments DROP COLUMN IF EXISTS purchase_token;
-- =============================================================================

-- ── 1. Product catalog map — the ONLY place Play SKU ids live ─────────────────
-- (product_id, base_plan_id) is the unit a client buys; it resolves to a
-- versioned plan + billing period. FK to plans keeps it from mapping to a SKU
-- that has no catalog row. Seeded in a follow-up data migration with the real
-- Play Console ids (kept out of this structural migration on purpose).
CREATE TABLE IF NOT EXISTS public.play_product_map (
  product_id     text NOT NULL,          -- Play subscription product id
  base_plan_id   text NOT NULL,          -- Play base plan id (monthly / annual)
  plan_code      text NOT NULL,
  plan_version   int  NOT NULL,
  billing_period text NOT NULL CHECK (billing_period IN ('monthly', 'annual')),
  is_active      boolean NOT NULL DEFAULT true,
  created_at     timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (product_id, base_plan_id),
  FOREIGN KEY (plan_code, plan_version) REFERENCES public.plans (code, version)
);

-- ── 2. Durable purchaseToken → business index (RTDN resolution) ───────────────
-- RTDN payloads carry only {purchaseToken, subscriptionId, notificationType} —
-- never our business_id. We record every token we ever verify so a later
-- lifecycle notification (renew / cancel / grace / revoke) can find its tenant.
-- Append-only: an upgrade issues a NEW token (linkedPurchaseToken → the old);
-- we keep both so stale-token notifications still resolve and can be ignored.
CREATE TABLE IF NOT EXISTS public.play_purchase_tokens (
  purchase_token text PRIMARY KEY,
  business_id    uuid NOT NULL REFERENCES public.businesses (id) ON DELETE CASCADE,
  product_id     text NOT NULL,
  base_plan_id   text,
  -- The token this one superseded (Play linkedPurchaseToken on upgrade/regrade).
  linked_token   text,
  is_current     boolean NOT NULL DEFAULT true,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_play_tokens_business
  ON public.play_purchase_tokens (business_id);

-- ── 3. Play linkage on the subscription (the current active purchase) ─────────
ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS provider            text;
ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS play_product_id     text;
ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS play_purchase_token text;

-- ── 4. Play fields on the payment ledger ─────────────────────────────────────
ALTER TABLE public.billing_payments
  ADD COLUMN IF NOT EXISTS product_id     text;
ALTER TABLE public.billing_payments
  ADD COLUMN IF NOT EXISTS base_plan_id   text;
ALTER TABLE public.billing_payments
  ADD COLUMN IF NOT EXISTS purchase_token text;

-- ── 5. RLS ────────────────────────────────────────────────────────────────────
ALTER TABLE public.play_product_map     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.play_purchase_tokens ENABLE ROW LEVEL SECURITY;

-- Catalog map: world-readable to signed-in users (the client needs the SKU ids
-- to query Play for prices). Never client-writable — service-role seeds it.
DROP POLICY IF EXISTS play_product_map_select ON public.play_product_map;
CREATE POLICY play_product_map_select ON public.play_product_map
  FOR SELECT TO authenticated USING (is_active);

-- play_purchase_tokens: no policies at all — service-role / definer only. A
-- purchase token is a bearer credential; clients must never read or write it.
