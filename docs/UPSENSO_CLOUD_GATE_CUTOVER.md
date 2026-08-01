# Cloud Gate Cutover — turning the paywall on

**Status:** not applied. `billing_settings.cloud_gate_enforced` is still `FALSE`
in production.

Everything the client does about subscriptions today — plan badges, branch and
seat locks, device caps, the offline verification window — is a **UX gate on an
unsigned local Drift cache**. A determined user with a rooted device can edit
`entitlement_cache` and unlock the premium UI. What they still cannot steal is
cloud sync, and only once this flip lands.

While the gate is false, `has_cloud_access()` short-circuits to `TRUE` for every
caller, so all 25 RESTRICTIVE write policies from `20260708000001` are inert.
The subscription system is advisory, not enforced.

The migration is already written:
[`supabase/migrations/20260728000002_enable_cloud_gate.sql`](../supabase/migrations/20260728000002_enable_cloud_gate.sql).
This document is the runbook for applying it. **You run these commands — no
agent should.**

---

## 1. Preconditions

All three must be true before you flip:

- [ ] `20260728000001_play_billing_hardening.sql` is applied to prod.
- [ ] Both edge functions are deployed (`verify-play-purchase`, RTDN handler).
- [ ] `tool/billing_rls_checks.sql` §7–§11 has been run green on a preview
      branch — **not** on prod.

Plus, new since the M7.1 enforcement pass (2026-08-01):

- [ ] A build containing the client-side enforcement is live on the Play
      production track. Flipping the gate before that ships means paid tenants
      lose sync with no in-app explanation of why.

## 2. Re-count the blast radius — the old numbers have aged

The migration header quotes tenant counts measured on **2026-07-28**. Do not
trust them. Re-run this first:

```sql
SELECT public.effective_sub_status(s) AS status, count(*)
  FROM public.subscriptions s
 GROUP BY 1
 ORDER BY 2 DESC;
```

Then look specifically at who loses cloud writes the moment you apply:

```sql
SELECT s.business_id, b.name, s.plan_code, s.status,
       s.current_period_end, s.grace_until
  FROM public.subscriptions s
  JOIN public.businesses b ON b.id = s.business_id
 WHERE public.effective_sub_status(s) NOT IN ('trialing', 'active', 'past_due');
```

Every row in that second query is a real business whose next write stops
reaching the cloud. Their local data is untouched and they keep selling, but
someone should hear from you before it happens, not after.

Also check who is about to lapse on their own, so you do not conflate the two
events in the support queue:

```sql
SELECT count(*) FROM public.subscriptions
 WHERE status = 'trialing' AND trial_end < now() + interval '14 days';
```

## 3. Apply

```bash
supabase migration up --include-all   # or apply the single file, per your usual flow
```

Never `supabase db push` — see `UPSENSO_PLAY_BILLING.md` §5 for why.

The migration ends with a `DO $$ ... RAISE EXCEPTION` guard, so a missing
`billing_settings` row fails loudly instead of silently changing nothing.

## 4. Verify

```sql
SELECT cloud_gate_enforced, updated_at FROM public.billing_settings WHERE id = 1;
-- expect: t
```

Then, signed in as a lapsed tenant, confirm a write is refused and a **read is
not** — `SELECT` stays open by design so a lapsed tenant keeps reading its own
frozen copy (`20260708000001`).

## 5. Rollback — instant, no data loss

```sql
UPDATE public.billing_settings
   SET cloud_gate_enforced = false, updated_at = now()
 WHERE id = 1;
```

Local data is never touched by either direction of this flip. The gate blocks
cloud **writes** only.

## 6. After the flip

- Watch `get_logs` for a spike in RLS refusals that are *not* from lapsed
  tenants — that would mean a policy is catching someone it shouldn't.
- A lapsed tenant should hear it from the notification bell (`cloud paused`,
  via `BillingNoticeService`), and see `OverCapBanner` / `DeviceStatusBanner` in
  the shell if anything is actually locked. If support starts hearing "sync just
  stopped and nothing said why", one of those isn't reaching the screen.
