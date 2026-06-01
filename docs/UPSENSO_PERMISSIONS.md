# UPSENSO PERMISSION SYSTEM

This document defines the complete permission matrix for UPSENSO.

It is used for:

- UI access control
- Backend authorization
- API guards
- Role configuration
- Admin panel toggles
- AI permission reasoning

---

# CORE CONCEPT

UPSENSO uses **RBAC (Role-Based Access Control)**.

Flow:

Employee
→ Roles
→ Permissions
→ Access Granted / Denied

Permissions are NEVER hardcoded in UI or backend logic.

---

# PERMISSION FORMAT

All permissions follow:

```
module.action
```

Examples:

- pos.use
- pos.discount
- inventory.adjust
- expenses.approve
- employees.create

---

# PERMISSION MATRIX

## POS MODULE

| Permission | Description | Risk |
|------------|------------|------|
| pos.use | Use POS system | Low |
| pos.open_shift | Open shift | Low |
| pos.close_shift | Close shift | Low |
| pos.discount | Apply discount | Medium |
| pos.refund | Refund transaction | High |
| pos.void | Void transaction | High |

---

## PRODUCTS MODULE

| Permission | Description | Risk |
|------------|------------|------|
| products.view | View products | Low |
| products.create | Create products | Low |
| products.update | Update products | Low |
| products.delete | Delete products | High |

---

## CATEGORIES MODULE

| Permission | Description | Risk |
|------------|------------|------|
| categories.view | View categories | Low |
| categories.create | Create categories | Low |
| categories.update | Update categories | Low |
| categories.delete | Delete categories | High |

---

## INVENTORY MODULE

| Permission | Description | Risk |
|------------|------------|------|
| inventory.view | View inventory | Low |
| inventory.adjust | Adjust stock manually | High |
| inventory.transfer | Transfer stock | High |
| inventory.count | Stock counting | Low |
| inventory.receive | Receive stock | Low |
| inventory.issue | Issue stock | Medium |

---

## EXPENSES MODULE

| Permission | Description | Risk |
|------------|------------|------|
| expenses.view | View expenses | Low |
| expenses.create | Create expense | Low |
| expenses.approve | Approve expense | High |
| expenses.delete | Delete expense | High |

---

## TRANSACTIONS MODULE

| Permission | Description | Risk |
|------------|------------|------|
| transactions.view | View transactions | Low |
| transactions.refund | Refund transaction | High |
| transactions.void | Void transaction | High |

---

## EMPLOYEES MODULE

| Permission | Description | Risk |
|------------|------------|------|
| employees.view | View employees | Low |
| employees.create | Create employee | Low |
| employees.update | Update employee | Medium |
| employees.delete | Delete employee | High |
| employees.assign_roles | Assign roles | High |

---

## ROLES MODULE

| Permission | Description | Risk |
|------------|------------|------|
| roles.view | View roles | Low |
| roles.create | Create roles | Low |
| roles.update | Update roles | Medium |
| roles.delete | Delete roles | High |

---

## BRANCHES MODULE

| Permission | Description | Risk |
|------------|------------|------|
| branches.view | View branches | Low |
| branches.create | Create branch | Low |
| branches.update | Update branch | Medium |
| branches.delete | Delete branch | High |

---

## REPORTS MODULE

| Permission | Description | Risk |
|------------|------------|------|
| reports.view | View reports | Low |
| reports.export | Export reports | Medium |

---

## SETTINGS MODULE

| Permission | Description | Risk |
|------------|------------|------|
| settings.view | View settings | Low |
| settings.update | Update settings | High |

---

## AUDIT MODULE

| Permission | Description | Risk |
|------------|------------|------|
| audit.view | View audit logs | Low |
| audit.export | Export audit logs | Medium |

---

## BUSINESS MODULE

| Permission | Description | Risk |
|------------|------------|------|
| business.view | View business info | Low |
| business.update | Update business settings | High |

---

## MODULES SYSTEM

| Permission | Description | Risk |
|------------|------------|------|
| modules.manage | Enable/disable modules | Critical |

---

# ROLE RECOMMENDATIONS

## OWNER
Full access

- All permissions enabled

---

## ADMIN
Almost full access except system-level control

Allowed:
- POS
- Inventory
- Expenses
- Reports
- Employees

Denied:
- modules.manage (optional restriction)

---

## MANAGER
Operational control

Allowed:
- POS
- Inventory view/adjust
- Expenses approve
- Reports view

Denied:
- delete operations
- roles management

---

## CASHIER
POS only

Allowed:
- pos.use
- pos.open_shift
- pos.close_shift

Denied:
- inventory
- expenses
- employees

---

## INVENTORY STAFF

Allowed:
- inventory.view
- inventory.receive
- inventory.count

Denied:
- inventory.adjust (optional restriction)
- financial operations

---

# UI USAGE PATTERN

## Button Example

```dart
if (hasPermission('products.create')) {
  showAddProductButton();
}
```

---

## Screen Access Example

```dart
if (!hasPermission('inventory.view')) {
  showAccessDenied();
}
```

---

## API Guard Example

```ts
requirePermission('expenses.approve')
```

---

# MODULE + PERMISSION COMBINATION

Even if permission exists:

IF module is disabled:

→ BLOCK ACCESS

Example:

if (!moduleEnabled('inventory')) {
  denyAccess();
}

---

# DANGEROUS ACTIONS

Any permission marked:

is_dangerous = true

Must:

- show confirmation dialog
- log audit entry
- trigger fraud detection check
- require stricter role validation

Examples:

- refunds
- void transactions
- delete operations
- role changes
- inventory adjustments

---

# FRAUD INTEGRATION

Permissions are tied to fraud detection.

Example rules:

- Too many refunds → flag employee
- Inventory adjustment abuse → flag employee
- Role escalation attempts → critical alert

---

# DESIGN RULES

- NEVER hardcode roles
- NEVER hardcode permissions
- ALWAYS use permission codes
- ALWAYS validate module access first
- ALWAYS log sensitive actions
- ALWAYS consider fraud risk