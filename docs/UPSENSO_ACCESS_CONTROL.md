# UPSENSO ENTERPRISE ACCESS CONTROL SYSTEM

**Version**: 2.0  
**Status**: Design Specification  
**Replaces**: Pure RBAC described in UPSENSO_PERMISSIONS.md  
**Compatibility**: Backward-compatible with existing `roles`, `role_permissions`, `permissions` tables

---

# OVERVIEW

This document defines the complete enterprise-grade access control refactor for UPSENSO.

The system evolves from a flat RBAC model into a **layered hybrid access control architecture**:

| Layer | Model | Description |
|-------|-------|-------------|
| 1 | Capability | Permission codes (existing `permissions` table) |
| 2 | RBAC | Roles → role_permissions (existing, preserved) |
| 3 | ABAC | Attribute-based user and branch overrides (new) |
| 4 | Context | Shift, device, offline state rules (new) |
| 5 | Policy Engine | Composable JSON rules (new) |

The system is **offline-first**, **deterministic**, and **zero-trust by default**.

---

---

# A. SYSTEM ARCHITECTURE DESIGN

---

## A.1 — Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                   FLUTTER CLIENT (OFFLINE)               │
│                                                         │
│  ┌───────────────────────────────────────────────┐      │
│  │          Permission Evaluator (Dart)           │      │
│  │   (pure function — deterministic, no I/O)     │      │
│  └──────────────────┬────────────────────────────┘      │
│                     │ reads from                        │
│  ┌──────────────────▼────────────────────────────┐      │
│  │         Local Permission Snapshot              │      │
│  │      (Drift/SQLite — effective_permissions)   │      │
│  └──────────────────┬────────────────────────────┘      │
│                     │ synced by                         │
│  ┌──────────────────▼────────────────────────────┐      │
│  │            Permission Sync Engine              │      │
│  │    (delta sync, version-aware, conflict-safe) │      │
│  └──────────────────┬────────────────────────────┘      │
└─────────────────────│───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                  SUPABASE / POSTGRESQL                   │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │          Permission Compute Function             │   │
│  │     (server-side, authoritative evaluation)      │   │
│  └──────┬──────────────────────────────────────────┘   │
│         │ reads from                                    │
│  ┌──────▼──────────────────────────────────────────┐   │
│  │   Permission Data Layers                        │   │
│  │                                                 │   │
│  │  business_modules  → module gate                │   │
│  │  permission_policies → context rules            │   │
│  │  user_permissions   → employee overrides        │   │
│  │  branch_permissions → branch restrictions       │   │
│  │  role_permissions   → base RBAC                 │   │
│  │  permissions        → capability catalog        │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │   effective_permissions (server-side cache)     │   │
│  │   Recomputed on permission change events        │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## A.2 — Permission Layers

Access is controlled by **6 named layers**, evaluated in strict priority order:

```
Layer 0 — Module Gate         (business_modules)
Layer 1 — Context Rules       (permission_policies)
Layer 2 — Explicit DENY       (user_permissions + branch_permissions where is_granted=false)
Layer 3 — User-Level Override (user_permissions where is_granted=true)
Layer 4 — Branch Rules        (branch_permissions where is_granted=true)
Layer 5 — Role Permissions    (role_permissions where allowed=true)
Layer 6 — Default DENY        (fallback — zero trust)
```

**Critical Rule**: A DENY in any layer from 0–2 immediately terminates evaluation and returns DENIED regardless of what layers below would grant.

---

## A.3 — Hybrid Access Control Models

### RBAC (Role-Based Access Control)
- Preserved as-is from existing schema
- `employee_roles` → `roles` → `role_permissions` → `permissions`
- Forms the **base access layer** (Layer 5)
- Still the primary mechanism for standard employees

### ABAC (Attribute-Based Access Control)
- Implemented via `user_permissions` and `branch_permissions`
- Attributes: employee identity, branch identity, time window, expiry
- Enables **exceptions to role-based rules** (Layer 3 and 4)
- Example: Grant `pos.refund` to a specific cashier without role change

### Capability-Based Permissions
- Permission codes remain the atomic unit of access (`pos.use`, `inventory.adjust`)
- Every permission check MUST use a code — never a role name
- Codes are immutable and catalogued in the `permissions` table

### Context-Aware Access Control
- Implemented via `permission_policies` (Layer 1)
- Context attributes: shift state, device trust level, offline mode, transaction amount
- Example: Block `expenses.approve` when device is offline
- Example: Restrict `pos.discount` to shift hours only

---

## A.4 — Zero Trust Security Model

- **Default deny**: no permission is implied; everything must be explicitly granted
- **is_dangerous** permissions require a secondary confirmation signal
- All permission changes are recorded in `audit_logs`
- Permission computation on the server is the **authoritative source of truth**
- Client-side snapshot is trusted for read operations only; writes are validated server-side through RLS

---

---

# B. DATABASE SCHEMA

---

## B.1 — New Tables

### user_permissions
Stores **employee-level** permission overrides. Overrides role-based access for a specific employee, optionally scoped to a branch.

```sql
CREATE TABLE user_permissions (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id       uuid        NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  employee_id       uuid        NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  branch_id         uuid        REFERENCES branches(id) ON DELETE CASCADE,
  -- NULL branch_id = applies to ALL branches of this employee
  permission_id     uuid        NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  is_granted        boolean     NOT NULL,
  -- true  = explicit ALLOW (overrides role DENY)
  -- false = explicit DENY  (overrides role ALLOW — highest priority)
  granted_by        uuid        NOT NULL REFERENCES employees(id),
  reason            text,
  expires_at        timestamptz,
  -- NULL = never expires
  is_active         boolean     NOT NULL DEFAULT true,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  UNIQUE (employee_id, branch_id, permission_id)
  -- one override record per employee+branch+permission
);

CREATE INDEX idx_user_permissions_employee    ON user_permissions(employee_id);
CREATE INDEX idx_user_permissions_business    ON user_permissions(business_id);
CREATE INDEX idx_user_permissions_branch      ON user_permissions(branch_id);
CREATE INDEX idx_user_permissions_expires     ON user_permissions(expires_at)
  WHERE expires_at IS NOT NULL;
```

