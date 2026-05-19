-- ============================================================
-- employees
--
-- Stores employee records scoped to a business.
-- Sync columns (sync_status, last_sync_attempt, sync_error)
-- are local-only and intentionally excluded from this table.
--
-- Normalization notes:
--   • branch_id uses a COMPOSITE FK (business_id, branch_id) →
--     (branches.business_id, branches.id) so a row can never
--     reference a branch that belongs to a different business.
--   • email is unique per business (case-insensitive).
--   • branch_id ON DELETE RESTRICT — you must reassign or archive
--     employees before a branch can be deleted.
-- ============================================================

-- Prerequisite: composite unique index on branches so the FK below can
-- reference it.  CREATE UNIQUE INDEX IF NOT EXISTS is idempotent.
CREATE UNIQUE INDEX IF NOT EXISTS branches_biz_id_uidx
  ON public.branches (business_id, id);

-- ---------------------------------------------------------------------------
CREATE TABLE public.employees (
  id                 uuid        PRIMARY KEY,
  business_id        uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id          uuid        NOT NULL,
  auth_user_id       uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
  employee_code      text        NOT NULL,
  full_name          text        NOT NULL,
  email              text        NOT NULL,
  phone              text,
  role               text        NOT NULL
                                 CHECK (role IN ('owner','branch_manager','cashier','inventory_staff')),
  status             text        NOT NULL DEFAULT 'active'
                                 CHECK (status IN ('active','suspended','archived')),
  profile_image_url  text,
  hired_at           timestamptz NOT NULL,
  archived_at        timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),

  -- Composite FK: branch_id must belong to the same business.
  -- RESTRICT prevents silent data loss when a branch is deleted.
  CONSTRAINT employees_branch_fk
    FOREIGN KEY (business_id, branch_id)
    REFERENCES public.branches (business_id, id)
    ON DELETE RESTRICT,

  -- DB-level email format guard (permissive but catches obvious garbage).
  CONSTRAINT employees_email_format
    CHECK (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

-- Unique employee code per business
CREATE UNIQUE INDEX employees_code_business_uidx
  ON public.employees (business_id, employee_code);

-- Unique email per business (case-insensitive)
CREATE UNIQUE INDEX employees_email_business_uidx
  ON public.employees (business_id, lower(email));

-- Fast look-ups
CREATE INDEX employees_business_idx ON public.employees (business_id);
CREATE INDEX employees_branch_idx   ON public.employees (business_id, branch_id);
CREATE INDEX employees_status_idx   ON public.employees (business_id, status)
  WHERE status <> 'archived';   -- partial index — active/suspended queries only

CREATE TRIGGER trg_employees_updated_at
  BEFORE UPDATE ON public.employees
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- =============================================================================
-- RLS
-- =============================================================================

ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- SELECT — super-admins see all employees in the business;
--          branch staff see only their own branch.
CREATE POLICY "emp_select" ON public.employees
  FOR SELECT TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (public.i_am_super_admin() OR branch_id = public.my_branch_id())
  );

-- INSERT / UPDATE / DELETE — super-admins (owners + branch managers) only.
CREATE POLICY "emp_insert" ON public.employees
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id = public.my_business_id()
    AND public.i_am_super_admin()
  );

CREATE POLICY "emp_update" ON public.employees
  FOR UPDATE TO authenticated
  USING  (business_id = public.my_business_id() AND public.i_am_super_admin())
  WITH CHECK (business_id = public.my_business_id() AND public.i_am_super_admin());

CREATE POLICY "emp_delete" ON public.employees
  FOR DELETE TO authenticated
  USING  (business_id = public.my_business_id() AND public.i_am_super_admin());
