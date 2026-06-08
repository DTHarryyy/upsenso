-- Migration: add role_name to employees
-- Stores a denormalized display name (e.g. "Cashier", "Branch Manager") on the
-- employee row so that clients without a role_id UUID can still display the
-- correct label, and so sync pull never needs to fall back to local-only state.

ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS role_name text;
