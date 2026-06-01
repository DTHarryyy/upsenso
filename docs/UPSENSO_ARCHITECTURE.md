# UPSENSO SYSTEM ARCHITECTURE

This document defines the full system architecture of UPSENSO.

It is designed for:

- Offline-first POS system
- Multi-branch businesses
- Scalable backend (Supabase/Postgres)
- Flutter mobile/web client
- AI-powered business assistant
- Fraud detection system

---

# HIGH LEVEL ARCHITECTURE

```
[ Flutter App ]
     |
     | (Offline First Layer)
     v
[ Local DB (SQLite/Hive) ]
     |
     | Sync Engine
     v
[ Sync Queue System ]
     |
     v
[ Supabase Backend ]
     |
     v
[ PostgreSQL Database ]
     |
     ├── RLS Security Layer
     ├── Audit System
     ├── Fraud Detection
     └── Analytics Layer
```

---

# CLIENT LAYER (FLUTTER)

Responsibilities:

- UI rendering
- Offline data storage
- Permission checks (UI level only)
- Local caching
- Sync queue management
- State management (Riverpod)

Key modules:

- POS Module
- Inventory Module
- Expenses Module
- Employees Module
- Reports Module
- Settings Module
- AI Assistant Module

---

# OFFLINE-FIRST ENGINE

## Local Storage

Use:

- SQLite (primary)
or
- Hive (fast cache layer)

Stores:

- Transactions
- Inventory updates
- Expenses
- Sync queue
- Temporary logs

---

## SYNC QUEUE SYSTEM

All offline actions go into:

```
sync_queue
```

Each action includes:

- operation type (insert/update/delete)
- table name
- payload
- timestamp
- device_id
- business_id

---

## SYNC FLOW

```
User Action
   ↓
Local DB update
   ↓
Sync Queue entry created
   ↓
Internet available?
   ↓
Push to Supabase
   ↓
Server validates RLS + permissions
   ↓
Commit to PostgreSQL
   ↓
Mark sync as completed
```

---

# BACKEND LAYER (SUPABASE)

Supabase handles:

- Authentication
- PostgreSQL database
- Row Level Security (RLS)
- Edge functions (optional)
- Real-time updates

---

## DATABASE RESPONSIBILITIES

- Data persistence
- Multi-tenant isolation
- Audit logging enforcement
- Fraud detection triggers (future)
- Sync conflict detection

---

# MULTI-BRANCH SYSTEM

Each business has:

- multiple branches
- shared products
- branch-specific inventory

Rule:

```
business_id = global scope
branch_id = operational scope
```

Example:

- Inventory is branch-specific
- Products are business-wide
- Transactions are branch-specific

---

# POS SYSTEM FLOW

```
Open Shift
   ↓
Add Products to Cart
   ↓
Apply Discounts (permission required)
   ↓
Checkout
   ↓
Create Transaction
   ↓
Create Transaction Items
   ↓
Create Payment Records
   ↓
Update Inventory
   ↓
Write Audit Log
   ↓
Add Sync Queue Entry (offline support)
```

---

# INVENTORY FLOW

```
Purchase / Sale / Adjustment
   ↓
Create Inventory Movement
   ↓
Update Inventory Levels
   ↓
Write Audit Log
   ↓
Trigger Fraud Detection (if risky)
```

---

# EXPENSE FLOW

```
Employee creates expense
   ↓
Status = pending
   ↓
Manager approves/rejects
   ↓
Update expense record
   ↓
Audit log created
   ↓
Fraud check (if suspicious)
```

---

# SECURITY ARCHITECTURE

## Layers:

### 1. UI Layer
- hides unauthorized buttons

### 2. API Layer
- validates permissions

### 3. DATABASE LAYER (RLS)
- enforces business isolation

---

# ROLE SYSTEM FLOW

```
Employee
   ↓
Employee Roles
   ↓
Role Permissions
   ↓
Permission Check
   ↓
Access Granted / Denied
```

---

# FRAUD DETECTION SYSTEM

Triggers:

- excessive refunds
- abnormal inventory changes
- repeated void transactions
- suspicious expense approvals
- role escalation attempts

Output:

- fraud_flags table
- notifications
- audit log entry

---

# AUDIT SYSTEM

Every critical action:

- stored in audit_logs
- includes hash chaining
- immutable

Used for:

- traceability
- fraud investigation
- compliance

---

# AI ASSISTANT ARCHITECTURE

## Future AI Layer

AI can query:

- transactions
- inventory
- expenses
- employees
- audit logs

Capabilities:

- natural language queries
- insights
- anomaly detection
- forecasting

Example:

User: "Why did sales drop yesterday?"

AI:
- queries transactions
- compares previous days
- checks branch performance
- returns insight

---

# MODULE SYSTEM

UPSENSO is modular.

Each business can enable/disable modules:

- POS
- Inventory
- Expenses
- Reports
- Employees

If module disabled:

- UI hidden
- API blocked
- permissions ignored

---

# DATA FLOW PRINCIPLES

- Write first locally
- Sync later
- Never lose data
- Never bypass RLS
- Always log critical actions

---

# SCALABILITY DESIGN

System supports:

- multiple businesses
- multiple branches per business
- thousands of employees
- high transaction volume

Scaling strategy:

- index business_id everywhere
- partition large tables (future)
- use Supabase scaling features
- keep queries business-scoped

---

# FUTURE EXTENSIONS

- AI-powered cashier assistant
- predictive inventory restocking
- fraud auto-block system
- offline AI model (local inference)
- barcode scanning optimization
- receipt OCR scanning

---

# FINAL PRINCIPLE

UPSENSO is built as:

> Offline-first + secure + multi-branch + AI-ready business OS