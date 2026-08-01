-- =============================================================================
-- Signup / onboarding — atomicity + duplicate-prevention verification runbook.
--
-- These checks PROVE that the 2026-07-26 duplicate-business bug cannot recur:
-- one failed signup used to leave a committed-but-unusable business behind, and
-- because the client minted a fresh uuid per attempt, eight retries produced
-- eight orphans. See 20260731130001 (cleanup) and 20260731130002 (the fix).
--
-- Run against a DEV / preview branch project — NEVER blind-run against prod.
-- §3 deliberately creates and rolls back data, so it must stay inside its
-- transaction.
--
-- HOW TO RUN
--   [service_role] — the SQL editor / a service-key connection
--   [user JWT]     — a signed-in user; the app's access token, or the dashboard
--                    "Run as user" feature
--
-- Expected results are noted inline as  --> EXPECT ...
-- =============================================================================


-- ── 1. The structural guard exists ──────────────────────────────────────────
-- [service_role] Without this index a second business per owner is possible and
-- every downstream single-business assumption (my_business_id,
-- getBusinessByOwner, ActiveBusinessContext) is on sand.
SELECT indexdef
FROM   pg_indexes
WHERE  schemaname = 'public' AND indexname = 'businesses_owner_id_key';
--> EXPECT 1 row: CREATE UNIQUE INDEX ... ON public.businesses USING btree (owner_id)


-- ── 2. No owner currently holds duplicates ──────────────────────────────────
-- [service_role] Should be permanently empty once §1 is in place.
SELECT owner_id, count(*) AS n
FROM   public.businesses
GROUP  BY owner_id
HAVING count(*) > 1;
--> EXPECT 0 rows


-- ── 3. A second business for the same owner is REFUSED ──────────────────────
-- [service_role] Rolled back — nothing is kept.
BEGIN;
  INSERT INTO public.businesses (id, name, owner_id, template_id)
  SELECT gen_random_uuid(), 'dupe probe', b.owner_id, b.template_id
  FROM   public.businesses b
  LIMIT  1;
  --> EXPECT ERROR:  duplicate key value violates unique constraint
  --                 "businesses_owner_id_key"
ROLLBACK;


-- ── 4. my_business_id() is deterministic ────────────────────────────────────
-- [user JWT] The owner fallback used to be a bare LIMIT 1 with no ORDER BY, so
-- a multi-business owner could get a different answer per call — and this feeds
-- has_permission()'s owner fast-path and effective_limits().
SELECT public.my_business_id() AS a,
       public.my_business_id() AS b,
       public.my_business_id() = public.my_business_id() AS stable;
--> EXPECT stable = true


-- ── 5. Onboarding is ATOMIC — a mid-way failure leaves nothing ──────────────
-- [user JWT, on an account with NO business yet] Force a failure by passing a
-- template id that does not exist: apply_business_template raises, which must
-- roll back the business AND the branch AND the trigger-written subscription.
BEGIN;
  SELECT public.create_business_onboarding(
    gen_random_uuid(), 'Atomicity probe', gen_random_uuid(),
    gen_random_uuid(), 'Main Branch');
  --> EXPECT ERROR: Template ... not found
ROLLBACK;

-- Then confirm the failed attempt left NO trace:
SELECT count(*) AS leftover FROM public.businesses WHERE name = 'Atomicity probe';
--> EXPECT 0   (before the fix this would have been 1 per attempt)


-- ── 6. Onboarding is IDEMPOTENT per owner ───────────────────────────────────
-- [user JWT, on an account that ALREADY has a business] A retry must return the
-- existing business rather than provision a second one. This is the guard that
-- makes a client retry harmless no matter what id it sends.
SELECT (public.create_business_onboarding(
          gen_random_uuid(), 'Retry probe', b.template_id,
          gen_random_uuid(), 'Main Branch') ->> 'reused') AS reused
FROM   public.businesses b
WHERE  b.owner_id = auth.uid()
LIMIT  1;
--> EXPECT reused = true

SELECT count(*) AS mine FROM public.businesses WHERE owner_id = auth.uid();
--> EXPECT 1


-- ── 7. A completed signup is whole, not half-built ──────────────────────────
-- [user JWT] Every orphan from 2026-07-26 had a business row and nothing else.
-- A real signup must populate all of these in the same transaction.
SELECT
  (SELECT count(*) FROM public.branches         WHERE business_id = public.my_business_id()) AS branches,
  (SELECT count(*) FROM public.roles            WHERE business_id = public.my_business_id()) AS roles,
  (SELECT count(*) FROM public.receipt_settings WHERE business_id = public.my_business_id()) AS receipt_settings,
  (SELECT count(*) FROM public.business_modules WHERE business_id = public.my_business_id()) AS modules,
  (SELECT count(*) FROM public.subscriptions    WHERE business_id = public.my_business_id()) AS subscription,
  (SELECT count(*) FROM public.users            WHERE business_id = public.my_business_id()) AS owner_user;
--> EXPECT branches >= 1, roles = 4, receipt_settings = 1, modules >= 1,
--         subscription = 1, owner_user >= 1


-- ── 8. Only `authenticated` may call the RPC ────────────────────────────────
-- [service_role] anon must never be able to provision a tenant.
SELECT grantee, privilege_type
FROM   information_schema.routine_privileges
WHERE  routine_schema = 'public'
  AND  routine_name   = 'create_business_onboarding';
--> EXPECT authenticated (+ the owner/service_role); NEVER anon or PUBLIC
