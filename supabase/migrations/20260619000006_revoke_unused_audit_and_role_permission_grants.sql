-- audit_logs is append-only by design; the client never calls .update() on
-- it (verified). Revoking removes attack surface even if a future policy
-- regresses.
-- Rollback: grant update on public.audit_logs to authenticated;
revoke update on public.audit_logs from authenticated;

-- role_permissions has RLS enabled with no policy (deny-all already, in
-- practice) but still carries a SELECT grant to authenticated that nothing
-- uses directly — the client and RPCs (get_my_permissions, etc.) read this
-- table only via SECURITY DEFINER functions, which bypass RLS/grants
-- entirely. Revoking removes a redundant grant rather than changing behavior.
-- Rollback: grant select on public.role_permissions to authenticated;
revoke select on public.role_permissions from authenticated;
