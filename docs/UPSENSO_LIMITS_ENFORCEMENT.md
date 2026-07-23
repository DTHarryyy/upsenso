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
| **Devices** | (registration is online-only; no local create) | RPC `register_device` returns `cap_reached` at `max_devices` | runbook §4 |
| **Checkout attempts** | — | `create-checkout` edge fn: `billing.manage` + ≤5 pending/hr → 429 | runbook §9–§10 |

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
