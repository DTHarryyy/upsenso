-- Composite index to support keyset (cursor) pagination on audit_logs.
--
-- The audit log viewer pulls a recent window on sync, then pages older rows
-- on demand ordered by (created_at desc, id desc) filtered by business_id.
-- Today only idx_audit_business (business_id) and idx_audit_created
-- (created_at) exist separately — Postgres has to intersect two indexes for
-- every page. A composite index matching the exact filter+order lets each
-- page (including deep ones) resolve as a single index range scan instead of
-- degrading as the table grows.
--
-- Plain CREATE INDEX (not CONCURRENTLY): this runs inside the standard
-- migration transaction like every other migration in this project; the
-- table is not large enough yet to warrant the non-transactional CONCURRENTLY
-- path. Revisit if audit_logs grows large enough to make this lock visible.
--
-- ROLLBACK:
--   drop index if exists public.idx_audit_logs_business_created_id;

create index if not exists idx_audit_logs_business_created_id
  on public.audit_logs (business_id, created_at desc, id desc);