---

### branch_permissions
Stores **branch-level** permission restrictions. Can block a permission for ALL employees at a specific branch regardless of role.

```sql
CREATE TABLE branch_permissions (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id       uuid        NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  branch_id         uuid        NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  permission_id     uuid        NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  is_granted        boolean     NOT NULL,
  -- false = blocked at this branch for everyone (including high-level roles)
  -- true  = explicitly allowed (useful for branch-specific capabilities)
  reason            text,
  created_by        uuid        NOT NULL REFERENCES employees(id),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  UNIQUE (branch_id, permission_id)
);

CREATE INDEX idx_branch_permissions_branch   ON branch_permissions(branch_id);
CREATE INDEX idx_branch_permissions_business ON branch_permissions(business_id);
```

---

### permission_policies
Stores **context-based rules** that apply additional access conditions. A policy does not grant or deny on its own — it constrains an already-granted permission based on runtime context.

```sql
CREATE TABLE permission_policies (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id     uuid        NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  branch_id       uuid        REFERENCES branches(id) ON DELETE CASCADE,
  -- NULL = applies to all branches
  permission_id   uuid        REFERENCES permissions(id) ON DELETE CASCADE,
  -- NULL = applies to all permissions
  role_id         uuid        REFERENCES roles(id) ON DELETE CASCADE,
  -- NULL = applies to all roles
  policy_type     text        NOT NULL,
  -- 'shift_hours'   | 'device_trust' | 'offline_mode'
  -- 'max_amount'    | 'require_shift_open' | 'custom_json'
  policy_config   jsonb       NOT NULL,
  priority        integer     NOT NULL DEFAULT 0,
  -- higher = evaluated first
  is_active       boolean     NOT NULL DEFAULT true,
  created_by      uuid        NOT NULL REFERENCES employees(id),
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_permission_policies_business    ON permission_policies(business_id);
CREATE INDEX idx_permission_policies_branch      ON permission_policies(branch_id);
CREATE INDEX idx_permission_policies_permission  ON permission_policies(permission_id);
CREATE INDEX idx_permission_policies_type        ON permission_policies(policy_type);
```

**policy_config examples:**

```json
// shift_hours — only allow during defined working hours
{
  "type": "shift_hours",
  "allowed_days": [1, 2, 3, 4, 5],
  "start_time": "08:00",
  "end_time": "22:00",
  "timezone": "Asia/Manila"
}

// offline_mode — block permission when device is offline
{
  "type": "offline_mode",
  "allowed_offline": false
}

// device_trust — require device to be registered/trusted
{
  "type": "device_trust",
  "require_trusted_device": true
}

// max_amount — block pos.discount if amount exceeds threshold
{
  "type": "max_amount",
  "field": "discount_amount",
  "max": 500.00,
  "currency": "PHP"
}

// require_shift_open — permission only valid during an open shift
{
  "type": "require_shift_open",
  "required": true
}
```

---

### effective_permissions
**Pre-computed permission snapshot** per employee per branch. This is the offline cache. It is the ONLY table the Flutter app reads for permission checks.

```sql
CREATE TABLE effective_permissions (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id         uuid        NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  employee_id         uuid        NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  branch_id           uuid        NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  permission_code     text        NOT NULL,
  -- denormalized code for fast offline lookup (no join needed)
  is_granted          boolean     NOT NULL,
  grant_source        text        NOT NULL,
  -- 'role'            — granted via role_permissions
  -- 'user_allow'      — granted via user_permissions (is_granted=true)
  -- 'branch_allow'    — granted via branch_permissions (is_granted=true)
  -- 'user_deny'       — denied via user_permissions (is_granted=false)
  -- 'branch_deny'     — denied via branch_permissions (is_granted=false)
  -- 'module_disabled' — denied because business_module is disabled
  -- 'context_blocked' — denied by a permission_policy rule
  -- 'default_deny'    — no grant found
  deny_reason         text,
  -- human-readable reason when is_granted=false
  snapshot_version    bigint      NOT NULL,
  -- monotonically increasing; incremented on any permission change
  computed_at         timestamptz NOT NULL DEFAULT now(),
  valid_until         timestamptz,
  -- NULL = permanent until next recompute

  UNIQUE (employee_id, branch_id, permission_code)
);

CREATE INDEX idx_effective_permissions_employee ON effective_permissions(employee_id);
CREATE INDEX idx_effective_permissions_business ON effective_permissions(business_id);
CREATE INDEX idx_effective_permissions_version  ON effective_permissions(snapshot_version);
CREATE INDEX idx_effective_permissions_lookup
  ON effective_permissions(employee_id, branch_id, permission_code);
```

---

### permission_snapshot_versions
Tracks the current snapshot version per employee per branch. Used for delta sync — client only downloads records newer than its stored version.

```sql
CREATE TABLE permission_snapshot_versions (
  employee_id      uuid        NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  branch_id        uuid        NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  business_id      uuid        NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  current_version  bigint      NOT NULL DEFAULT 1,
  last_recomputed  timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (employee_id, branch_id)
);
```

---

## B.2 — Additions to Existing Tables

### permissions — add metadata fields

```sql
ALTER TABLE permissions ADD COLUMN IF NOT EXISTS
  risk_level text NOT NULL DEFAULT 'low'
  CHECK (risk_level IN ('low', 'medium', 'high', 'critical'));
-- Replaces the boolean is_dangerous with a graduated scale
-- is_dangerous = true becomes risk_level IN ('high', 'critical')

ALTER TABLE permissions ADD COLUMN IF NOT EXISTS
  requires_confirmation boolean NOT NULL DEFAULT false;
-- true = UI must show confirmation dialog before executing

ALTER TABLE permissions ADD COLUMN IF NOT EXISTS
  requires_manager_pin boolean NOT NULL DEFAULT false;
-- true = manager must enter PIN for dangerous operations offline

ALTER TABLE permissions ADD COLUMN IF NOT EXISTS
  audit_level text NOT NULL DEFAULT 'standard'
  CHECK (audit_level IN ('none', 'standard', 'detailed', 'immutable'));
-- 'immutable' = write-once audit log with hash chain
```

