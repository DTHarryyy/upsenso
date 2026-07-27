# Google Play Billing — Audit & Fix Plan

Audit date: 2026-07-27 · Branch: `main` · Status: **fixed and verified in prod**

## Outcome (2026-07-27)

| Fix | Where | State |
|---|---|---|
| F1 service_role table grants | `20260727000001_service_role_grants.sql` | **applied to prod** |
| F2 edge-function error handling | both functions + `_shared/google_play.ts` | **deployed** (v2 each) |
| F3 no auto-granted trial | `20260727000002_no_auto_trial.sql` | **applied to prod** (new businesses only) |
| F4 page repaints on entitlement change | `billing_cubit.dart`, `billing_state.dart` | code |
| F5 app-scoped purchase listener + startup restore | `play_purchase_sync_service.dart`, `di.dart`, `bootstrap.dart` | code |

Verified after applying: `service_role` now holds SELECT/INSERT on every billing
table; the RTDN retry storm **stopped** — the backlog of 10 distinct
notifications (2 test, 2 voided, 6 subscription) drained in 12 seconds and the
endpoint has been quiet since, against 2–5 failing requests/second before.
`billing_webhook_events` went 0 → 10 rows.

Gates: `flutter analyze` clean, `flutter test` 162 passing.

**Still to do:** an end-to-end purchase on a License Tester account (see
§Verification) — that is the only thing that proves the grant path front to back.
The 6 drained subscription notifications referenced tokens that were never
registered (because verify never succeeded), so they logged
"unknown token — client verify will land" and are now idempotency-consumed. The
tester's next purchase or Restore is what registers the token.

### Two corrections to the original audit

1. **Hold / pause were not defects.** §4 called the immediate `expire` on
   `SUBSCRIPTION_STATE_ON_HOLD` / `_PAUSED` too harsh. It matches Google's own
   guidance — access should be revoked in both — and recovery is already
   automatic: a recovery/restart notification re-fetches state and re-applies
   through `apply_play_subscription`. No code change; the table below is
   corrected and `decideFromState` only gained a comment plus logging for
   genuinely unmapped states.
2. **"F6 — acknowledge on terminal failure" was wrong and was dropped.**
   Completing a purchase the server refused would leave the user charged, with no
   entitlement, and past Google's 3-day auto-refund window. Leaving it
   unacknowledged is what makes Google refund them. The service now deliberately
   never completes a purchase it could not grant — with a regression test
   pinning that — and instead retries transient failures automatically when the
   network returns.

### Beyond billing

`service_role` had **no privileges on any table in `public`** — `products`,
`businesses`, `employees` included. Any other server-side path using the service
key was equally broken; billing is just where it surfaced. Worth a sweep of the
other edge functions (`send-employee-credentials`, and the PayMongo pair still
deployed but slated for deletion).

---

## Context

Upsenso is pre-release with Play Billing integrated. Purchases go through in the
Play dialog, but the app never reflects them: the Billing screen shows *"We
couldn't confirm your purchase yet"* and the plan card still reads "Free —
Current plan". Three symptoms (verification, refresh, restore) plus a
split-source-of-truth display bug were reported as release blockers.

The audit traced the evidence anchor outward and then verified against the live
Supabase project (`dmhyfezuravbjpoxjesb`, read-only queries + edge-function
logs). The result is **not** an app-side bug. Two independent, provable backend
defects account for every reported symptom, and one of them is currently
generating a runaway Pub/Sub retry storm.

**Verified prod state (2026-07-27):**

| Check | Result |
|---|---|
| `verify-play-purchase` deployed | yes, v1, `verify_jwt=true` |
| `google-play-rtdn` deployed | yes, v1, `verify_jwt=false` |
| `play_product_map` rows | 4 (correctly seeded) |
| `play_purchase_tokens` rows | **0** |
| `subscriptions where provider='google_play'` | **0** |
| `billing_payments where provider='google_play'` | **0** |
| `billing_webhook_events` rows | **0** |
| `google-play-rtdn` HTTP status, last 24h | **500 on every delivery**, ~2–5/sec sustained |

