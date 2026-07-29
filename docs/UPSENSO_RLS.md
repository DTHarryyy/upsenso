# UPSENSO ROW LEVEL SECURITY (RLS)

This document defines database-level security rules for UPSENSO using PostgreSQL RLS (Supabase).

---

# CORE SECURITY PRINCIPLE

Every query must be scoped by:

- business_id
- optionally branch_id
- employee ownership where applicable

NO DATA SHOULD EVER CROSS BUSINESS BOUNDARIES.

---

# ENABLE RLS ON ALL TABLES

All tables must have:

```sql
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
```

---

# GLOBAL POLICY PATTERN

## 1. BUSINESS ISOLATION

All records must belong to a business.

Standard rule:

```sql
USING (business_id = auth.business_id)
```

or using JWT claim:

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

---

# TABLE POLICIES

## businesses

```sql
USING (id = auth.jwt() ->> 'business_id')
```

Only owner can update:

```sql
WITH CHECK (owner_id = auth.uid())
```

---

## branches

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

---

## employees

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

Employees can only see themselves OR same business:

```sql
USING (
  user_id = auth.uid()
  OR business_id = auth.jwt() ->> 'business_id'
)
```

---

## roles

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

---

## permissions

Global catalog (read-only):

```sql
USING (true)
```

---

## role_permissions

```sql
USING (
  role_id IN (
    SELECT id FROM roles
    WHERE business_id = auth.jwt() ->> 'business_id'
  )
)
```

---

## products

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

---

## product_variants

```sql
USING (
  product_id IN (
    SELECT id FROM products
    WHERE business_id = auth.jwt() ->> 'business_id'
  )
)
```

---

## categories

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

---

## inventory_levels

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

---

## inventory_movements

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

---

## stock_transfers

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

AND branch-level restriction:

```sql
USING (
  from_branch_id IN (
    SELECT branch_id FROM employee_branches
    WHERE employee_id = auth.jwt() ->> 'employee_id'
  )
)
```

---

## transactions

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

Branch restriction:

```sql
USING (
  branch_id IN (
    SELECT branch_id FROM employee_branches
    WHERE employee_id = auth.jwt() ->> 'employee_id'
  )
)
```

---

## transaction_items

```sql
USING (
  transaction_id IN (
    SELECT id FROM transactions
    WHERE business_id = auth.jwt() ->> 'business_id'
  )
)
```

---

## expenses

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

Branch restriction:

```sql
USING (
  branch_id IN (
    SELECT branch_id FROM employee_branches
    WHERE employee_id = auth.jwt() ->> 'employee_id'
  )
)
```

---

## shifts

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

---

## audit_logs

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

---

## fraud_flags

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

---

## notifications

```sql
USING (
  business_id = auth.jwt() ->> 'business_id'
  AND (
    employee_id = auth.jwt() ->> 'employee_id'
    OR employee_id IS NULL
  )
)
```

---

## sync_queue

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

---

## sync_conflicts

```sql
USING (business_id = auth.jwt() ->> 'business_id')
```

---

## user_permissions

```sql
USING (business_id = (auth.jwt() ->> 'business_id')::uuid)
```

Only owners and admins may write:

```sql
WITH CHECK (
  business_id = (auth.jwt() ->> 'business_id')::uuid
  AND (auth.jwt() ->> 'role') IN ('owner', 'admin')
)
```

---

## branch_permissions

```sql
USING (business_id = (auth.jwt() ->> 'business_id')::uuid)
```

Only owners and admins may write:

```sql
WITH CHECK (
  business_id = (auth.jwt() ->> 'business_id')::uuid
  AND (auth.jwt() ->> 'role') IN ('owner', 'admin')
)
```

---

## permission_policies

```sql
USING (business_id = (auth.jwt() ->> 'business_id')::uuid)
```

---

## effective_permissions

Read: employees see only their own snapshot; admins/owners see all:

```sql
USING (
  business_id = (auth.jwt() ->> 'business_id')::uuid
  AND (
    employee_id = (auth.jwt() ->> 'employee_id')::uuid
    OR (auth.jwt() ->> 'role') IN ('owner', 'admin')
  )
)
```

No direct INSERT/UPDATE/DELETE — only the `compute_employee_permissions` SECURITY DEFINER function may write:

```sql
-- All write policies return false for direct access
CREATE POLICY effective_permissions_no_direct_write
  ON effective_permissions FOR INSERT USING (false);
```