---

## B.3 — Triggers for Automatic Snapshot Recomputation

```sql
-- Function: bump snapshot version when any permission source changes
CREATE OR REPLACE FUNCTION bump_permission_snapshot_version()
RETURNS TRIGGER AS $$
BEGIN
  -- Determine which employees are affected
  -- and increment their snapshot version
  INSERT INTO permission_snapshot_versions
    (employee_id, branch_id, business_id, current_version, last_recomputed)
  SELECT
    e.id,
    eb.branch_id,
    e.business_id,
    COALESCE(psv.current_version, 0) + 1,
    now()
  FROM employees e
  JOIN employee_branches eb ON eb.employee_id = e.id
  LEFT JOIN permission_snapshot_versions psv
    ON psv.employee_id = e.id AND psv.branch_id = eb.branch_id
  WHERE e.business_id = NEW.business_id
  ON CONFLICT (employee_id, branch_id)
  DO UPDATE SET
    current_version = permission_snapshot_versions.current_version + 1,
    last_recomputed = now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach to tables that affect permissions
CREATE TRIGGER trg_role_permissions_version
  AFTER INSERT OR UPDATE OR DELETE ON role_permissions
  FOR EACH ROW EXECUTE FUNCTION bump_permission_snapshot_version();

CREATE TRIGGER trg_user_permissions_version
  AFTER INSERT OR UPDATE OR DELETE ON user_permissions
  FOR EACH ROW EXECUTE FUNCTION bump_permission_snapshot_version();

CREATE TRIGGER trg_branch_permissions_version
  AFTER INSERT OR UPDATE OR DELETE ON branch_permissions
  FOR EACH ROW EXECUTE FUNCTION bump_permission_snapshot_version();

CREATE TRIGGER trg_business_modules_version
  AFTER INSERT OR UPDATE OR DELETE ON business_modules
  FOR EACH ROW EXECUTE FUNCTION bump_permission_snapshot_version();
```

---

## B.4 — Server-Side Permission Compute Function

```sql
-- Authoritative permission evaluation — called when recomputing snapshots
CREATE OR REPLACE FUNCTION compute_employee_permissions(
  p_employee_id uuid,
  p_branch_id   uuid
)
RETURNS TABLE (
  permission_code text,
  is_granted      boolean,
  grant_source    text,
  deny_reason     text
) AS $$
DECLARE
  v_business_id uuid;
BEGIN
  SELECT business_id INTO v_business_id
  FROM employees WHERE id = p_employee_id;

  RETURN QUERY
  WITH

  -- All permission codes in the catalog
  all_perms AS (
    SELECT p.id AS permission_id, p.code, p.module
    FROM permissions p
  ),

  -- Step 0: Module gate
  module_disabled AS (
    SELECT ap.code
    FROM all_perms ap
    WHERE NOT EXISTS (
      SELECT 1 FROM business_modules bm
      JOIN modules m ON m.id = bm.module_id
      WHERE bm.business_id = v_business_id
        AND bm.enabled = true
        AND lower(m.code) = lower(ap.module)
    )
  ),

  -- Step 2a: Explicit DENY from user_permissions
  user_deny AS (
    SELECT p.code
    FROM user_permissions up
    JOIN permissions p ON p.id = up.permission_id
    WHERE up.employee_id = p_employee_id
      AND (up.branch_id = p_branch_id OR up.branch_id IS NULL)
      AND up.is_granted = false
      AND up.is_active = true
      AND (up.expires_at IS NULL OR up.expires_at > now())
  ),

  -- Step 2b: Explicit DENY from branch_permissions
  branch_deny AS (
    SELECT p.code
    FROM branch_permissions bp
    JOIN permissions p ON p.id = bp.permission_id
    WHERE bp.branch_id = p_branch_id
      AND bp.is_granted = false
  ),

  -- All DENYs combined (highest priority)
  all_denies AS (
    SELECT code FROM module_disabled
    UNION
    SELECT code FROM user_deny
    UNION
    SELECT code FROM branch_deny
  ),

  -- Step 3: User-level ALLOW override
  user_allow AS (
    SELECT p.code
    FROM user_permissions up
    JOIN permissions p ON p.id = up.permission_id
    WHERE up.employee_id = p_employee_id
      AND (up.branch_id = p_branch_id OR up.branch_id IS NULL)
      AND up.is_granted = true
      AND up.is_active = true
      AND (up.expires_at IS NULL OR up.expires_at > now())
  ),

  -- Step 4: Branch-level ALLOW
  branch_allow AS (
    SELECT p.code
    FROM branch_permissions bp
    JOIN permissions p ON p.id = bp.permission_id
    WHERE bp.branch_id = p_branch_id
      AND bp.is_granted = true
  ),

  -- Step 5: Role-based ALLOW
  role_allow AS (
    SELECT DISTINCT p.code
    FROM employee_roles er
    JOIN role_permissions rp ON rp.role_id = er.role_id
    JOIN permissions p ON p.id = rp.permission_id
    WHERE er.employee_id = p_employee_id
      AND rp.allowed = true
  ),

  -- Final resolution
  resolved AS (
    SELECT
      ap.code AS permission_code,
      CASE
        WHEN ap.code IN (SELECT code FROM module_disabled) THEN false
        WHEN ap.code IN (SELECT code FROM user_deny)       THEN false
        WHEN ap.code IN (SELECT code FROM branch_deny)     THEN false
        WHEN ap.code IN (SELECT code FROM user_allow)      THEN true
        WHEN ap.code IN (SELECT code FROM branch_allow)    THEN true
        WHEN ap.code IN (SELECT code FROM role_allow)      THEN true
        ELSE false
      END AS is_granted,
      CASE
        WHEN ap.code IN (SELECT code FROM module_disabled) THEN 'module_disabled'
        WHEN ap.code IN (SELECT code FROM user_deny)       THEN 'user_deny'
        WHEN ap.code IN (SELECT code FROM branch_deny)     THEN 'branch_deny'
        WHEN ap.code IN (SELECT code FROM user_allow)      THEN 'user_allow'
        WHEN ap.code IN (SELECT code FROM branch_allow)    THEN 'branch_allow'
        WHEN ap.code IN (SELECT code FROM role_allow)      THEN 'role'
        ELSE 'default_deny'
      END AS grant_source,
      CASE
        WHEN ap.code IN (SELECT code FROM module_disabled) THEN 'Module is disabled for this business'
        WHEN ap.code IN (SELECT code FROM user_deny)       THEN 'Explicitly denied for this employee'
        WHEN ap.code IN (SELECT code FROM branch_deny)     THEN 'Blocked at branch level'
        ELSE NULL
      END AS deny_reason
    FROM all_perms ap
  )

  SELECT * FROM resolved;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

---

# C. PERMISSION EVALUATION ALGORITHM

---

## C.1 — Evaluation Order (Strict Priority)

```
INPUT: employee_id, branch_id, permission_code, context

