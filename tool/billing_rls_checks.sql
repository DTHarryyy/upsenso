-- =============================================================================
-- M7.1 billing — server-side enforcement verification runbook.
--
-- These checks PROVE the paywall is not client-bypassable (design §6.3, §11).
-- Run against a DEV / preview branch project AFTER applying the billing
-- migrations — NEVER blind-run against prod, and NEVER `supabase db push`.
--
-- HOW TO RUN
--   Each block notes the role it must run as:
--     [service_role]  — the SQL editor / a service-key connection
--     [free JWT]      — a signed-in user whose business is on Free (or lapsed)
--     [paid JWT]      — a signed-in user whose business is on a cloud tier
--   Get a user JWT by signing in that account in the app and copying the access
--   token, or use the Supabase dashboard "Run as user" feature.
--
-- Expected results are noted inline as  --> EXPECT ...
-- =============================================================================


-- ── 0. Precondition: the enforcement flag ───────────────────────────────────
-- [service_role] The gate is inert until this is TRUE. Flip it only after the
-- entitlement-aware client is released.
--   UPDATE billing_settings SET cloud_gate_enforced = true WHERE id = 1;
SELECT id, cloud_gate_enforced, trial_days FROM billing_settings;   --> EXPECT 1 row


-- ── 1. Free is local-only: business-data writes are blocked (§11) ───────────
-- [free JWT] Any INSERT into a business-data-plane table must be denied by the
-- has_cloud_access() RESTRICTIVE policy.
--   INSERT INTO products (id, business_id, name) VALUES (gen_random_uuid(), get_my_business_id(), 'x');
--     --> EXPECT: new row violates row-level security policy for table "products"
--   INSERT INTO transactions (...) ...      --> EXPECT: RLS denial
-- SELECT still works (frozen copy stays readable):
--   SELECT count(*) FROM products;          --> EXPECT: succeeds
-- Identity-plane writes still work on Free (onboarding must not break):
--   INSERT INTO branches (id, business_id, name) VALUES (gen_random_uuid(), get_my_business_id(), 'B2');
--     --> EXPECT: succeeds IF under the branch cap (see §3), else cap denial


-- ── 2. Paid tenant can write business data (§11) ────────────────────────────
-- [paid JWT]
--   INSERT INTO products (id, business_id, name) VALUES (gen_random_uuid(), get_my_business_id(), 'ok');
--     --> EXPECT: succeeds


-- ── 3. Structural caps enforced server-side (§11) ───────────────────────────
-- [paid JWT] With branches already AT max_branches:
--   INSERT INTO branches (id, business_id, name) VALUES (gen_random_uuid(), get_my_business_id(), 'over');
--     --> EXPECT: RLS denial (branches_cap_insert)
-- Effective cap = snapshot + add-ons. After a +branch add-on:
--   [service_role] SELECT apply_subscription_addon(get_my_business_id_for(<biz>), 'branch', 1, 'admin');
--   [paid JWT] the same INSERT now --> EXPECT: succeeds
-- Seat cap via the RPC (RLS is bypassed by SECURITY DEFINER, so the in-function
-- check is the real gate):
--   [paid JWT] SELECT create_employee_auth_account('a@b.co','password123', ...);
--     with active seats already AT max_seats --> EXPECT: SEAT_LIMIT_REACHED
-- Suspend frees a seat; reactivation re-checks:
--   UPDATE employees SET is_active = false WHERE id = <e>;   -- frees a seat
--   UPDATE employees SET is_active = true  WHERE id = <e>;   -- OK if under cap,
--                                                            -- else SEAT_LIMIT_REACHED


-- ── 4. Device cap: online-only register RPC (§11) ───────────────────────────
-- [paid JWT] Registering the (max_devices+1)-th device:
--   SELECT register_device('uid-N', 'Tablet', 'android');   --> EXPECT: 'cap_reached'
-- Revoke one, then register succeeds:
--   SELECT revoke_device('uid-1');                          -- needs billing.manage
--   SELECT register_device('uid-N', 'Tablet', 'android');   --> EXPECT: 'registered'


-- ── 5. Grandfathering / plan versioning (§4.9, §11) ─────────────────────────
-- [service_role] Grant v1, then publish a repriced v2, and confirm the existing
-- subscription's entitlement is UNCHANGED (it resolves from the pinned snapshot).
--   SELECT admin_grant_subscription('<biz>', 'growth', 1, 'monthly', '{}'::jsonb, 'admin');
--   INSERT INTO plans (code, version, name, price_monthly, is_active)
--     VALUES ('growth', 2, 'Growth', 699, true);
--   INSERT INTO plan_limits (plan_code, plan_version, cloud_enabled, max_branches, max_seats, max_devices, feature_flags)
--     VALUES ('growth', 2, true, 3, 10, 5, '{"crm":"full","procurement":true,"reports":"full","cloud_audit":true}');
--   SELECT (entitlement_snapshot->>'price_monthly') FROM subscriptions WHERE business_id = '<biz>';
--     --> EXPECT: 499  (NOT 699 — the existing sub keeps its sold price)


