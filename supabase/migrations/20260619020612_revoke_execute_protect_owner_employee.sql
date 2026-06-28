-- Trigger functions must not be callable via PostgREST RPC.
-- Reconciliation note (2026-06-28): applied to prod on 2026-06-19, captured
-- here verbatim because it was missing from this repo.
-- Rollback: grant execute on function public.protect_owner_employee() to authenticated;
revoke execute on function public.protect_owner_employee() from public, anon, authenticated;