STEP 0 ──► Is the module enabled for this business?
           NO  → DENY (source: module_disabled)

STEP 1 ──► Do any context rules (permission_policies) block this?
           YES → DENY (source: context_blocked, reason: policy type)

STEP 2 ──► Is there an explicit DENY for this employee at this branch?
           (user_permissions.is_granted = false)
           YES → DENY (source: user_deny) — CANNOT be overridden below

STEP 3 ──► Is there a branch-level DENY for this permission?
           (branch_permissions.is_granted = false)
           YES → DENY (source: branch_deny) — CANNOT be overridden below

STEP 4 ──► Is there an explicit ALLOW for this employee at this branch?
           (user_permissions.is_granted = true, not expired)
           YES → ALLOW (source: user_allow)

STEP 5 ──► Is there a branch-level ALLOW for this permission?
           (branch_permissions.is_granted = true)
           YES → ALLOW (source: branch_allow)

STEP 6 ──► Does any of the employee's roles grant this permission?
           (employee_roles → role_permissions.allowed = true)
           YES → ALLOW (source: role)

STEP 7 ──► DEFAULT → DENY (source: default_deny)

OUTPUT: { granted: bool, source: string, reason?: string }
```

---

## C.2 — Dart Implementation (Flutter Client)

```dart
// lib/core/permissions/permission_evaluator.dart

import 'package:equatable/equatable.dart';

enum GrantSource {
  moduleDisabled,
  contextBlocked,
  userDeny,
  branchDeny,
  userAllow,
  branchAllow,
  role,
  defaultDeny,
}

class PermissionResult extends Equatable {
  final bool isGranted;
  final GrantSource source;
  final String? denyReason;

  const PermissionResult({
    required this.isGranted,
    required this.source,
    this.denyReason,
  });

  static const denied = PermissionResult(
    isGranted: false,
    source: GrantSource.defaultDeny,
  );

  @override
  List<Object?> get props => [isGranted, source, denyReason];
}

class PermissionContext {
  final bool isOnline;
  final bool isShiftOpen;
  final bool isDeviceTrusted;
  final DateTime localTime;
  final double? transactionAmount;

  const PermissionContext({
    required this.isOnline,
    required this.isShiftOpen,
    required this.isDeviceTrusted,
    required this.localTime,
    this.transactionAmount,
  });
}

/// Purely functional — no I/O, no async.
/// Reads only from the pre-loaded PermissionSnapshot.
class PermissionEvaluator {
  const PermissionEvaluator();

  PermissionResult evaluate({
    required String permissionCode,
    required String employeeId,
    required String branchId,
    required PermissionSnapshot snapshot,
    required PermissionContext context,
  }) {
    final module = permissionCode.split('.').first;

    // Step 0 — Module gate
    if (!snapshot.isModuleEnabled(module)) {
      return const PermissionResult(
        isGranted: false,
        source: GrantSource.moduleDisabled,
        denyReason: 'Module is disabled for this business',
      );
    }

    // Step 1 — Context rules
    final contextBlock = _evaluateContextPolicies(
      permissionCode, branchId, context, snapshot,
    );
    if (contextBlock != null) return contextBlock;

    // Step 2 — User-level explicit DENY
    final userDeny = snapshot.getUserOverride(
      employeeId: employeeId,
      branchId: branchId,
      permissionCode: permissionCode,
      isGranted: false,
    );
    if (userDeny != null) {
      return PermissionResult(
        isGranted: false,
        source: GrantSource.userDeny,
        denyReason: userDeny.reason ?? 'Explicitly denied for this employee',
      );
    }

    // Step 3 — Branch-level explicit DENY
    final branchDeny = snapshot.getBranchOverride(
      branchId: branchId,
      permissionCode: permissionCode,
      isGranted: false,
    );
    if (branchDeny != null) {
      return PermissionResult(
        isGranted: false,
        source: GrantSource.branchDeny,
        denyReason: branchDeny.reason ?? 'Blocked at branch level',
      );
    }

    // Step 4 — User-level explicit ALLOW
    final userAllow = snapshot.getUserOverride(
      employeeId: employeeId,
      branchId: branchId,
      permissionCode: permissionCode,
      isGranted: true,
    );
    if (userAllow != null) {
      return const PermissionResult(
        isGranted: true,
        source: GrantSource.userAllow,
      );
    }

    // Step 5 — Branch-level ALLOW
    final branchAllow = snapshot.getBranchOverride(
      branchId: branchId,
      permissionCode: permissionCode,
      isGranted: true,
    );
    if (branchAllow != null) {
      return const PermissionResult(
        isGranted: true,
        source: GrantSource.branchAllow,
      );
    }

    // Step 6 — Role permissions
    if (snapshot.hasRolePermission(
      employeeId: employeeId,
      permissionCode: permissionCode,
    )) {
      return const PermissionResult(
        isGranted: true,
        source: GrantSource.role,
      );
    }

    // Step 7 — Default DENY
    return PermissionResult.denied;
  }