**No purchase has ever been recorded.** The entitlement engine has never seen a
Play grant.

---

## 1. Entitlement chain

```
Google Play (authoritative billing state)
  └─ in_app_purchase plugin
     └─ IapService.purchaseStream                       iap_service.dart:46
        └─ BillingCubit._onPurchases                    billing_cubit.dart:247
           └─ BillingCubit._verifyAndFinish             billing_cubit.dart:284
              └─ BillingRemoteDs.verifyPlayPurchase     billing_remote_ds.dart:113
                 └─ POST edge fn verify-play-purchase   verify-play-purchase/index.ts:84
                    ├─ get_my_business_id()  (as authenticated)        :113
                    ├─ has_permission('billing.manage')                :117
                    ├─ Google subscriptionsv2.get        google_play.ts:100
                    ├─ resolvePlan → play_product_map    (as service_role)  :59
                    └─ apply_play_subscription()  ← SOLE GRANTOR       :169
                       └─ public.subscriptions           play_grant_fns.sql:104
                          ↑ also written by google-play-rtdn (renew/cancel/refund)
                             └─ get_my_entitlement()     registered_devices.sql:161
                                └─ EntitlementRemoteDs   entitlement_remote_ds.dart:15
                                   └─ Drift entitlement_cache  entitlement_service.dart:106
                                      └─ EntitlementService (in-memory _cached)
                                         ├─ AccountStatusBanner (live)   account_status_banner.dart:20
                                         ├─ SyncService / router guards
                                         └─ BillingCubit._withEntitlement → BillingState (COPY)
                                            └─ BillingPage widgets       billing_page.dart:151, :250
```

**Authoritative source: `public.subscriptions` in Supabase.** Everything
downstream is cache. This is correctly designed — `IapService` grants nothing,
and the client purchase is never trusted (`iap_service.dart:23-33`).

**Two derived readers disagree by construction** (a finding, but not the cause of
the reported S4):
- `AccountStatusBanner` reads `EntitlementService` **live**, repainting on
  `entitlementRevision` — `account_status_banner.dart:20-22`.
- `BillingPage` reads a **snapshot copy** taken into `BillingState` at
  `load()` — `billing_cubit.dart:316-330`. The cubit never listens to
  `entitlementRevision`, so a background entitlement change updates the shell
  banner and leaves the Billing page stale until the next `load()`.

---

## 2. Root causes

| Symptom | Root cause | Evidence | Conf. |
|---|---|---|---|
| **S1** verification fails | `service_role` has **no table privileges on any `public` table**. `relacl` = `{postgres=…,authenticated=…}` — service_role absent; `member_of` = null; `rolbypassrls=true` (bypasses RLS, but GRANTs still apply). `resolvePlan`'s `play_product_map` SELECT dies with 42501 → `planRow=null` → **400 "Unknown product"** | `verify-play-purchase/index.ts:74-81`, `:145-151`; prod `pg_class.relacl` | **H** |
| **S1** (masking) | Every `admin.from(...)` destructures `{ data }` and **never checks `error`**, so a permission denial silently becomes "not found" and surfaces as the wrong message | `verify-play-purchase/index.ts:75`, `:154`, `:186`, `:196` | **H** |
| **S1** (RTDN arm) | `billing_webhook_events` INSERT dies with 42501; code is not `23505` → returns **500** → Pub/Sub retries forever. Explains 0 ledger rows + the 500 storm | `google-play-rtdn/index.ts:100-109` | **H** |
| **S2** plan doesn't refresh | Downstream of S1: `load()` + the clearing `emit` are inside the `try`, after `verifyPlayPurchase`. Verify throws → refresh never runs | `billing_cubit.dart:286-292` | **H** |
| **S2** (independent) | `BillingState` is a one-shot copy of `EntitlementService`; the cubit never subscribes to `entitlementRevision`, so an RTDN/background entitlement change does not repaint the page | `billing_cubit.dart:316-330` | **H** |
| **S2** (independent) | `copyWith` cannot clear nullables — `daysRemaining ?? this.daysRemaining`. A trial→active transition keeps the stale "2 days left" forever | `billing_state.dart:113-120` | **H** |
| **S3** restore | No automatic restore exists. `IapService` is consumed **only** by the page-scoped `BillingCubit`; nothing listens at app scope and nothing calls `restorePurchases()` at startup. The silent backfill is additionally dead on a reinstall — it early-returns when `planCode == 'free'`, which is exactly the reinstall state | `billing_cubit.dart:221`; `billing_page.dart:31-42`; DI `di.dart:513` | **H** |
| **S4** split source | **One row, two truths.** `grant_initial_trial()` inserts `plan_code='free'` **with a `'starter'` `entitlement_snapshot`**. `effective_limits` reads the snapshot (Starter caps, cloud on); the UI reads `plan_code` ("Free"). All 9 prod subscription rows are `plan_code='free' / status='trialing'` | `20260707000001_billing_foundation.sql:492-510`; prod query | **H** |
| **S4** (display) | `currentCode` maps only `free`/`lapsed` → 'free'; `trialing` on `plan_code='free'` therefore marks the **Free** card "Current plan" while the banner reads the trial branch | `billing_page.dart:250-253` vs `:151-158` | **H** |

