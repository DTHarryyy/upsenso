# UPSENSO — Usage-Limit Enforcement (audit + contract)

Every plan-capped resource (team members, branches, devices) and every abuse
guard (checkout attempts) is enforced across up to three layers. This doc is the
map of what enforces what, where it's proven, and the contract any **new** limit
must follow so the 2026-07-18 seat-meter bug can't recur.

## The bug this doc exists to prevent

The seat usage meter and the client cap pre-check both read **one number that
came only from the server** (`get_my_entitlement` → `active_seat_count`, counted
server-side). On the local-only Free tier — and any time local data hasn't
synced — that number is stale, so the meter froze at its last server value and
the pre-check never blocked. Fix: **count structural usage from the local Drift
source of truth** (`EntitlementService.liveUsageOf` / `recomputeLocalUsage`),
keeping only the genuinely cross-device `device_count` server-sourced.

Root lesson: *a usage meter must be counted from the same source of truth the
resource is created in.* Seats and branches live locally → count locally.

## Enforcement matrix

| Resource | Client pre-check (UX) | Server hard cap (authority) | Proven by |
|---|---|---|---|
| **Team members** (seats) | `EntitlementService.canAddAnother(seats)` — live Drift count, in `employees_repository_impl.addEmployee` | RPC `create_employee_auth_account` (`SEAT_LIMIT_REACHED`) + `employees_cap_insert` RLS + `enforce_seat_cap_on_reactivate` trigger | `entitlement_service_test` "seat cap blocks…"; runbook §3 |
| **Branches** | `canAddAnother(branches)` — live Drift count, in `branch_cubit.addBranch` | `branches_cap_insert` RLS (`count < effective_limits().max_branches`) | `entitlement_service_test` "branch cap blocks…"; runbook §3 |
| **Devices** | (registration is online-only; no local create) — `PlanNoticeService` surfaces `capReached` in Notifications, re-verified on the SyncService entitlement tick | RPC `register_device` returns `cap_reached` at `max_devices` | runbook §4 |
| **Over-cap holdings** (downgrade / lapse) | `EntitlementEnforcementService.reconcile()` locks the excess; `assertBranchWritable` guards every write | Existing rows are never rejected server-side — only new INSERTs are. This layer is client-only by nature | `entitlement_enforcement_service_test` |

> The `create-checkout` edge function row was removed on 2026-08-01: the
> function was deleted during the PayMongo → Play Billing move (`PLAY_BILLING`
> §5), so there is no longer a checkout-attempt limit to document.

### Over-cap enforcement — the one-month loophole (added 2026-08-01)

`canAddAnother` only stops the *next* create. Before this, buying one month of
Growth, creating five branches and twelve staff logins, then cancelling kept all
of it working forever — the caps were checked on insert and never again.

`EntitlementEnforcementService` closes that. Exactly N branches / seats stay
**active** (N = the plan cap); the excess is **locked**, never deleted:

- Locked branches stay readable, reportable and exportable. They cannot be sold
  on, written to, or selected in the branch switcher.
- Suspended staff keep their record and their history; they just don't hold a
  seat. Reactivating one at the cap is refused (and the server's
  `enforce_seat_cap_on_reactivate` trigger refuses it too).
- **Nothing ever stops mid-shift.** The branch currently open in POS is always
  in the default active set. The owner re-picks from Billing → Usage.
- Upgrading releases every lock automatically — no manual cleanup.

State lives in the local-only Drift table `entitlement_locks` (schema v60). It
has no Supabase counterpart on purpose: a lapsed tenant has cloud sync off
anyway, so there is nothing to reconcile. The trade-off is that two devices on a
*paid* downgrade can pick different active sets until the owner confirms one;
the server caps still bound the total.

### Offline verification window (added 2026-08-01)

Google Play renews silently and the client only learns about it through
`get_my_entitlement()`. A paying merchant offline over their renewal date used
to be downgraded on the spot despite having been charged.

`effectiveStatus` now returns **`unverified`** between `current_period_end` and
`last_server_sync_at + window` (14 days monthly, 30 annual). Inside the window
the tier — and cloud sync — stay live behind a "connect to keep your plan"
banner. It is anchored on the server timestamp, never the device clock alone, so
going offline deliberately buys at most one window and rewinding the clock buys
nothing. Distinct from `past_due`, which means *we know the payment failed*;
`unverified` means *we don't know*.

### Feature gates are a different animal — UX only, by design

The plan also gates **capabilities** (not counts) through `feature_flags`:
`crm`, `procurement`, `reports`, and `audit`. These resolve client-side in
`EntitlementService.featureAllowed()` → `PermissionService.canAccessFeature()`,
which drives `PermissionGate` and the router's `routeEntitlementGuards`.

**Nav is the exception, and getting this wrong caused a real bug.** Nav items do
*not* consult `featureAllowed` to decide visibility — they consult
`planLockFor()` (`core/permissions/feature_plan_requirement.dart`) to decide
which **tier badge** to render. The rule, applied identically in `more_page.dart`
and `main_navigation_page.dart`:

