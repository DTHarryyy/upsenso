-- =============================================================================
-- PHASE 4 — audit_logs normalization + anomaly model   (REVIEW ONLY — DO NOT APPLY)
-- Risk: HIGH (tamper-evidence). audit_logs is normalized, NOT exempt — but every
-- change here must preserve the hash chain. Coordinate a hash-version bump
-- (audit_hash.dart v3) IN THE SAME RELEASE. Impacts sync + integrity.
-- =============================================================================

-- GUARDING PRINCIPLE: the hash is computed over each row's canonical payload.
-- Reference only by IMMUTABLE CODES (never mutable display strings) so historical
-- rows' hashes never drift. Legacy rows (hash_version NULL/1) are already skipped
-- by the verifier; new rows adopt v3 canonical form that EXCLUDES any field moved
-- out of the hashed payload.

-- 1) action_type / entity_type → reference tables keyed by stable code.
CREATE TABLE IF NOT EXISTS public.audit_action_types (
  code         text PRIMARY KEY,          -- immutable; what the hash references
  display_name text NOT NULL,
  category     text,
  is_system    boolean NOT NULL DEFAULT true
);
CREATE TABLE IF NOT EXISTS public.audit_entity_types (
  code text PRIMARY KEY, display_name text NOT NULL
);
-- Seed from existing distinct values, then (LATER release) FK the columns:
--   INSERT ... SELECT DISTINCT action_type ...
--   ALTER TABLE audit_logs ADD CONSTRAINT audit_action_fk
--     FOREIGN KEY (action_type) REFERENCES audit_action_types(code) NOT VALID;
-- Display names live in the lookup; audit_logs keeps the code (hash-stable).
-- Lets client + server share ONE enum source (removes the brittle string coupling
-- the fraud plan deferred).

-- 2) Retire the audit_logs.device_id LABEL (superseded by device_uid + devices).
--    The client STILL pushes device_id today → this is a COORDINATED change:
--    (a) client stops sending device_id, reads label via devices(device_uid);
--    (b) exclude device_id from the v3 canonical payload;
--    (c) LATER release: ALTER TABLE audit_logs DROP COLUMN device_id.
--    ROLLBACK: re-add nullable device_id default 'unknown'.

-- 3) ANOMALY data out of metadata jsonb → a normalized model reconciled with
--    fraud_flags. Today anomaly context lives as free JSON in audit_logs.metadata
--    and separately in fraud_flags.evidence/related_ids (jsonb). Target:
--    - audit_logs.metadata keeps genuinely open-ended context (stays jsonb, in hash).
--    - Structured, queryable anomaly signals move to typed columns / a child table
--      so anomaly detection queries a relational model, not JSON scans:
CREATE TABLE IF NOT EXISTS public.audit_anomaly_signals (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  audit_log_id  text NOT NULL,            -- soft ref (audit rows are immutable/append-only)
  business_id   uuid NOT NULL,
  signal_code   text NOT NULL,            -- FK-able to a signal catalog
  numeric_value numeric,
  created_at    timestamptz NOT NULL DEFAULT now()
);
--    - fraud_flags.rule_code / severity → reference tables (severity already has a
--      CHECK; a table makes it FK-enforced + describable). related_ids stays jsonb
--      only if genuinely polymorphic; otherwise a fraud_flag_links child table.
-- ⚠️ Extraction must NOT alter the hashed metadata of EXISTING rows. Only new (v3)
--    rows write the normalized columns AND omit them from the canonical payload.

-- ROLLBACK for §3: DROP TABLE audit_anomaly_signals; (no source rows altered).