Per the product steer — *no free trial unless we deliberately create one for a
plan* — the S4 fix is to stop auto-granting the trial, not to re-skin the UI.

---

## 3. Fix plan (ranked)

### F0 — Stop the RTDN retry storm *(do first, minutes)*

The Pub/Sub push subscription has been retrying a 500 endpoint for at least 24h.
Nothing is recorded, and every retry burns an edge-function invocation. F1 fixes
the 500 at the source, so the cleanest sequence is: **apply F1, then confirm the
storm stops**. If F1 slips, pause the push subscription in GCP as a stopgap.

Nothing to change in the repo. Verification: `get_logs(edge-function)` shows
`google-play-rtdn` returning 200, and `billing_webhook_events` starts filling.

---

### F1 — Grant `service_role` its table privileges *(P0, the actual blocker)*

**What changes.** One new additive migration,
`supabase/migrations/20260727000001_service_role_grants.sql`:

- `GRANT USAGE ON SCHEMA public TO service_role;`
- `GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO service_role;`
- `GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO service_role;`
- `ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT … TO service_role;` so future
  tables don't regress.

**Why it fixes the root cause.** `service_role` is currently absent from every
table ACL and inherits from no role. `rolbypassrls=true` bypasses RLS policies
but **not** GRANTs — that is precisely why this looked like an RLS-correct setup
while every service-role write failed. Restoring the grants makes
`resolvePlan` find the product, `apply_play_subscription` run, the token index
and payment ledger write, and the RTDN ledger insert succeed.

**Blast radius.** Project-wide, and deliberately so — `service_role` has no
privileges anywhere, so this is not billing-specific. It restores the Supabase
default posture. RLS is untouched; `service_role` already bypassed RLS, so this
grants **no new data reach** to anything holding the service key. The service key
is server-only (edge functions), never shipped to the client.

**What could break.** Nothing that works today starts failing — this is purely
additive. The genuine question is whether the grants were *deliberately* revoked
as a hardening measure. Evidence says no: the two Play migrations explicitly
`GRANT EXECUTE … TO service_role` (`play_grant_fns.sql:140`, `:192`), i.e. the
design assumes service_role is a working principal. See open question Q1.

**Rollback.** `REVOKE ALL ON ALL TABLES IN SCHEMA public FROM service_role;` plus
reverting the default privileges. Returns to today's state exactly.

**Narrower alternative** (if Q1 says the revoke was intentional): grant only
`play_product_map` (SELECT), `play_purchase_tokens` (SELECT/INSERT/UPDATE),
`billing_payments` (INSERT), `billing_webhook_events` (INSERT), `plans` (SELECT).
Smaller blast radius; leaves the rest of the project's service_role paths broken
and will resurface as the next bug.

