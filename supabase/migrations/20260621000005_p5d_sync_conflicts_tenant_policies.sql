-- Phase 5d — let the client persist LWW-superseded local changes into
-- sync_conflicts (RLS was enabled with zero policies = deny-all). Tenant-scoped
-- so a business only ever sees/writes its own conflict log.
GRANT INSERT, SELECT ON public.sync_conflicts TO authenticated;

CREATE POLICY sync_conflicts_insert ON public.sync_conflicts
  FOR INSERT TO authenticated
  WITH CHECK (business_id = (SELECT get_my_business_id()));

CREATE POLICY sync_conflicts_select ON public.sync_conflicts
  FOR SELECT TO authenticated
  USING (business_id = (SELECT get_my_business_id()));
