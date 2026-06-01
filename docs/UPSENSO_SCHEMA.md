# UPSENSO DATABASE SCHEMA

This document describes the current UPSENSO database structure.

Database:
- PostgreSQL
- Supabase

Primary key type:
- UUID

Architecture:
- Multi-tenant
- Multi-branch
- Offline-first

---

# BUSINESS STRUCTURE

## businesses

Represents a company using UPSENSO.

| Column | Type |
|----------|----------|
| id | uuid |
| name | text |
| owner_id | uuid |
| created_at | timestamptz |
| is_active | boolean |

Relationships:

businesses
→ branches
→ employees
→ products
→ expenses
→ transactions

---

## branches

Represents a physical branch.

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| name | text |
| location | text |
| created_at | timestamptz |

Relationships:

branch
→ inventory
→ expenses
→ transactions
→ shifts

---

# MODULE SYSTEM

## modules

System-defined modules.

Examples:

- POS
- Inventory
- Expenses
- Reports
- Employees

| Column | Type |
|----------|----------|
| id | uuid |
| code | text |
| name | text |
| description | text |

---

## business_modules

Determines which modules are enabled.

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| module_id | uuid |
| enabled | boolean |

Example:

Inventory disabled

Result:

- Inventory menu hidden
- Inventory APIs blocked

---

# SETTINGS

## business_settings

Stores dynamic business configuration.

| Column | Type |
|----------|----------|
| business_id | uuid |
| settings | jsonb |
| updated_at | timestamptz |

Examples:

```json
{
  "currency": "PHP",
  "timezone": "Asia/Manila",
  "tax_enabled": true
}
```

---

## receipt_settings

Receipt customization.

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| header_text | text |
| footer_text | text |
| show_logo | boolean |
| show_tax | boolean |
| paper_size | text |
| created_at | timestamptz |
| updated_at | timestamptz |

---

# EMPLOYEE SYSTEM

## employees

Represents a business member.

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| user_id | uuid |
| full_name | text |
| created_at | timestamptz |
| is_active | boolean |

Relationships:

employee
→ roles
→ branches
→ transactions
→ expenses
→ audit_logs

---

## employee_roles

Many-to-many mapping.

| Column | Type |
|----------|----------|
| employee_id | uuid |
| role_id | uuid |

---

## employee_branches

Controls branch assignments.

| Column | Type |
|----------|----------|
| employee_id | uuid |
| branch_id | uuid |

An employee can belong to multiple branches.

---

# ROLE & PERMISSION SYSTEM

## roles

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| name | text |
| level | integer |
| priority | integer |
| is_system | boolean |
| created_at | timestamptz |

Examples:

Owner
Admin
Manager
Cashier
Inventory Staff

---

## permissions

Master permission catalog.

| Column | Type |
|----------|----------|
| id | uuid |
| code | text |
| module | text |
| action | text |
| description | text |
| display_name | text |
| is_dangerous | boolean |

Examples:

pos.use
inventory.adjust
expenses.approve

---

## role_permissions

Permission matrix.

| Column | Type |
|----------|----------|
| role_id | uuid |
| permission_id | uuid |
| allowed | boolean |

---

# PRODUCT SYSTEM

## categories

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| name | text |
| created_at | timestamptz |

---

## units

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| name | text |
| symbol | text |
| created_at | timestamptz |

Examples:

Piece
Kg
Liter

---

## products

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| category_id | uuid |
| unit_id | uuid |
| name | text |
| base_price | numeric |
| is_active | boolean |
| created_at | timestamptz |

---

## product_variants

| Column | Type |
|----------|----------|
| id | uuid |
| product_id | uuid |
| sku | text |
| price | numeric |

Examples:

Coffee
- Small
- Medium
- Large

---

## suppliers

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| name | text |
| contact_person | text |
| phone | text |
| email | text |
| address | text |
| is_active | boolean |
| created_at | timestamptz |

---

# INVENTORY SYSTEM