-- ── 6. subscription_events hash chain verifies (§11) ────────────────────────
-- [service_role] The chain must be contiguous and fork-proof.
SELECT business_id, seq, event_type,
       (hash = encode(digest(
          coalesce(previous_hash,'') || '|' ||
          business_id::text || '|' || seq::text || '|' || event_type || '|' ||
          actor || '|' || payload::text || '|' ||
          to_char(created_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
        'sha256'),'hex')) AS hash_ok
FROM subscription_events
ORDER BY business_id, seq;
--   --> EXPECT: hash_ok = true for every row.
-- A forked seq is impossible:
--   INSERT INTO subscription_events (business_id, seq, event_type, actor, hash)
--     VALUES ('<biz>', 1, 'x', 'admin', 'deadbeef');
--     --> EXPECT: duplicate key value violates unique constraint (business_id, seq)


-- ── 7. Manual grant ≡ webhook grant (§11) ───────────────────────────────────
-- Both write through admin_grant_subscription. Grant two businesses the same
-- plan (one "as admin", one simulating the webhook actor) and diff the rows:
--   SELECT plan_code, plan_version, status, entitlement_snapshot
--   FROM subscriptions WHERE business_id IN ('<biz_admin>', '<biz_webhook>');
--     --> EXPECT: identical plan_code/version/status/snapshot shape.


-- ── 8. Service-role-only writes (§8) ────────────────────────────────────────
-- [free JWT / paid JWT] A client can never write the billing tables directly:
--   INSERT INTO subscriptions (business_id, plan_code, plan_version, status, entitlement_snapshot)
--     VALUES (get_my_business_id(), 'growth', 1, 'active', '{}');
--     --> EXPECT: RLS denial (no INSERT policy exists for authenticated)
--   UPDATE subscriptions SET plan_code = 'growth' WHERE business_id = get_my_business_id();
--     --> EXPECT: 0 rows affected / denied


-- ── 9. create-checkout requires billing.manage (edge fn, curl) ──────────────
-- The edge function 403s any authenticated caller without billing.manage
-- (owner bypass is inside has_permission). Verify with a cashier JWT:
--   curl -s -X POST "$SUPABASE_URL/functions/v1/create-checkout" \
--     -H "Authorization: Bearer <cashier JWT>" -H "Content-Type: application/json" \
--     -d '{"kind":"plan","plan_code":"starter","plan_version":1}'
--     --> EXPECT: 403 {"error":"Not allowed to manage billing"}
-- Same call with an owner JWT --> EXPECT: 200 {"checkout_url": ...}


-- ── 10. create-checkout rate limit (edge fn, curl) ──────────────────────────
-- At most 5 open (pending, <1h old) checkouts per business. Fire the §9 owner
-- call 6× without paying:
--   --> EXPECT: calls 1-5 return 200; call 6 returns 429.
-- Pending rows older than 24h are auto-expired on the next call:
--   [service_role] SELECT count(*) FROM billing_payments
--     WHERE status = 'pending' AND created_at < now() - interval '24 hours';
--     --> EXPECT: 0 right after any successful create-checkout invocation.


-- ── 11. Webhook amount-mismatch rejection (manual) ──────────────────────────
-- The webhook compares the paid amount (centavos) in the event payload against
-- billing_payments.amount and refuses the grant on mismatch. Simulate by
-- sending a signed test webhook whose amount != the pending row:
--   --> EXPECT: 200 {"ok":true,"note":"amount mismatch — not granted"},
--               billing_payments.status = 'failed', subscription UNCHANGED.
-- (Signing: HMAC-SHA256 over "<t>.<rawBody>" with PAYMONGO_WEBHOOK_SECRET,
--  header Paymongo-Signature: t=<unix>,te=<sig> in test mode.)


-- ── 12. Trial anti-farming: signup_device_uid dedup (§6.2) ───────────────────
-- [service_role] New-client signups stamp businesses.signup_device_uid; the
-- second business created from the same device gets a zero-length trial:
--   SELECT b.id, b.signup_device_uid, s.trial_end > now() AS has_trial
--   FROM businesses b JOIN subscriptions s ON s.business_id = b.id
--   WHERE b.signup_device_uid = '<uid>' ORDER BY b.created_at;
--     --> EXPECT: first row has_trial = true, later rows has_trial = false
--   SELECT event_type FROM subscription_events WHERE business_id = '<biz2>';
--     --> EXPECT: includes 'trial_denied_device_reuse'