---

# INSERT POLICIES

Standard rule:

```sql
WITH CHECK (business_id = auth.jwt() ->> 'business_id')
```

Applied to:

- products
- inventory
- expenses
- transactions
- employees
- branches

---

# UPDATE POLICIES

Only allow update if:

- Same business_id
- AND permission check passes in backend

Example:

```sql
USING (business_id = auth.jwt() ->> 'business_id')
WITH CHECK (business_id = auth.jwt() ->> 'business_id')
```

---

# DELETE POLICIES

Highly restricted.

Only allowed for:

- Admin
- Owner roles

Example:

```sql
USING (
  business_id = auth.jwt() ->> 'business_id'
  AND auth.jwt() ->> 'role' IN ('owner', 'admin')
)
```

---

# SECURITY LAYERS (IMPORTANT)

UPSENSO uses 3 layers:

## 1. UI Layer
- hide buttons using permissions

## 2. API Layer
- enforce permission checks

## 3. DATABASE LAYER (RLS)
- enforce business isolation

---

# CRITICAL RULES

- NEVER trust frontend alone
- NEVER bypass RLS
- NEVER allow cross-business access
- NEVER expose raw tables without policy
- ALWAYS enforce business_id filtering
- ALWAYS enforce employee branch mapping

---

# BILLING TABLES (M7.1)

The billing tables follow a different rule from the rest of the schema, and the
generic patterns above do **not** apply to them.

> ⚠️ The `auth.jwt() ->> 'business_id'` pattern documented earlier in this file is
> **not** what the billing migrations use. They call `public.get_my_business_id()`.
> Verify against `supabase/migrations/`, which is the source of truth.

**Clients get SELECT only. Every write is service-role.** A client that could
write its own `subscriptions` row could grant itself any plan, so there is no
tenant-scoped INSERT/UPDATE/DELETE policy anywhere in this group — and since
`20260728000001` the DML privilege itself is revoked from `authenticated`, so a
future permissive policy cannot re-open it.

| Table | Client access | Written by |
|---|---|---|
| `subscriptions` | SELECT own (`subscriptions_select_own`) | `apply_play_subscription` / `expire_play_subscription` / `admin_grant_subscription` (SECURITY DEFINER, service_role only) |
| `subscription_events` | SELECT own | `record_subscription_event` — hash-chained |
| `billing_payments` | SELECT own | verify-play-purchase, google-play-rtdn |
| `play_purchase_tokens` | **none** — invisible | verify-play-purchase |
| `billing_webhook_events` | **none** | google-play-rtdn |
| `trial_claims` | **none** | signup trigger |
| `play_product_map` | SELECT where `is_active` | migration / manual seed |
| `plans`, `plan_limits`, `plan_addons` | SELECT all (public catalog) | migration |
| `billing_settings` | **none** since `20260728000001` | migration / manual |

**The cloud gate.** `20260708000001_cloud_gate_rls.sql` adds a RESTRICTIVE
`has_cloud_access()` policy to the write path of 25 business-data tables. SELECT
is deliberately ungated so a lapsed tenant keeps reading its own frozen data, and
the identity plane (businesses, branches, employees, roles, modules) is ungated so
they can still sign in and pay.

> **`has_cloud_access()` returns TRUE for everyone while
> `billing_settings.cloud_gate_enforced` is FALSE — its default.** No migration
> sets it. Until it is flipped, every RESTRICTIVE gate above is inert and the
> local Drift `entitlement_cache` is the only thing standing between a user and
> cloud sync — and that cache is unsigned and trivially editable. Treat the
> paywall as advisory until this flag is confirmed TRUE in prod.

**Verifying.** `tool/billing_rls_checks.sql` §7–§11 is the runbook: run it against
a preview branch, not prod. It asserts that a direct
`UPDATE subscriptions SET plan_code='growth'` as `authenticated` affects zero
rows, that structural caps reject an over-limit INSERT, and that a lapsed tenant
can read but not write.

---

# OFFLINE SYNC IMPACT

All sync operations must:

- include business_id
- be validated server-side
- be rejected if mismatched

Conflicts must still respect RLS boundaries

---

# FINAL NOTE

RLS is the FINAL SECURITY GATE.

Even if:

- frontend is compromised
- API is misused

RLS must still prevent data leaks.