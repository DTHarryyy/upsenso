-- ============================================================
-- Audit Logs
-- Append-only ledger of every business action, written by
-- client devices and synced to the server.
-- Rows are immutable after insert — no UPDATE or DELETE.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id   UUID        NOT NULL,
  user_id     UUID        NOT NULL,
  action_type TEXT        NOT NULL CHECK (char_length(action_type) <=  64),
  entity_type TEXT        NOT NULL CHECK (char_length(entity_type) <=  64),
  entity_id   UUID,
  description TEXT        NOT NULL CHECK (char_length(description) <= 500),
  metadata    JSONB       NOT NULL DEFAULT '{}'
                          CHECK (octet_length(metadata::text)      <= 32768),
  device_id   TEXT        NOT NULL DEFAULT 'unknown'
                          CHECK (char_length(device_id)            <=  256),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.audit_logs IS
  'Append-only event ledger. Written by client devices; never updated or deleted.';

-- ── Indexes ────────────────────────────────────────────────────────────────

-- Primary query: newest logs for a business (covers the business_id-only case too)
CREATE INDEX IF NOT EXISTS idx_audit_logs_business_created
  ON public.audit_logs (business_id, created_at DESC);

-- Selective filters
CREATE INDEX IF NOT EXISTS idx_audit_logs_branch_id
  ON public.audit_logs (branch_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id
  ON public.audit_logs (user_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_action_type
  ON public.audit_logs (action_type);

-- ── Row-Level Security ─────────────────────────────────────────────────────

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- INSERT: users may only write logs that belong to their own business
-- AND are attributed to themselves.  Without the user_id check a
-- compromised device could forge entries for other users.
CREATE POLICY "audit_logs_insert"
  ON public.audit_logs
  FOR INSERT
  WITH CHECK (
    business_id = public.my_business_id()
    AND user_id = auth.uid()
  );

-- SELECT: any authenticated member may read all logs within their business.
CREATE POLICY "audit_logs_select"
  ON public.audit_logs
  FOR SELECT
  USING (
    business_id = public.my_business_id()
  );

-- No UPDATE or DELETE policies — audit_logs are immutable by design.