  PermissionResult? _evaluateContextPolicies(
    String permissionCode,
    String branchId,
    PermissionContext context,
    PermissionSnapshot snapshot,
  ) {
    final policies = snapshot.getPoliciesFor(
      permissionCode: permissionCode,
      branchId: branchId,
    );

    for (final policy in policies) {
      switch (policy.policyType) {
        case 'offline_mode':
          final allowedOffline = policy.config['allowed_offline'] as bool? ?? true;
          if (!context.isOnline && !allowedOffline) {
            return const PermissionResult(
              isGranted: false,
              source: GrantSource.contextBlocked,
              denyReason: 'This action requires an internet connection',
            );
          }

        case 'require_shift_open':
          final required = policy.config['required'] as bool? ?? false;
          if (required && !context.isShiftOpen) {
            return const PermissionResult(
              isGranted: false,
              source: GrantSource.contextBlocked,
              denyReason: 'A shift must be open to perform this action',
            );
          }

        case 'device_trust':
          final requireTrusted = policy.config['require_trusted_device'] as bool? ?? false;
          if (requireTrusted && !context.isDeviceTrusted) {
            return const PermissionResult(
              isGranted: false,
              source: GrantSource.contextBlocked,
              denyReason: 'This action requires a trusted device',
            );
          }

        case 'shift_hours':
          final startTime = policy.config['start_time'] as String?;
          final endTime = policy.config['end_time'] as String?;
          final allowedDays = (policy.config['allowed_days'] as List?)
              ?.cast<int>() ?? [];
          if (startTime != null && endTime != null) {
            if (!_isWithinShiftHours(
              context.localTime, startTime, endTime, allowedDays,
            )) {
              return const PermissionResult(
                isGranted: false,
                source: GrantSource.contextBlocked,
                denyReason: 'This action is only allowed during shift hours',
              );
            }
          }

        case 'max_amount':
          final max = (policy.config['max'] as num?)?.toDouble();
          if (max != null &&
              context.transactionAmount != null &&
              context.transactionAmount! > max) {
            return PermissionResult(
              isGranted: false,
              source: GrantSource.contextBlocked,
              denyReason: 'Amount exceeds the allowed maximum of $max',
            );
          }
      }
    }

    return null; // no context block
  }

  bool _isWithinShiftHours(
    DateTime now,
    String startTime,
    String endTime,
    List<int> allowedDays,
  ) {
    if (allowedDays.isNotEmpty && !allowedDays.contains(now.weekday)) {
      return false;
    }
    final start = _parseTime(startTime, now);
    final end = _parseTime(endTime, now);
    return now.isAfter(start) && now.isBefore(end);
  }

  DateTime _parseTime(String time, DateTime ref) {
    final parts = time.split(':');
    return DateTime(ref.year, ref.month, ref.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }
}
```

---

## C.3 — PermissionSnapshot Model (Dart)

```dart
// lib/core/permissions/permission_snapshot.dart

class EffectivePermissionRecord {
  final String permissionCode;
  final bool isGranted;
  final String grantSource;
  final String? denyReason;

  const EffectivePermissionRecord({
    required this.permissionCode,
    required this.isGranted,
    required this.grantSource,
    this.denyReason,
  });
}

class UserOverrideRecord {
  final String permissionCode;
  final bool isGranted;
  final String? reason;
  final DateTime? expiresAt;

  const UserOverrideRecord({
    required this.permissionCode,
    required this.isGranted,
    this.reason,
    this.expiresAt,
  });
}

class BranchOverrideRecord {
  final String permissionCode;
  final bool isGranted;
  final String? reason;

  const BranchOverrideRecord({
    required this.permissionCode,
    required this.isGranted,
    this.reason,
  });
}

class PolicyRecord {
  final String policyType;
  final Map<String, dynamic> config;

  const PolicyRecord({required this.policyType, required this.config});
}

/// Pre-loaded, immutable snapshot for a single employee+branch.
/// All lookups are O(1) via pre-built maps.
class PermissionSnapshot {
  final String employeeId;
  final String branchId;
  final int snapshotVersion;
  final DateTime computedAt;

  final Set<String> _enabledModules;
  // key: permissionCode → override record for this employee/branch
  final Map<String, UserOverrideRecord> _userAllows;
  final Map<String, UserOverrideRecord> _userDenies;
  final Map<String, BranchOverrideRecord> _branchAllows;
  final Map<String, BranchOverrideRecord> _branchDenies;
  final Set<String> _rolePermissions;
  // key: permissionCode → list of applicable policies
  final Map<String, List<PolicyRecord>> _policies;

  const PermissionSnapshot({
    required this.employeeId,
    required this.branchId,
    required this.snapshotVersion,
    required this.computedAt,
    required Set<String> enabledModules,
    required Map<String, UserOverrideRecord> userAllows,
    required Map<String, UserOverrideRecord> userDenies,
    required Map<String, BranchOverrideRecord> branchAllows,
    required Map<String, BranchOverrideRecord> branchDenies,
    required Set<String> rolePermissions,
    required Map<String, List<PolicyRecord>> policies,
  })  : _enabledModules = enabledModules,
        _userAllows = userAllows,
        _userDenies = userDenies,
        _branchAllows = branchAllows,
        _branchDenies = branchDenies,
        _rolePermissions = rolePermissions,
        _policies = policies;

  bool isModuleEnabled(String module) => _enabledModules.contains(module.toLowerCase());

  UserOverrideRecord? getUserOverride({
    required String employeeId,
    required String branchId,
    required String permissionCode,
    required bool isGranted,
  }) {
    final map = isGranted ? _userAllows : _userDenies;
    final record = map[permissionCode];
    if (record == null) return null;
    // Check expiry
    if (record.expiresAt != null && record.expiresAt!.isBefore(DateTime.now())) {
      return null;
    }
    return record;
  }