**Test (License Tester).** Buy Starter monthly → snackbar gone, card flips to
Starter; `subscriptions` shows `provider='google_play'` and
`current_period_end` = Google's expiryTime; `play_purchase_tokens` gains a row;
`billing_payments` gains a paid row. RTDN: cancel in Play → `billing_webhook_events`
gains a row, endpoint returns 200.

---

### F2 — Stop swallowing PostgREST errors in the edge functions *(P0, same PR)*

**What changes.** In `verify-play-purchase/index.ts` and
`google-play-rtdn/index.ts`, destructure and check `error` on every
`admin.from(...)` call (`:75`, `:79`, `:154`, `:186`, `:196`, `:203`). A DB error
must return 500 with the real cause, distinct from the 400 "Unknown product" that
means *the product genuinely isn't mapped*. Log `error.code`/`error.message`.

**Why.** This is why S1 presented as an unactionable snackbar instead of
"permission denied for table play_product_map". Without it, the next
infrastructure fault produces the same dead end. ~10 lines, no structural change.

**Blast radius.** Edge functions only. Risk: a previously-silent failure now
returns 500 — which is the point, and for RTDN correctly triggers a Pub/Sub retry.

---

### F3 — Do not auto-grant a trial *(P0, fixes S4 at the source)*

**What changes.** New migration replacing `grant_initial_trial()`
(`20260707000001_billing_foundation.sql:466-531`) so a new business lands on a
plain Free plan: `plan_code='free'`, `status` free-equivalent, `trial_end=NULL`,
and an **honest** `entitlement_snapshot` built from `plan_limits` for
`free/v1` — not Starter's. Keep the trigger, `trial_claims`, and
`billing_settings.trial_days` in place so a future plan-attached trial can be
switched on by writing `plan_code='<paid tier>' , status='trialing'`.

**Why it fixes the root cause.** The disagreement is one row holding two answers:
`plan_code='free'` with a Starter snapshot. Removing the phantom trial collapses
it to one truth. The banner's `trialing` branch stops firing, the plan card's
"Free — Current plan" becomes correct and unambiguous, and `_isDowngrade`
(`billing_cubit.dart:204`) stops reasoning about a plan the tenant isn't on.

**Blast radius.** Signup path + the 9 existing prod businesses. **Existing rows
are the sensitive part:** they currently enjoy Starter limits and cloud sync via
the Starter snapshot. Rewriting them to Free revokes cloud sync from live test
tenants. See open question Q2 — no data backfill is planned without that call.

**What could break.** Any test tenant relying on trial cloud sync loses it at the
next entitlement sync. Local data is untouched (`expire`/lapse semantics keep the
POS selling — `entitlement_service.dart:192-196` fails closed only for cloud).

**Test.** Create a fresh business → `subscriptions` row is `free/free`,
`trial_end` null; Billing page shows Free as current with **no** trial banner;
`AccountStatusBanner` renders nothing.

---

### F4 — Refresh the plan immediately after purchase *(P1, S2)*

**What changes.** Three small edits in `billing_cubit.dart` / `billing_state.dart`:

1. Subscribe to `_entitlement.entitlementRevision` in the cubit constructor and
   re-emit `_withEntitlement(state)` on each bump; dispose in `close()`
   (alongside `_purchaseSub` at `:334`). Kills the snapshot-vs-live divergence
   for RTDN-driven and background changes.
2. Add explicit `clearDaysRemaining` / `clearGrandfatheredPrice` flags to
   `copyWith` (mirroring the existing `clearPurchaseError` idiom at
   `billing_state.dart:105`) so a trial→active transition clears stale values.
3. In `_verifyAndFinish`, move the success `emit` so `purchaseInProgress` is
   cleared in a `finally`, not only on the happy path.

**Why.** Once F1 lands, `load()` already runs after a successful verify — but only
on that path, and only for purchases made while the page is open. (1) covers
everything else. **No new dependency, no new layer** — `entitlementRevision` is
the existing mechanism, already consumed by the router (`app_router.dart:107`)
and `SyncService` (`sync_service.dart:324`).

