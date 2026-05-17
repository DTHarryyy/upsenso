-- Add payment_method column to transactions so it syncs across devices.
-- Defaults to 'cash' to match existing rows that were inserted without it.
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS payment_method text NOT NULL DEFAULT 'cash';