  BranchOverrideRecord? getBranchOverride({
    required String branchId,
    required String permissionCode,
    required bool isGranted,
  }) {
    final map = isGranted ? _branchAllows : _branchDenies;
    return map[permissionCode];
  }

  bool hasRolePermission({
    required String employeeId,
    required String permissionCode,
  }) => _rolePermissions.contains(permissionCode);

  List<PolicyRecord> getPoliciesFor({
    required String permissionCode,
    required String branchId,
  }) => _policies[permissionCode] ?? const [];
}
```

---

---

# D. OFFLINE SYNC STRATEGY

---

## D.1 — Snapshot Model

The app NEVER recomputes permissions from raw tables. It ONLY reads from `effective_permissions`.

```
Server recomputes effective_permissions
   ↓
Stores snapshot_version per employee+branch
   ↓
App requests delta: "give me all records with version > my_version"
   ↓
App writes to local Drift effective_permissions table
   ↓
App loads PermissionSnapshot from Drift into memory
   ↓
All permission checks use in-memory PermissionSnapshot
```

---

## D.2 — Delta Sync Protocol

**On app launch / reconnect:**
```
1. Read local snapshot_version from Drift
2. POST /functions/v1/sync-permissions  { employee_id, branch_id, since_version: N }
3. Server returns: { records: [...], new_version: M }
4. App upserts records into local effective_permissions Drift table
5. App updates local version to M
6. App rebuilds in-memory PermissionSnapshot
```

**On permission change (server event via Supabase Realtime):**
```
1. Server fires realtime event: { type: 'permission_changed', employee_id, branch_id, new_version }
2. App receives event
3. App triggers delta sync from current_version to new_version
4. Snapshot reloaded automatically
```

**On offline mode:**
```
1. App uses last-known PermissionSnapshot from memory / Drift
2. context.isOnline = false → context policies for offline_mode evaluated
3. Dangerous operations with requires_manager_pin = true → PIN prompt
4. All offline-executed actions queued in sync_queue as normal
5. Permission changes made offline are BLOCKED (require connectivity)
```

---

## D.3 — Drift Local Schema (Dart)

```dart
// lib/core/database/tables/effective_permissions_table.dart

import 'package:drift/drift.dart';

class EffectivePermissionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().named('business_id')();
  TextColumn get employeeId => text().named('employee_id')();
  TextColumn get branchId => text().named('branch_id')();
  TextColumn get permissionCode => text().named('permission_code')();
  BoolColumn get isGranted => boolean().named('is_granted')();
  TextColumn get grantSource => text().named('grant_source')();
  TextColumn get denyReason => text().named('deny_reason').nullable()();
  IntColumn get snapshotVersion => integer().named('snapshot_version')();
  DateTimeColumn get computedAt => dateTime().named('computed_at')();
  DateTimeColumn get validUntil => dateTime().named('valid_until').nullable()();

  @override
  String get tableName => 'effective_permissions';

  @override
  Set<Column> get primaryKey => {id};
}

class SnapshotVersionsTable extends Table {
  TextColumn get employeeId => text().named('employee_id')();
  TextColumn get branchId => text().named('branch_id')();
  IntColumn get currentVersion => integer().named('current_version')();
  DateTimeColumn get lastSynced => dateTime().named('last_synced')();

  @override
  String get tableName => 'permission_snapshot_versions_local';

  @override
  Set<Column> get primaryKey => {employeeId, branchId};
}
```

---

## D.4 — Conflict Resolution Rules

| Scenario | Resolution Strategy |
|----------|-------------------|
| Server permission changed while offline | Server wins — snapshot refreshed on reconnect |
| User-level override created offline | Blocked — requires connectivity |
| Branch-level override changed offline | Blocked — requires connectivity |
| Role assignment changed offline | Blocked — requires connectivity |
| `expired_at` passed while offline | Client treats expired override as non-existent |
| Snapshot version mismatch | Full re-sync for that employee+branch |
| Realtime event missed | Version check on reconnect triggers delta sync |

**Rule**: Permission changes are **write-protected offline**. The employee can USE permissions offline (based on snapshot), but cannot CHANGE permission configuration without connectivity. This prevents privilege escalation attacks.

---

## D.5 — Snapshot Freshness Policy

| Permission Change | Max Stale Time |
|------------------|----------------|
| Role assignment change | 60 seconds (Realtime) |
| User-level deny | 30 seconds (priority push) |
| Branch-level block | 30 seconds (priority push) |
| Module enable/disable | 60 seconds (Realtime) |
| Expiry-based change | Client-enforced at expiry time |
| First login | Immediate full sync |

---

---

# E. MIGRATION PLAN

---

## Phase 0 — Pre-Migration Audit (No Changes)
**Goal**: Understand current state before touching anything.

```
1. Export current role_permissions for all businesses
2. Count employee_roles assignments per business
3. Identify any hardcoded permission checks in Flutter code
4. Identify any hardcoded role checks (search: 'owner', 'admin', 'cashier' in code)
5. Document current permission codes vs new schema
6. Run: SELECT code FROM permissions ORDER BY module → verify all codes match UPSENSO_PERMISSIONS.md
```

---

## Phase 1 — Schema Migration (Additive Only)
**Goal**: Add new tables without breaking anything. Zero downtime.

```sql
-- 1. Add new tables (see B.1 above)
-- 2. Add new columns to permissions table (see B.2 above)
-- 3. Backfill risk_level from is_dangerous:
UPDATE permissions
SET risk_level = CASE
  WHEN is_dangerous = true THEN 'high'
  ELSE 'low'
END;

-- 4. Create triggers (see B.3 above)
-- 5. Enable RLS on new tables (see RLS section below)
-- 6. Run initial effective_permissions backfill:
INSERT INTO effective_permissions (
  id, business_id, employee_id, branch_id,
  permission_code, is_granted, grant_source, snapshot_version, computed_at
)
SELECT
  gen_random_uuid(),
  e.business_id,
  e.id,
  eb.branch_id,
  p.code,
  COALESCE(rp.allowed, false),
  'role',
  1,
  now()