**Blast radius.** Billing page only. Risk: a revision bump during `load()` causes
an extra emit; `BillingState` is `Equatable`, so identical states don't rebuild.

**Test.** Buy on the Billing page → card flips with **no** restart. Cancel in
Play on another device → within one RTDN cycle + entitlement sync, the page
updates without navigation.

---

### F5 — Restore automatically, and never lose a purchase *(P1, S3 + P0-grade prod risk)*

**What changes.**

1. Register a small app-scoped listener that owns `IapService.purchaseStream` for
   the process lifetime and routes each event through the same
   verify-then-complete path. Simplest shape that preserves the architecture: a
   `PlayPurchaseSyncService` in `lib/features/billing/data/`, registered
   `registerLazySingleton` in `di.dart` next to `IapService` (`:513`) and started
   from `bootstrap.dart` after auth (near the existing entitlement sync at
   `:103`). `BillingCubit` keeps its own listener for UI feedback — the plugin's
   stream is a broadcast stream, so both may listen.
2. Call `restorePurchases()` once per session at startup on Android when signed
   in, so a reinstall or second device recovers without user action.
3. Drop the `state.planCode == 'free'` guard at `billing_cubit.dart:221` — it
   disables the backfill in exactly the reinstall case it exists to serve.

**Why.** Today `IapService` has exactly one consumer, created in
`BlocProvider.create` (`billing_page.dart:32`) and cancelled on page dispose
(`:334`). A purchase that completes while the user is anywhere else — or a
`pending` payment that resolves hours later — is **never** delivered, **never**
verified, and therefore **never acknowledged**. Google auto-refunds
unacknowledged purchases after 3 days. This is the single largest production risk
after F1.

**Blast radius.** New startup work on Android. Guarded by
`IapService.isSupportedPlatform`, so web/desktop/iOS are unaffected. Must be
gated on a signed-in Supabase session — verifying with no JWT returns 401 and
would burn a retry.

**What could break.** Double-processing if both listeners verify the same event.
Mitigate by making the cubit's listener presentation-only (spinner/error) and
letting the service own verify+complete. `apply_play_subscription` is idempotent
(`ON CONFLICT (business_id) DO UPDATE`, `play_grant_fns.sql:112`), so a duplicate
verify is safe but wasteful.

**Test.** Buy, then background the app before verify completes → reopen, plan is
active. Uninstall/reinstall → plan returns with no tap. Second device, same Play +
Supabase account → plan present after login.

---

### F6 — Acknowledge on the client too *(P1, revenue-protecting)*

**What changes.** In `_verifyAndFinish` (`billing_cubit.dart:284-301`), call
`completePurchase(p)` when the server responds `409 "Subscription not active"` or
`400 "Unknown product"` — terminal answers where retrying forever is pointless —
while continuing to withhold it on 5xx/network errors so a retry can re-verify.

**Why.** `completePurchase` currently runs **only** on the success path (`:290`).
The comment at `:281-283` argues the server acknowledges on grant — true
(`verify-play-purchase/index.ts:221-232`) — but that path is unreachable when the
grant fails, which is the exact state we've been in. A purchase stuck
unacknowledged for 3 days is auto-refunded.

**Blast radius.** Cubit only. Risk: acknowledging a purchase we haven't granted.
Bounded to terminal-classification responses, which requires F2's honest error
codes to land first. **F2 is a hard prerequisite.**

---

## 4. State coverage

