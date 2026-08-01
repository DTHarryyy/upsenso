-- =============================================================================
-- Plan retune — "Growth = everything unlocked", Starter = one store, small team.
--
-- Product decision 2026-07-31. Two changes to what we sell:
--   * Capacity: Starter 2→3 devices; Growth 3→5 branches, 10→15 seats, and
--     devices uncapped (NULL). Every change is a RAISE, so §4.9 ("existing
--     customers never worse off") holds trivially.
--   * feature_flags: `cloud_audit` (bool) becomes `audit` (ranked
--     local | cloud | full), matching the existing crm/reports idiom.
--
--       local  — the hash-chained on-device audit log records everything.
--       cloud  — the chain is also backed up server-side. Not a capability we
--                built; it rides the cloud sync the tier already pays for.
--       full   — the Audit Logs viewer, the Fraud & Risk dashboard, and
--                cross-device fraud sync. This is the tier-differentiating bit.
--
-- The audit RECORD stays universal on every tier — only the analysis surface is
-- paid, and audit rows now ride the always-free Data Export so nobody's trail is
-- ever unreachable (§4.7 "never trap data" + BIR retrievability).
--
-- WHY EDIT v1 IN PLACE instead of publishing v2: there are zero users and zero
-- subscribers, so no subscription pins a v1 entitlement_snapshot and there is
-- nothing to grandfather. The guard below refuses to run if that stops being
-- true. The versioning + snapshot mechanism is untouched for the next change,
-- when it will matter.
--
-- Prices are unchanged (₱199 / ₱499) — no plans row, no play_product_map, and
-- no Play Console work. No function or RLS policy changes: NULL already means
-- "unlimited" in branches_cap_insert, create_employee_auth_account,
-- enforce_seat_cap_on_reactivate, and register_device.
--
-- ROLLBACK — restore the 20260707000001 §14 seed values verbatim:
--   UPDATE public.plan_limits SET max_branches=1, max_seats=2, max_devices=1,
--     feature_flags='{"crm": false, "procurement": false, "reports": "basic", "cloud_audit": false}'
--     WHERE plan_code='free' AND plan_version=1;
--   UPDATE public.plan_limits SET max_branches=1, max_seats=3, max_devices=2,
--     feature_flags='{"crm": "basic", "procurement": false, "reports": "basic", "cloud_audit": true}'
--     WHERE plan_code='starter' AND plan_version=1;
--   UPDATE public.plan_limits SET max_branches=3, max_seats=10, max_devices=5,
--     feature_flags='{"crm": "full", "procurement": true, "reports": "full", "cloud_audit": true}'
--     WHERE plan_code='growth' AND plan_version=1;
--   UPDATE public.plan_limits SET max_branches=10, max_seats=50, max_devices=20,
--     feature_flags='{"crm": "full", "procurement": true, "reports": "full", "cloud_audit": true, "accounting": true, "multi_currency": true}'
--     WHERE plan_code='business' AND plan_version=1;
--   UPDATE public.plan_limits SET
--     feature_flags='{"crm": "full", "procurement": true, "reports": "full", "cloud_audit": true, "accounting": true, "multi_currency": true}'
--     WHERE plan_code='enterprise' AND plan_version=1;
-- =============================================================================

-- ── 0. Safety guard — in-place editing is only sound while nobody is inside a
-- paid window they bought. The condition is deliberately narrow: a live sub
-- resolves its limits from the entitlement_snapshot PINNED on the subscription
-- (effective_limits_for → the IF FOUND branch), not from plan_limits, so this
-- UPDATE cannot retroactively change what anyone was sold. What it must never
-- do is move the goalposts for a paying customer whose snapshot later expires.
--
-- Verified 2026-07-31 before applying: 9 rows, 0 blocking.
--   * 8 × "Cruz Store" — phantom trials from the 2026-07-26 grant_initial_trial
--     bug (plan_code free + Starter snapshot, see 20260727000002). No provider,
--     no transactions, no employees. Test artifacts.
--   * 1 × "Heaven brew" — a google_play license-tester purchase whose period
--     ended 2026-07-31 12:34 UTC, so it already reads as 'lapsed'.
--
-- If this ever fires, publish a v2 instead of editing v1.
DO $$
DECLARE
  v_live int;
BEGIN
  SELECT count(*) INTO v_live
  FROM public.subscriptions s
  WHERE s.provider IS NOT NULL
    AND public.effective_sub_status(s.*) IN ('trialing', 'active', 'past_due');

  IF v_live > 0 THEN
    RAISE EXCEPTION
      'ABORT: % provider-backed subscription(s) are inside a live window. Editing plan_limits v1 in place would move the goalposts under a paying customer — publish plans v2 instead (§4.9).',
      v_live;
  END IF;
END;
$$;

-- ── 1. Free — unchanged limits; flag rename only. Local-only forever (§4.2).
UPDATE public.plan_limits SET
  cloud_enabled = false,
  max_branches  = 1,
  max_seats     = 2,
  max_devices   = 1,
  feature_flags = '{"crm": false, "procurement": false, "reports": "basic", "audit": "local"}'::jsonb
WHERE plan_code = 'free' AND plan_version = 1;

-- ── 2. Starter ₱199 — one store, small team, on up to 3 devices.
UPDATE public.plan_limits SET
  cloud_enabled = true,
  max_branches  = 1,
  max_seats     = 3,
  max_devices   = 3,
  feature_flags = '{"crm": "basic", "procurement": false, "reports": "basic", "audit": "cloud"}'::jsonb
WHERE plan_code = 'starter' AND plan_version = 1;

-- ── 3. Growth ₱499 — every feature unlocked, unlimited devices.
-- Capacity stays metered on branches/seats: uncapping them would flatten ARPU
-- at ₱499 forever and make the (already-seeded, not-yet-sold) add-ons dead.
UPDATE public.plan_limits SET
  cloud_enabled = true,
  max_branches  = 5,
  max_seats     = 15,
  max_devices   = NULL,
  feature_flags = '{"crm": "full", "procurement": true, "reports": "full", "audit": "full"}'::jsonb
WHERE plan_code = 'growth' AND plan_version = 1;

-- ── 4. Business / Enterprise — inactive, unlaunched. Flag shape kept uniform so
-- they render consistently if they are ever switched on.
UPDATE public.plan_limits SET
  feature_flags = '{"crm": "full", "procurement": true, "reports": "full", "audit": "full", "accounting": true, "multi_currency": true}'::jsonb
WHERE plan_code IN ('business', 'enterprise') AND plan_version = 1;

-- ── 5. Verify the shape landed (fails the migration loudly, not silently).
DO $$
DECLARE
  v_bad int;
BEGIN
  SELECT count(*) INTO v_bad
  FROM public.plan_limits
  WHERE plan_version = 1
    AND (feature_flags ? 'cloud_audit' OR NOT (feature_flags ? 'audit'));

  IF v_bad > 0 THEN
    RAISE EXCEPTION 'ABORT: % plan_limits row(s) still carry cloud_audit or lack audit', v_bad;
  END IF;
END;
$$;