## inventory_levels

Current stock per branch.

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| branch_id | uuid |
| product_variant_id | uuid |
| quantity | numeric |
| updated_at | timestamptz |

---

## inventory_movements

Inventory ledger.

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| branch_id | uuid |
| product_variant_id | uuid |
| type | text |
| qty | numeric |
| reference_id | uuid |
| created_at | timestamptz |

Movement Types:

- RECEIVE
- ISSUE
- ADJUSTMENT
- SALE
- TRANSFER_IN
- TRANSFER_OUT

---

## stock_transfers

Branch-to-branch transfers.

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| from_branch_id | uuid |
| to_branch_id | uuid |
| created_by | uuid |
| status | text |
| notes | text |
| created_at | timestamptz |

---

# SALES SYSTEM

## shifts

Cashier shift tracking.

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| branch_id | uuid |
| employee_id | uuid |
| opening_cash | numeric |
| closing_cash | numeric |
| opened_at | timestamptz |
| closed_at | timestamptz |
| status | text |
| created_at | timestamptz |

---

## transactions

Sales header.

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| branch_id | uuid |
| employee_id | uuid |
| total | numeric |
| payment_method | text |
| transaction_number | text |
| receipt_number | text |
| created_at | timestamptz |

---

## transaction_items

Items sold.

| Column | Type |
|----------|----------|
| id | uuid |
| transaction_id | uuid |
| product_variant_id | uuid |
| qty | numeric |
| price | numeric |

---

## transaction_payments

Payment breakdown.

| Column | Type |
|----------|----------|
| id | uuid |
| transaction_id | uuid |
| payment_method | text |
| amount | numeric |

Supports:

- Cash
- GCash
- Maya
- Card
- Mixed Payments

---

# EXPENSE SYSTEM

## expense_categories

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| name | text |
| created_at | timestamptz |

---

## expenses

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| branch_id | uuid |
| employee_id | uuid |
| expense_category_id | uuid |
| amount | numeric |
| description | text |
| receipt_url | text |
| status | text |
| approved_by | uuid |
| approved_at | timestamptz |
| created_at | timestamptz |

Statuses:

- pending
- approved
- rejected

---

# SECURITY SYSTEM

## audit_logs

Immutable audit records.

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| employee_id | uuid |
| action | text |
| entity_type | text |
| entity_id | uuid |
| metadata | jsonb |
| previous_hash | text |
| hash | text |
| created_at | timestamptz |

---

## fraud_flags

Fraud detection records.

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| employee_id | uuid |
| severity | text |
| rule_code | text |
| description | text |
| resolved | boolean |
| created_at | timestamptz |

---

## notifications

System alerts.

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| employee_id | uuid |
| title | text |
| message | text |
| is_read | boolean |
| created_at | timestamptz |

---

# OFFLINE SYNC SYSTEM

## sync_queue

Pending sync operations.

| Column | Type |
|----------|----------|
| id | uuid |
| device_id | text |
| business_id | uuid |
| table_name | text |
| operation | text |
| payload | jsonb |
| status | text |
| created_at | timestamptz |

Statuses:

- pending
- synced
- failed

---

## sync_conflicts

Conflict tracking.

| Column | Type |
|----------|----------|
| id | uuid |
| business_id | uuid |
| table_name | text |
| record_id | uuid |
| local_data | jsonb |
| remote_data | jsonb |
| resolution | text |
| resolved_by | uuid |
| resolved_at | timestamptz |
| created_at | timestamptz |

Statuses:

- pending
- local_wins
- remote_wins
- merged

---

# DESIGN RULES

Every operational table should contain:

- business_id

Branch-specific tables should contain:

- branch_id

All entities use UUID primary keys.

Audit logs are append-only.

Inventory changes must create movement records.

Permissions must never be hardcoded.

All new features must support:

- Offline Mode
- Multi-Branch
- Audit Logging
- Permission Checks
- AI Queryability
