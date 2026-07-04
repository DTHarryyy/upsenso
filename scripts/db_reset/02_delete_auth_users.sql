-- Phase 2 — Delete all auth users (zero accounts).
-- Run AFTER 01 so no public row references auth.users.
-- Cascades to auth.identities, auth.sessions, auth.refresh_tokens,
-- auth.mfa_factors, auth.one_time_tokens (all ON DELETE CASCADE to auth.users).
DELETE FROM auth.users;
