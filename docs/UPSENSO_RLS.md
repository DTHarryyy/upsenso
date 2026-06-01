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