FROM employees e
JOIN employee_branches eb ON eb.employee_id = e.id
JOIN employee_roles er ON er.employee_id = e.id
JOIN role_permissions rp ON rp.role_id = er.role_id
JOIN permissions p ON p.id = rp.permission_id
ON CONFLICT (employee_id, branch_id, permission_code)
DO UPDATE SET
  is_granted = EXCLUDED.is_granted,
  snapshot_version = EXCLUDED.snapshot_version,
  computed_at = EXCLUDED.computed_at;
```

---

## Phase 2 — Feature Flag (Parallel Run)
**Goal**: Run old and new systems side-by-side; validate parity.

```dart
// lib/core/permissions/permission_service.dart

class PermissionService {
  final bool _useHybridSystem;
  final LegacyPermissionChecker _legacy;
  final PermissionEvaluator _hybrid;

  bool hasPermission(String code) {
    if (!_useHybridSystem) {
      return _legacy.check(code);
    }

    final result = _hybrid.evaluate(
      permissionCode: code,
      employeeId: _currentEmployee.id,
      branchId: _currentBranch.id,
      snapshot: _snapshot,
      context: _buildContext(),
    );
    return result.isGranted;
  }
}
```

- Feature flag: `FEATURE_HYBRID_PERMISSIONS = false` (controlled via `business_settings.settings`)
- Run both for 1 week, log discrepancies
- Validate: hybrid result must match legacy result for 100% of checks before cutover

---

## Phase 3 — Gradual Rollout
**Goal**: Enable hybrid system for pilot businesses.

```
1. Enable FEATURE_HYBRID_PERMISSIONS for internal test business
2. Monitor for 48 hours — zero discrepancy required
3. Enable for 10% of businesses (smallest by employee count)
4. Monitor for 1 week
5. Enable for all businesses
```

---

## Phase 4 — Full Cutover
**Goal**: Remove legacy code path.

```
1. Remove LegacyPermissionChecker
2. Remove feature flag
3. Update all UI permission checks to use PermissionEvaluator directly
4. Add permission inheritance UI (Phase F below)
5. Remove any remaining role-name string comparisons in code
```

---

## Phase 5 — Advanced Features (Post-Migration)
**Goal**: Enable new capabilities not possible in RBAC.

```
1. Enable user_permissions UI for admin dashboard
2. Enable branch_permissions management
3. Enable permission_policies configuration
4. Enable approval workflows for is_dangerous permissions
5. Enable AI-driven permission recommendations
```

---

## Phase 6 — Deprecate Old Schema (Optional)
**Goal**: Clean up once effective_permissions is proven stable.

```sql
-- Only run after 90 days of stable hybrid operation
-- Keep role_permissions — it remains the base RBAC layer
-- No tables are dropped; effective_permissions supersedes direct reads
```

---

---

# F. ADMIN UI PERMISSION MATRIX DESIGN

---

## F.1 — Permission Matrix Screen

```
┌─────────────────────────────────────────────────────────────────────────┐
│  PERMISSION MATRIX                         Branch: [All Branches ▼]    │
│  Business: Sunrise Coffee                                               │
├─────────────────────┬────────┬───────┬─────────┬──────────┬────────────┤
│  PERMISSION         │ OWNER  │ ADMIN │ MANAGER │ CASHIER  │ INV. STAFF │
├─────────────────────┼────────┼───────┼─────────┼──────────┼────────────┤
│  POS MODULE         │        │       │         │          │            │
│  ├ pos.use          │  ✅    │  ✅   │   ✅    │   ✅     │    ⛔     │
│  ├ pos.open_shift   │  ✅    │  ✅   │   ✅    │   ✅     │    ⛔     │
│  ├ pos.close_shift  │  ✅    │  ✅   │   ✅    │   ✅     │    ⛔     │
│  ├ pos.discount     │  ✅    │  ✅   │   ✅    │ 👤ALLOW  │    ⛔     │  ← user override
│  ├ pos.refund  🔴   │  ✅    │  ✅   │   ✅    │   ⛔     │    ⛔     │  ← dangerous
│  └ pos.void    🔴   │  ✅    │  ✅   │   ✅    │   ⛔     │    ⛔     │
├─────────────────────┼────────┼───────┼─────────┼──────────┼────────────┤
│  INVENTORY MODULE   │        │       │         │          │            │
│  ├ inventory.view   │  ✅    │  ✅   │   ✅    │   ⛔     │    ✅     │
│  ├ inventory.adjust🔴│  ✅   │  ✅   │ 🏢DENY  │   ⛔     │    ⛔     │  ← branch block
│  └ inventory.count  │  ✅    │  ✅   │   ✅    │   ⛔     │    ✅     │
├─────────────────────┼────────┼───────┼─────────┼──────────┼────────────┤
│  EXPENSES MODULE    │        │       │         │          │            │
│  ├ expenses.view    │  ✅    │  ✅   │   ✅    │   ⛔     │    ⛔     │
│  ├ expenses.create  │  ✅    │  ✅   │   ✅    │   ⛔     │    ⛔     │
│  └ expenses.approve🔴│  ✅   │  ✅   │   ✅    │   ⛔     │    ⛔     │
└─────────────────────┴────────┴───────┴─────────┴──────────┴────────────┘

LEGEND:
  ✅  Role ALLOW          ⛔  Role DENY (or no role grant)
  👤  User-level ALLOW    🏢  Branch-level DENY
  🔴  Dangerous action    ⚠️  Context-restricted