```
permission ✗  → hidden           (RBAC boundary — never an upsell)
module     ✗  → hidden           (the owner's own toggle)
plan       ✗  → VISIBLE + badge  (the upsell; tap opens the upgrade sheet)
```

On 2026-07-31 `AppRoutes.fraud` gained a `routeEntitlementGuards` entry while
both nav builders kept rendering a plain, tappable "Unusual Activity" item. On
Free and Starter it was a visible control wired to a guard it could never pass:
tapping it silently redirected to the dashboard. If you add a
`routeEntitlementGuards` entry, add the matching `requiredPlanFor` case in the
same commit — `feature_plan_requirement_test` asserts the two agree on every
tier.

**There is no server cap behind them, and that is deliberate.** They gate
*local, already-downloaded* data — hiding the Audit Logs page does not protect
anything cloud-priced, and the row-level tenant policies still apply to every
read. Do not mistake a feature gate for a security boundary: the structural caps
above are enforced server-side because they cost us money; feature flags are
packaging.

| Flag | Value | What it gates |
|---|---|---|
| `audit` | `local` \| `cloud` \| `full` | Two surfaces on two rungs (split 2026-08-01): `cloud` → the **Audit Logs viewer** (`AppFeature.auditLogs`); `full` → adds the **Unusual Activity** dashboard (`AppFeature.fraudAlerts`) + cross-device fraud sync. The chain records on every tier; audit rows always ship in the free Data Export, so the record stays retrievable (§4.7 + BIR). Before the split both gated on `full`, leaving Starter paying for a `cloud` rung it could never reach. |
| `reports` | `basic` \| `full` | `full` → Branch Comparison tab + report PDF/Excel export. Sales / Inventory / Profit are ungated. **Not** the full Data Export, which is tier-free. |
| `crm` | `false` \| `basic` \| `full` | directory access; `full` unlocks the deeper views |
| `procurement` | `bool` | procurement + supplier directory |

Verified deployed to prod 2026-07-18 (`npx supabase db query --linked`): all
five server objects above are present and carry their cap logic.

### Enforcement profiles differ per resource — know which gate is load-bearing

- **Team members** are created **online-only** (a new employee needs a Supabase
  auth account to log in). So the server RPC is the real authority even on Free.
  The client pre-check is UX polish + the offline-truth meter.
- **Branches** are created **local-first, remote best-effort**. An offline Free
  device can create a branch with no server round-trip, so **the client
  pre-check is the only gate offline**; server RLS catches it on sync/online.
- **Devices** only matter on cloud tiers (registration is a cloud RPC). Free =
  local-only, one device, nothing to register — the cap is a non-event there.
- **Free-tier limits are inherently soft** (client-only when fully offline).
  That's acceptable by design: Free is local-only, so there is nothing
  cloud-priced to protect — "tampering unlocks nothing with cloud value." Hard
  enforcement matters on cloud tiers, where the server is always the referee.

## The contract every new limited resource must follow

1. **Count from the source of truth.** If the resource is created locally (Drift),
   count it locally in `EntitlementService.liveUsageOf`. Only truly cross-device
   counts (devices) stay server-sourced. Never let the meter read a number the
   local device can't verify.
2. **Client pre-check is live + async.** `canAddAnother(resource)` counts at call
   time (`liveUsageOf`), never off a cached snapshot, so it can't run stale.
3. **Server hard cap is the authority for cloud tiers.** Add a RESTRICTIVE RLS
   policy (or an in-RPC check for SECURITY-DEFINER paths that bypass RLS) keyed on
   `effective_limits_for(business)`. Not behind `cloud_gate_enforced` — structural
   caps apply on every tier.
4. **Refresh the meter on mutation + load.** Call `recomputeLocalUsage()` after
   create/remove/activate and on the billing page load / bootstrap.
5. **Prove it blocks with a test.** A unit test that seeds usage *to the cap* and
   asserts `canAddAnother == false`, plus a runbook entry (`tool/billing_rls_checks.sql`)
   that proves the server rejects the over-cap write. Present-but-untested ≡ not done.

## Bug-class checklist — how to spot "limit looks enforced but isn't"

- [ ] Is the usage number counted from where the resource actually lives, or from
      a lagging cache/RPC? (The seat bug: counted server-side, created locally.)
- [ ] Does the pre-check read a **live** count or a cached one?
- [ ] Does the meter refresh after a create/remove, or only on a full reload?
- [ ] Is the server cap **deployed** to prod (not just written in a migration)?
      Verify: `pg_get_functiondef` contains the cap; the RLS policy exists.
- [ ] For SECURITY-DEFINER RPCs (which bypass RLS): is the cap **inside the RPC**,
      not only in an RLS policy that the RPC skips?
- [ ] Is there a test that actually seeds to the cap and asserts a block?
- [ ] For "rate limits": does it survive cold starts / count the right window?
      (`create-checkout` counts pending rows in the last hour — DB-backed.)
