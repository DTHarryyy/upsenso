# UPSENSO AI CONTEXT

## Project Overview

UPSENSO is an offline-first, multi-branch Business Management and POS platform.

The goal is to provide small and medium businesses with a unified system for:

- Point of Sale (POS)
- Inventory Management
- Expense Tracking
- Employee Management
- Role-Based Access Control
- Fraud Detection
- Audit Trails
- Multi-Branch Operations
- Offline Sync
- Business Analytics
- AI Business Assistant

This project is being developed as a capstone project but follows production-grade architecture principles.

---

# Core Principles

## 1. Offline First

UPSENSO must continue operating without internet.

Critical operations that must work offline:

- Sales
- Inventory updates
- Expense recording
- Employee operations
- Permission checks
- Audit logging

Changes are stored locally and synchronized when internet becomes available.

---

## 2. Multi-Branch Architecture

A business may have multiple branches.

All operational records belong to:

- business_id

Most operational records also belong to:

- branch_id

Examples:

Transactions:
- business_id
- branch_id

Inventory:
- business_id
- branch_id

Expenses:
- business_id
- branch_id

Reports can be generated:

- Per branch
- Across all branches

---

## 3. Security First

UPSENSO uses:

- Role-Based Access Control (RBAC)
- Audit Logging
- Fraud Detection
- Tamper-Evident Audit Chain

Every sensitive action should:

1. Check permissions
2. Generate audit logs
3. Trigger fraud rules when applicable

---

## 4. AI Friendly Architecture

All business data is structured so future AI systems can query:

- Sales
- Inventory
- Expenses
- Employee activity
- Fraud alerts
- Audit logs

through SQL and analytics pipelines.

---

# Current Database Structure

Major tables:

## Business

businesses
branches
business_modules
business_settings
receipt_settings

## Users

employees
employee_roles
employee_branches

## Permissions

roles
permissions
role_permissions

## Products

products
product_variants
categories
units
suppliers

## Inventory

inventory_levels
inventory_movements
stock_transfers

## Sales

transactions
transaction_items
transaction_payments
shifts

## Expenses

expenses
expense_categories

## Security

audit_logs
fraud_flags
notifications

## Offline Sync

sync_queue
sync_conflicts

---

# Permission System

UPSENSO uses dynamic permissions.

Permissions are stored in database.

Examples:

pos.use
pos.discount
pos.refund
products.create
products.update
inventory.adjust
inventory.transfer
expenses.approve
employees.assign_roles
settings.update

Roles are collections of permissions.

Employees receive permissions through assigned roles.

Permission Flow:

Employee
→ Roles
→ Permissions

Permission checking should never be hardcoded.

Always use permission codes.

Example:

BAD:

if (role == 'admin')

GOOD:

if (hasPermission('inventory.adjust'))

---

# Module System

UPSENSO supports feature toggling.

Tables:

modules
business_modules

Example:

POS enabled
Inventory enabled
Expenses enabled

A business owner can disable modules.

Disabled modules should:

- disappear from navigation
- block access
- prevent actions

Example:

if inventory module disabled:
- inventory screens hidden
- inventory API blocked

---

# Audit Logging

Every important action should generate an audit log.

Examples:

Create Product
Update Product
Delete Product
Inventory Adjustment
Refund
Void Transaction
Approve Expense
Role Changes

Audit fields:

- employee_id
- action
- entity_type
- entity_id
- metadata
- previous_hash
- hash
- created_at

The audit system is append-only.

Never modify audit records.

---

# Fraud Detection

UPSENSO includes fraud detection.

Current fraud table:

fraud_flags

Fraud severity:

LOW
MEDIUM
HIGH
CRITICAL

Examples of future fraud rules:

Multiple refunds in short period

Large inventory adjustments

Repeated void transactions

Sales after shift close

Unusual expense approvals

Role escalation attempts

Audit tampering attempts

Fraud alerts generate:

fraud_flags
notifications

---

# Inventory Rules

Inventory is tracked per branch.

Current stock:

inventory_levels

Movement history:

inventory_movements

Never directly modify inventory quantities without creating movement records.

Inventory adjustments should:

1. Create movement
2. Update inventory level
3. Create audit log

---

# Sales Rules

Transactions consist of:

transactions
transaction_items
transaction_payments

Sales should:

1. Create transaction
2. Create transaction items
3. Create payment records
4. Update inventory
5. Create audit log

Transactions must work offline.

---

# Expense Workflow

Expense statuses:

pending
approved
rejected

Approval requires:

expenses.approve permission

Approvals should:

- update status
- store approver
- generate audit log

---

# Offline Sync Architecture

UPSENSO is offline-first.

Local actions are stored in:

sync_queue

Conflict records stored in:

sync_conflicts

Conflict resolution must preserve data integrity.

Never silently discard records.

All conflicts must be reviewable.

---

# AI Assistant Roadmap

Future AI assistant capabilities:

Sales insights

Inventory forecasting

Expense analysis

Business recommendations

Fraud summaries

Natural language queries

Examples:

"Show today's sales"

"Which products are low in stock?"

"What were my expenses this month?"

"Which employee issued the most refunds?"

"Show inventory adjustments last week"

The AI assistant must only access data allowed by the user's permissions.

---

# Coding Standards

Use Repository Pattern.

Use Riverpod for state management.

Use Supabase as backend.

Use UUIDs as primary keys.

Prefer immutable models.

Always include:

created_at

business_id

branch_id where applicable.

Never hardcode permissions.

Never bypass audit logging.

Never bypass inventory movement records.

Always consider offline sync implications before schema changes.

---

# When Generating Code

Always assume:

- Flutter frontend
- Supabase backend
- PostgreSQL database
- Offline-first architecture
- Multi-branch support
- Permission-based access
- Audit logging required
- Future AI integration required

Any new feature should be evaluated against:

1. Offline support
2. Multi-branch support
3. Permissions
4. Audit logging
5. Fraud detection
6. Sync behavior
7. AI compatibility