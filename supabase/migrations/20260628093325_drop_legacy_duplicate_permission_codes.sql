-- Phase 7 (migration/prod drift reconciliation): the permissions catalog had
-- legacy duplicate/orphaned codes left over from an earlier naming scheme,
-- superseded by the codes PermissionKeys (the client's single source of
-- truth) actually uses:
--   pos.refund              -> superseded by pos.refund_sale
--   pos.void                -> superseded by pos.void_sale
--   pos.discount             -> superseded by pos.apply_discount
--   audit.view               -> superseded by audit_logs.view
--   employees.assign_roles  -> superseded by employees.assign_role
--   transactions.refund/view/void -> entirely orphaned family, no active
--     counterpart; no RLS policy, function body, or role_permissions grant
--     references any of these three.
--
-- Verified before dropping: none of the 8 codes above appear in any RLS
-- policy qual/with_check, any function body, or any role_permissions row
-- (rp.allowed = true) for any role. They are inert catalog rows.
--
-- Rollback (re-seed the rows; nothing else referenced them, so this is purely
-- cosmetic to restore):
--   insert into public.permissions (code) values
--     ('pos.refund'), ('pos.void'), ('pos.discount'), ('audit.view'),
--     ('employees.assign_roles'), ('transactions.refund'),
--     ('transactions.view'), ('transactions.void')
--   on conflict (code) do nothing;

delete from public.permissions
where code in (
  'pos.refund',
  'pos.void',
  'pos.discount',
  'audit.view',
  'employees.assign_roles',
  'transactions.refund',
  'transactions.view',
  'transactions.void'
);