| State | Current behaviour | Required | Evidence |
|---|---|---|---|
| Active | `grant_active` → grant `active`; expiry = Google's `expiryTime` | correct | `google_play.ts:163-165`; `play_grant_fns.sql:110` |
| Canceled (auto-renew off, paid to expiry) | `grant_canceled` → status `canceled`, access to `current_period_end`, no dunning grace | correct | `google_play.ts:166-167`; `play_grant_fns.sql:92` |
| Expired | RTDN type 13 → `expire_play_subscription` → window collapses to now, oracle lands `lapsed` | correct | `google-play-rtdn/index.ts:146-152` |
| In grace period | `grant_active` — cloud stays on; app renders `past_due` from `grace_until` | correct | `google_play.ts:164`; `entitlement_service.dart:172-178` |
| On hold | `expire` — access revoked; a recovery notification re-fetches and re-grants | correct (matches Google's guidance) | `google_play.ts` `decideFromState` |
| Paused | `expire` — access revoked; a restart notification re-fetches and re-grants | correct (matches Google's guidance) | `google_play.ts` `decideFromState` |
| Pending purchase | `pending` → spinner; now survives app kill via the app-scoped listener | correct after F5 | `play_purchase_sync_service.dart` |
| Billing retry / recovering | `PENDING` / `PENDING_PURCHASE_CANCELED` mapped to `ignore` explicitly; anything unmapped is logged | correct after F2 | `google_play.ts` `decideFromState` |
| Revoked | RTDN type 12 → expire directly, no Google fetch | correct | `google-play-rtdn/index.ts:146-152` |
| Refunded / voided | `voidedPurchaseNotification` → `expireByToken` | correct in design; **has never executed** (0 ledger rows) | `google-play-rtdn/index.ts:120-122` |

---

## 5. Production readiness

| P | Issue | Evidence | Minimal fix |
|---|---|---|---|
| **P0** | `service_role` has zero table privileges → every service-role write in the billing path fails | prod `pg_class.relacl` | F1 |
| **P0** | RTDN 500s on every delivery → unbounded Pub/Sub retry loop, nothing recorded | `get_logs`; `google-play-rtdn/index.ts:100-109` | F1 + F0 verification |
| **P0** | No app-scoped purchase listener — purchases delivered off the Billing page are lost and never acknowledged (3-day auto-refund) | `di.dart:513`; `billing_page.dart:31-42`; `billing_cubit.dart:334` | F5 |
| **P0** | PostgREST errors silently discarded in both edge functions; a permission denial masquerades as "Unknown product" | `verify-play-purchase/index.ts:75,154,186,196` | F2 |
| **P1** | `completePurchase` only on the success path → unacknowledged purchases accumulate whenever the server can't grant | `billing_cubit.dart:290` | F6 |
| **P1** | Billing page renders a stale snapshot; no subscription to `entitlementRevision` | `billing_cubit.dart:316-330` | F4.1 |
| **P1** | `copyWith` cannot clear nullable fields — stale `daysRemaining`/`grandfatheredPrice` persist across transitions | `billing_state.dart:113-120` | F4.2 |
| **P1** | Silent-restore backfill is dead exactly on reinstall (`planCode == 'free'` early return) | `billing_cubit.dart:221` | F5.3 |
| **P2** | `_onPurchases` awaits sequentially; a slow verify blocks later events in the same batch | `billing_cubit.dart:247-251` | acceptable; revisit only if batches grow |
| **P2** | No in-flight token de-dup — a duplicate stream emission triggers a second verify round trip (idempotent server-side, but wasteful) | `billing_cubit.dart:253` | set of tokens being verified |
| **P2** | Trial grant writes a Starter snapshot under `plan_code='free'` | `20260707000001_billing_foundation.sql:492-510` | F3 |

---

## 6. Security

| P | Issue | Evidence | Minimal fix |
|---|---|---|---|
| **P1** | `featureAllowed` **fails open** when the local cache is absent — clearing app data unlocks every plan-gated feature | `entitlement_service.dart:222` | keep fail-open (deliberate, documented at `:28-31`) but re-gate on the server for anything with cloud cost |
| **P1** | Entitlement cache is a plain unencrypted Drift table; no signature, no HMAC. `flutter_secure_storage` is in the project but used only for device identity | `entitlement_cache_table.dart`; `secure_storage_service.dart`, `device_identity_service.dart` | accept for local-only features; never let it gate a cloud-priced action |
| **P2** | `obfuscatedAccountId` = `sha256(businessId)` is sent to Play but **never compared** server-side against Google's `obfuscatedExternalAccountId` | `billing_cubit.dart:305-309`; `verify-play-purchase/index.ts` (no check) | compare it in `verify-play-purchase`; makes the binding real rather than decorative |
| **P2** | Token-binding check is read-then-write with no constraint — two businesses verifying the same new token concurrently both see no row and both grant | `verify-play-purchase/index.ts:154-165` vs `:186` | rely on the `purchase_token` PK: upsert **before** granting, or grant inside a transaction keyed on the token |
| **P2** | `decideFromState` default `ignore` silently accepts unknown states with no telemetry | `google_play.ts:172-174` | log the unmapped state |

**What a patched APK unlocks today.** Entitlement is bound to the **Supabase
business**, not the device — `get_my_business_id()` is derived from the JWT and
never read from the request body (`verify-play-purchase/index.ts:113-116`), and
`apply_play_subscription` is `SECURITY DEFINER`, service-role-only
(`play_grant_fns.sql:138-140`). So an attacker cannot mint a subscription, cannot
replay another tenant's token (`play_purchase_tokens` PK + the 409 at `:159`),
and cannot obtain cloud sync: `cloudEnabled` fails **closed** with no cache
(`entitlement_service.dart:192-196`) and every remote write is refereed by
`has_cloud_access()` RLS. What they *can* do is patch the APK or edit the
unencrypted `entitlement_cache` row to flip `feature_flags`, unlocking the
**local-only** premium surface: procurement/suppliers, full CRM, full
reports+export, and the cloud-audit flag. `featureAllowed` also fails **open** on
a missing cache, so simply clearing app data achieves the same without patching.
The smallest change that closes it: keep the fail-open default (it protects paying
users mid-rollout) but move the *check* for anything with server cost into the
RPC/RLS layer, so a patched client gets a local UI it cannot back with data. Given
these are on-device features on an offline-first POS, this is a low-value target —
worth accepting pre-release and documenting, not worth a client-side DRM layer.

---

## 7. Edge cases

| Case | Current | Expected | Recovery | Log | Auto-retry |
|---|---|---|---|---|---|
| App killed mid-purchase | Purchase lost; page-scoped listener is gone | Delivered on next stream attach | F5 app-scoped listener | none today | N |
| Network drop mid-verify | Snackbar; not completed, not retried | Retry on reconnect | manual Restore | `billing_cubit.dart:294` | N |
| Play unavailable / billing disconnect | `isAvailable()` exists but is **never called** | Disable CTAs with a clear reason | user retry | `iap_service.dart:55` | N |
| User cancels | `canceled` → spinner off, completed | correct | — | none | — |
| Pending payment (delayed form) | Spinner only, no persistence, no timeout | Survive restart; bounded spinner | F5 | none | N |
| Declined | `error` → snackbar, completed | correct | user retry | `billing_cubit.dart:263` | — |
| Duplicate callbacks | Both verified; server idempotent, client double round-trips | De-dup in flight | — | none | Y (server) |
| Already-owned | Restore emits `restored` → verify path | correct | — | — | Y |
| Upgrade / downgrade | `oldPurchase` + `ReplacementMode`; deferred on downgrade | correct | — | — | — |
| Renewal | RTDN re-fetch + re-apply | correct in design; **never executed** | — | RTDN 500 | Y (Pub/Sub) |
| Refund / chargeback | `voided` → `expireByToken` | correct in design; **never executed** | — | RTDN 500 | Y |
| Grace period | Granted; UI shows `past_due` | correct | — | — | — |
| Account hold | Expires immediately | Suspend, allow recovery | new purchase only | — | N |
| Paused | Expires immediately | Suspend, restore on resume | new purchase only | — | N |
| Device clock change | Clamped to `lastServerSyncAt`; back-roll can't extend grace | correct | — | — | — |
| Google account switch | Not detected | Re-restore, re-bind | manual Restore | none | N |
| Supabase logout/login | `clear()` wipes cache; revision bumps | correct | — | `entitlement_service.dart:142` | — |
| Reinstall | Silent backfill dead (`planCode=='free'` guard); manual Restore only | Automatic | F5 | — | N |
| Second device | Same as reinstall | Automatic | F5 | — | N |
| Offline startup | Cache renders; `cloudEnabled` fails closed, `featureAllowed` fails open | by design | — | `entitlement_service.dart:81` | — |
| Failed entitlement sync | Cached snapshot stays authoritative, no user signal | correct, but silent | next sync | `entitlement_service.dart:102` | Y |
| RTDN before client verify | Unknown token → 200 no-op, notification **dropped** | Client verify lands later; a renewal arriving first is lost | — | `google-play-rtdn/index.ts:140` | N |
| Stale token after upgrade | `expire_play_subscription` ignores non-current tokens | correct | — | `play_grant_fns.sql:168-173` | — |

---

## 8. Open questions

**Q1 — resolved by shipping.** The schema-wide grant was applied; nothing broke
and the storm stopped. Whether the original revoke was deliberate is still
unknown, but the design plainly assumed a working service_role
(`play_grant_fns.sql:140` grants it EXECUTE). Rollback is in the migration header
if you decide otherwise.

**Q2 — still open, and deliberately not acted on.** The 9 existing businesses
remain on the phantom trial (`plan_code='free'`, Starter snapshot, cloud on).
F3 changed only what *new* signups get. Rewriting the existing rows to Free would
revoke cloud sync from live test tenants — your call, not a migration's. Left
alone, each lapses naturally once its `trial_end` passes.

**Q3 — closed.** Hold/pause behaviour was already correct; see the correction
above.

**Q4 — answered, and it widens the finding.** `service_role` had no privileges
on *any* table, so this was never billing-specific. Other service-key paths were
broken too and are now unblocked by the same grant; worth a sweep.

**Q5 — new.** `create-checkout` and `paymongo-webhook` are still deployed
(`list_edge_functions`) despite PayMongo being retired in the M7.1 plan
(`UPSENSO_PLAY_BILLING.md` step 5). They are now *more* capable than before,
since service_role can write again. Delete them and unset the PayMongo secrets?

---

## 9. What shipped, and what is left

Shipped (all of F1–F5, plus the token-race fix and unmapped-state logging from
the old Step 5):

1. service_role grants — S1 root cause, RTDN storm.
2. Edge-function error propagation — a permission denial can no longer
   masquerade as "Unknown product".
3. Token claimed via `insert` before the grant, so the `purchase_token` primary
   key referees a concurrent double-verify instead of an advisory read.
4. No auto-granted trial for new signups — S4 root cause.
5. Billing page repaints on `entitlementRevision`; nullable entitlement fields
   can be cleared — S2.
6. `PlayPurchaseSyncService` owns the purchase stream for the app lifetime,
   restores at startup, retries transient verify failures on reconnect, and never
   acknowledges a purchase it could not grant — S3 + the auto-refund exposure.
7. Regression tests: `play_purchase_sync_service_test.dart` (8 cases, including
   the two acknowledgement rules) and 4 new `billing_cubit_test.dart` cases.

Left, in priority order:

- **License-Tester end-to-end run** — the only unproven link. Nothing below
  matters until this passes.
- **Q2** — decide what happens to the 9 existing phantom-trial businesses.
- **Q5** — delete the retired PayMongo functions and secrets.
- **P2 security** — compare Google's `obfuscatedExternalAccountId` against the
  caller's business in `verify-play-purchase`, making the account binding real
  rather than decorative.
- **P2 polish** — `IapService.isAvailable()` is still never called; the Billing
  CTAs cannot say "Play is unreachable" as distinct from "not configured".

## Verification

- **Backend:** Supabase MCP read-only — `get_logs(edge-function)` for RTDN status;
  `select count(*)` on `play_purchase_tokens`, `billing_payments`,
  `billing_webhook_events`, `subscriptions where provider='google_play'`.
- **App:** `flutter run --dart-define-from-file=flavors/dev.json` on an Android
  device signed in as a Play **License Tester**, internal track, signed build.
  Walk the F1/F4/F5 test steps above.
- **Gates:** `flutter analyze`, `flutter test test/features/billing/`,
  `flutter test test/core/permissions/`.