```

---

## F.2 — Inheritance Chain Inspector

When admin clicks any cell, a side panel shows:

```
┌─────────────────────────────────────────────┐
│  pos.discount — Juan dela Cruz (Cashier)    │
│  Branch: Main Branch                        │
├─────────────────────────────────────────────┤
│  EVALUATION TRACE                           │
│                                             │
│  ① Module: POS .................. ✅ ENABLED │
│  ② Context Policies ............. ✅ PASS   │
│     └ shift_hours: within hours             │
│  ③ Explicit DENY (user) ......... ⛔ NONE  │
│  ④ Branch DENY .................. ⛔ NONE  │
│  ⑤ User Override ................ ✅ FOUND  │  ← override highlighted
│     └ Granted by: Maria Santos             │
│       Reason: Temporary promotion trial    │
│       Expires: 2026-06-15                  │
│                                             │
│  RESULT: ✅ ALLOWED (via user_allow)        │
├─────────────────────────────────────────────┤
│  [Remove Override]  [Extend Expiry]         │
└─────────────────────────────────────────────┘
```

---

## F.3 — Quick Permission Override Flow

```
Admin selects employee → selects permission → clicks cell

For toggling ALLOW:
  ┌──────────────────────────────────────┐
  │  Grant Override: pos.discount        │
  │  Employee: Juan dela Cruz            │
  │  Branch: [Main Branch ▼] or [All]   │
  │  Reason: ____________________        │
  │  Expires: [Date picker] or [Never]   │
  │                                      │
  │  [Cancel]           [Grant Override] │
  └──────────────────────────────────────┘

For toggling DENY (red border):
  ┌──────────────────────────────────────┐
  │  ⚠️  DENY Override: pos.refund       │
  │  This will block the employee even   │
  │  if their role grants this access.   │
  │  Reason: ____________________        │
  │  Expires: [Date picker] or [Never]   │
  │                                      │
  │  [Cancel]            [Apply DENY]    │
  └──────────────────────────────────────┘
```

---

## F.4 — Branch Restriction Manager

Separate screen for branch-level overrides:

```
┌─────────────────────────────────────────────────────┐
│  BRANCH RESTRICTIONS — Main Branch                  │
├──────────────────────────────────┬──────────────────┤
│  PERMISSION                      │  STATUS          │
├──────────────────────────────────┼──────────────────┤
│  inventory.adjust                │  🏢 BLOCKED      │
│  pos.void                        │  🏢 BLOCKED      │
│  expenses.approve                │  ✅ Unrestricted │
│  pos.refund                      │  ✅ Unrestricted │
└──────────────────────────────────┴──────────────────┘
  [+ Add Branch Restriction]
```

---

## F.5 — Context Policy Builder

```
┌─────────────────────────────────────────────────────────┐
│  CONTEXT POLICIES — Main Branch                         │
├─────────────────────────────────────────────────────────┤
│  + Policy: Restrict offline access to dangerous actions │
│    Type: offline_mode                                   │
│    Applies to: is_dangerous = true                      │
│    Config: allowed_offline = false                      │
│    Status: ✅ Active                                    │
│                                                         │
│  + Policy: Shift hours for POS module                   │
│    Type: shift_hours                                    │
│    Applies to: module = pos                             │
│    Config: Mon–Sat, 08:00–22:00                         │
│    Status: ✅ Active                                    │
└─────────────────────────────────────────────────────────┘
  [+ Add Policy]
```

---

---

# SECURITY ADDENDUM

## Updated RLS Policies for New Tables

```sql
-- user_permissions
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_permissions_business_isolation ON user_permissions
  USING (business_id = (auth.jwt() ->> 'business_id')::uuid);

-- branch_permissions
ALTER TABLE branch_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY branch_permissions_business_isolation ON branch_permissions
  USING (business_id = (auth.jwt() ->> 'business_id')::uuid);

-- permission_policies
ALTER TABLE permission_policies ENABLE ROW LEVEL SECURITY;

CREATE POLICY permission_policies_business_isolation ON permission_policies
  USING (business_id = (auth.jwt() ->> 'business_id')::uuid);

-- effective_permissions — employees can only read their own snapshot
ALTER TABLE effective_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY effective_permissions_read ON effective_permissions
  FOR SELECT
  USING (
    business_id = (auth.jwt() ->> 'business_id')::uuid
    AND (
      employee_id = (auth.jwt() ->> 'employee_id')::uuid
      OR (auth.jwt() ->> 'role') IN ('owner', 'admin')
    )
  );

-- Only the compute function (SECURITY DEFINER) may write effective_permissions
CREATE POLICY effective_permissions_no_direct_write ON effective_permissions
  FOR INSERT USING (false);

CREATE POLICY effective_permissions_no_direct_update ON effective_permissions
  FOR UPDATE USING (false);
```

## Audit Log Integration

All writes to `user_permissions`, `branch_permissions`, `permission_policies` must be logged:

```sql
CREATE OR REPLACE FUNCTION log_permission_change()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (
    business_id, action, table_name, record_id,
    old_value, new_value, performed_by, created_at
  ) VALUES (
    NEW.business_id,
    TG_OP,
    TG_TABLE_NAME,
    NEW.id,
    to_jsonb(OLD),
    to_jsonb(NEW),
    (auth.jwt() ->> 'employee_id')::uuid,
    now()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER audit_user_permissions
  AFTER INSERT OR UPDATE OR DELETE ON user_permissions
  FOR EACH ROW EXECUTE FUNCTION log_permission_change();

CREATE TRIGGER audit_branch_permissions
  AFTER INSERT OR UPDATE OR DELETE ON branch_permissions
  FOR EACH ROW EXECUTE FUNCTION log_permission_change();
```

---

---

# FUTURE AI EXTENSION POINTS

The system is designed to be AI-ready at three levels:

1. **AI Permission Auditor** — AI can analyze `effective_permissions` + `audit_logs` to detect anomalies (unusual overrides, escalation patterns)

2. **AI Permission Recommender** — Based on employee behavior patterns, AI can suggest optimal permission sets for new roles

3. **AI Policy Generator** — AI can propose `permission_policies` (e.g., "based on sales data, restrict discounts after 9pm at Branch 3")

All of these operate read-only on existing data — no schema changes required.

---

*Last updated: See UPSENSO_SCHEMA.md for complete table definitions.*
*See UPSENSO_RLS.md for complete RLS policies.*
*See UPSENSO_PERMISSIONS.md for permission code catalog.*
