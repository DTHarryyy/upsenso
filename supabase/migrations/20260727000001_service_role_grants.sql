-- =============================================================================
-- Restore `service_role`'s table privileges (P0 — Play Billing release blocker).
--
-- FINDING (2026-07-27 audit, docs/billing-audit-plan.md §2):
--   service_role was absent from EVERY table ACL in `public`
--   (relacl = {postgres=…,authenticated=…}) and is a member of no role, so it
--   inherited nothing. It does hold rolbypassrls, which bypasses RLS POLICIES
--   but NOT table GRANTs — which is why the setup looked correctly hardened
--   while every service-role write failed with 42501.
--
-- Consequences this fixes:
--   * verify-play-purchase: the play_product_map lookup in resolvePlan() died
--     with 42501, so planRow came back null and the function answered
--     400 "Unknown product" — surfacing in-app as "We couldn't confirm your
--     purchase yet". No purchase has ever been granted.
--   * google-play-rtdn: the billing_webhook_events insert died with 42501,
--     returning 500 to every Pub/Sub delivery and driving an unbounded retry
--     loop (~2–5 req/s sustained). billing_webhook_events had 0 rows.
--
-- This restores the stock Supabase posture. It is NOT a widening of what the
-- service key can reach: service_role already bypasses RLS, so the key's data
-- reach is unchanged — it simply could not execute at all. The key is
-- server-only (edge function secrets) and is never shipped to a client.
--
-- Scope is schema-wide on purpose: the privileges are missing from every table
-- (products, businesses, employees…), not just the billing surface, so a
-- billing-only grant would leave the same defect to resurface elsewhere.
--
-- ROLLBACK:
--   ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM service_role;
--   ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM service_role;
--   REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM service_role;
--   REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM service_role;
--   REVOKE USAGE ON SCHEMA public FROM service_role;
-- =============================================================================

GRANT USAGE ON SCHEMA public TO service_role;

-- DML only. No TRUNCATE / REFERENCES / TRIGGER — nothing in the server-side
-- paths needs them, and withholding them keeps a leaked key from reshaping the
-- schema or mass-wiping a table.
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO service_role;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- Future tables/sequences created by the migration owner inherit the same grants,
-- so this defect cannot silently return with the next migration.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO service_role;
