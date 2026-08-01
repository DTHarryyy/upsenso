# UPSENSO — Google Play Billing (M7.1 acquisition layer)

Billing moved from **PayMongo → Google Play Billing** on 2026-07-24. Decision:
**Android-only billing.** Play Billing is the only purchase path; Web keeps a
read-only plan/status view and points users to the Android app. The PayMongo
hosted-checkout path is retired.

The **entitlement engine is unchanged** — the status oracle, `effective_limits`,
`has_cloud_access`, and the versioned/grandfathered `subscriptions` model from
`20260707000001/2` are exactly as before. This migration swapped only the
*acquisition + verification* layer. Supabase remains the single source of truth
for Premium access.

---

## What was built (in the repo, config-driven, inert until activated)

| Area | Path |
|---|---|
| Schema (Play SKU map, token index, Play columns) | `supabase/migrations/20260723000001_play_billing_foundation.sql` |
| Play write path (grant/expire, mirrors Google's expiry) | `supabase/migrations/20260723000002_play_grant_fns.sql` |
| Google Play API helper (JWT auth, get, acknowledge) | `supabase/functions/_shared/google_play.ts` |
| Verify a purchase → grant (client-initiated) | `supabase/functions/verify-play-purchase/index.ts` |
| RTDN lifecycle (renew/cancel/hold/refund) | `supabase/functions/google-play-rtdn/index.ts` |
| Store driver (query/buy/restore/complete, manage deep link) | `lib/features/billing/data/iap_service.dart` |
| Purchase flow, offers, restore, error states | `lib/features/billing/presentation/cubit/billing_cubit.dart` |
| Android→Play / Web→read-only UI | `lib/features/billing/presentation/billing_page.dart` |
| Ladder vs. subscribed summary | `lib/features/billing/presentation/tabs/billing_plans_tab.dart`, `widgets/current_plan_card.dart` |

Nothing here hardcodes a Play SKU id — the ids live only in `play_product_map`,
seeded during activation (step 4).

---

## Activation — do these IN ORDER

### 1. Play Console — subscription products

Create **one subscription product per tier per period, each with a single base
plan** (keeps the client unambiguous — `in_app_purchase` does not cleanly expose
base-plan ids, so separate products avoid that entirely).

| Product ID | Base plan | Billing period | Price (PHP) |
|---|---|---|---|
| `upsenso_starter_monthly` | `monthly` | P1M | ₱199 |
| `upsenso_starter_annual`  | `annual`  | P1Y | ₱1,990 (10× monthly, 2 free) |
| `upsenso_growth_monthly`  | `monthly` | P1M | ₱499 |
| `upsenso_growth_annual`      | `annual`  | P1Y | ₱4,990 |

- Activate each product + base plan.
- Add **license testers** (Play Console → Setup → License testing) so test buys
  don't charge real money.
- Upload a **signed** build to at least the **internal testing** track — Play
  returns no product details until the app is on a track with the same
  `applicationId` (`com.ledgidy.pos`).

### 2. Google Cloud + Play Console — the billing service account

Use a **dedicated service account for billing**, separate from the one CI uses to
publish releases (`github-deploy`). The reason runs the opposite way to the
obvious one: the deploy key can push an app update to production, and its JSON
ends up stored in Supabase's edge environment. A leak there would let someone
ship a build to every user. A billing-only account can read subscription state
and nothing else.

Current setup for reference: GCP project **`ledgify-deploy`**, service account
**`upsenso-play-billing@ledgify-deploy.iam.gserviceaccount.com`**.

**2.1 — Find the linked GCP project.** Play Console → **Setup → API access**
(account level: click the Play Console logo first; inside an app the Setup menu
is hidden). It names the linked Google Cloud project. Visible only to the account
owner or an admin.

**2.2 — Enable the API.** In that GCP project: **APIs & Services → Library** →
*Google Play Android Developer API* → **Enable**. Already on if CI publishes
successfully with a service account in the same project.

**2.3 — Create the service account.** GCP → **IAM & Admin → Service Accounts →
Create service account**. Name it e.g. `upsenso-play-billing`. **Skip the "grant
this service account access to project" step** — Play permissions are granted in
Play Console, not GCP IAM, so it needs no GCP roles at all.

**2.4 — Create a JSON key.** Click the account → **Keys → Add Key → Create new
key → JSON**. It downloads once.

> Google shows a private key **only at creation** — there is no re-download. If
> the file is lost, create a new key and delete the old one. Adding a key never
> invalidates existing keys, and permissions live on the *account*, so a new key
> needs no Play Console changes.

Keep the file out of the repo.

**2.5 — Invite it in Play Console.** Account level → **Users and permissions →
Invite new users** → paste the service-account email. Creating the account in GCP
does **not** grant Play access; these are separate systems, and missing this step
is the single easiest way to get a `403` that looks like a code bug.

**2.6 — Grant exactly these permissions:**

| Grant | Why |
|---|---|
| ✅ **View financial data, orders, and cancellation survey responses** | its own description says *"access the Purchases API"* — required for `subscriptionsv2.get` |
| ✅ **Manage orders and subscriptions** | `subscriptions.acknowledge` is a write; an unacknowledged purchase is auto-refunded in 3 days **and blocks every later plan change** |
| ✅ App access to Upsenso (**App permissions** tab → view app information) | the package name is in the API path, so Play checks per-app access |
| ❌ Admin, release/production tracks, draft apps | a billing key must never be able to publish |

Then **Send invite / Save** — the invite isn't created until you do. Confirm the
service account now appears in the users list.

**2.7 — Propagation.** Usually a few minutes; Google documents up to 24h. A `403`
on the first attempt is normally just this.

### 3. GCP + Play — RTDN (Pub/Sub push)

1. Create a Pub/Sub **topic**, e.g. `play-rtdn`.
2. Grant publish rights on it to
   `google-play-developer-notifications@system.gserviceaccount.com`.
3. Play Console → Monetization setup → **Real-time developer notifications**:
   set the topic to `projects/<gcp-project>/topics/play-rtdn` and Send test.
4. Create a **push subscription** on the topic with endpoint
   `https://<project-ref>.supabase.co/functions/v1/google-play-rtdn` and attach a
   push service account so Pub/Sub signs each delivery with an OIDC token:

   ```bash
   gcloud pubsub subscriptions update <subscription> \
     --push-auth-service-account=<sa>@<gcp-project>.iam.gserviceaccount.com
   ```

   Set `PLAY_RTDN_PUSH_SA` to that same address. The function verifies the
   token's signature against Google's JWKS, plus `iss`, `exp`, and that `email`
   matches — so only your push subscription can reach it.

#### Migrating from the old `?secret=` scheme

The endpoint previously authenticated with a shared secret in the **URL query
string**, which Supabase writes to the edge logs in plaintext on every single
notification. Anyone with log-read access could forge notifications, and the
terminal types (`SUBSCRIPTION_REVOKED`, `SUBSCRIPTION_EXPIRED`, voided purchase)
revoked entitlement with no Google re-check — so a forged push could cancel any
tenant's subscription.

Cut over without dropping notifications:

1. Deploy the function with `PLAY_RTDN_PUSH_SA` set **and**
   `PLAY_RTDN_ALLOW_LEGACY=true`. Both auth paths are accepted.
2. Run the `gcloud` update above.
3. Confirm OIDC deliveries are landing (logs show no
   `rtdn: OIDC failed … trying legacy secret`).
4. Set `PLAY_RTDN_ALLOW_LEGACY=false` and delete `PLAY_RTDN_SHARED_SECRET`.

Terminal notifications now re-fetch `subscriptionsv2.get` and only expire when
Google agrees the subscription is gone (a 404 counts as agreement), so a forged
or stale revoke cannot take access away on its own.

### 4. Supabase — migrations, secrets, functions, seed

**⚠️ NEVER `supabase db push`** (it would replay the 2026-07-04 reset and wipe
prod). Apply migrations statement-by-statement with `npx supabase db query
--linked`, in this order (the `20260707*`/`20260717*` billing engine must exist
first):

```
20260723000001_play_billing_foundation.sql
20260723000002_play_grant_fns.sql
20260728000001_play_billing_hardening.sql
```

`20260728000001` adds the stale-token guard to `apply_play_subscription`, revokes
client DML on the billing tables, adds `billing_webhook_events.status` (so a
failed RTDN is retried rather than swallowed as a duplicate), and closes the
`billing_settings` read. It is additive and its rollback is in the file header.

Set the secrets.

> **Set `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` as base64, never as raw JSON.**
> This is not a style preference — it is the bug that kept Play billing broken
> from launch until 2026-07-28. The key is pretty-printed multi-line JSON whose
> **first line is just `{`**. Pasted into the dashboard's single-line secret
> field, everything after line 1 is discarded and the stored secret becomes one
> character. Shell interpolation (`"$(cat key.json)"`) is the same trap from the
> other direction — unquoted, the shell splits on whitespace and keeps only `{`.
> Base64 is a single line of `A–Z a–z 0–9 + / =`, so there is nothing for a field
> or a shell to truncate.

Produce the value (PowerShell):

```powershell
$json = Get-Content -Raw "C:\path\to\upsenso-play-billing-key.json"
($json | ConvertFrom-Json).client_email   # sanity: must be the BILLING account, not github-deploy
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json)) | Set-Clipboard
(Get-Clipboard).Length                    # expect a few thousand; a small number means it failed
```

Paste it into **Dashboard → Project Settings → Edge Functions → Secrets**
(`https://supabase.com/dashboard/project/<project-ref>/settings/functions`),
clearing any previous value first. Secrets are read per request — no redeploy
needed, though redeploying forces fresh isolates if you suspect a stale value.

`parseServiceAccount` accepts base64, raw JSON, escaped quotes, and
quote-wrapped JSON, so a correct value in any of those shapes works — but only
base64 is immune to being truncated on the way in.

The other two are single-line and safe either way:

```bash
npx supabase secrets set GOOGLE_PLAY_PACKAGE_NAME=com.ledgidy.pos
npx supabase secrets set PLAY_RTDN_PUSH_SA=<sa>@<gcp-project>.iam.gserviceaccount.com

# Only during the auth cutover in step 3 — remove both once OIDC is confirmed.
npx supabase secrets set PLAY_RTDN_ALLOW_LEGACY=true
npx supabase secrets set PLAY_RTDN_SHARED_SECRET=<long-random-string>
```

Deploy the functions (mind the JWT flags):

```bash
npx supabase functions deploy verify-play-purchase          # JWT verified (signed-in caller)
npx supabase functions deploy google-play-rtdn --no-verify-jwt   # Pub/Sub can't send a Supabase JWT
```

Seed `play_product_map` with the **real** ids from step 1 (one statement):

```sql
INSERT INTO public.play_product_map
  (product_id, base_plan_id, plan_code, plan_version, billing_period) VALUES
  ('upsenso_starter_monthly', 'monthly', 'starter', 1, 'monthly'),
  ('upsenso_starter_annual',  'annual',  'starter', 1, 'annual'),
  ('upsenso_growth_monthly',  'monthly', 'growth',  1, 'monthly'),
  ('upsenso_growth_annual',   'annual',  'growth',  1, 'annual')
ON CONFLICT (product_id, base_plan_id) DO NOTHING;
```

### 5. Retire PayMongo on prod

- `npx supabase functions delete create-checkout`
- `npx supabase functions delete paymongo-webhook`
- Unset `PAYMONGO_SECRET_KEY`, `PAYMONGO_MODE`, `PAYMONGO_WEBHOOK_SECRET`,
  `CHECKOUT_SUCCESS_URL`, `CHECKOUT_CANCEL_URL`.
- Remove the webhook endpoint in the PayMongo dashboard.

### 6. Verify the configuration — free, before spending anything

Run the config probe (see *Config health check* below — it is a curl, not an
in-app button). Every stage must be green; each failure names its own fix. Do
this first — it costs nothing, and it catches every setup fault that used to be
discoverable only by charging someone.

### 7. Test end-to-end (license tester on Android internal track)

Only once step 6 is fully green.

1. Open Billing → tier cards show live Play prices → tap Upgrade.
2. Complete the Play sheet → the app verifies → plan flips to active with no
   manual refresh. Confirm in the DB that **all three** gain a row:
   `play_purchase_tokens`, `billing_payments`, `subscriptions`
   (`provider='google_play'`, `current_period_end` = Google's expiry).
3. Confirm the verify response has **`acknowledged: true`**. An unacknowledged
   purchase is auto-refunded in 3 days *and* blocks every later plan change.
4. **Plan changes** — the regression that broke this at launch. Walk
   Starter monthly → Growth monthly → Starter annual → Growth annual →
   Starter annual. No Play dialog at any step; `plan_code` / `billing_period`
   follow each change. Cross-period switches must use `withTimeProration`;
   `chargeProratedPrice` is rejected by Play across periods.
5. **Restore is automatic** — reinstall and open the app; the plan comes back
   with no button pressed (see *Restore* below).
6. RTDN: cancel in Play → `SUBSCRIPTION_CANCELED` keeps access to expiry;
   let it expire / refund → entitlement lapses, cloud pauses, local data intact.
7. Run `tool/billing_rls_checks.sql` §7–§11 against a preview branch.

---

## Verification cross-references

- `has_cloud_access()` / `effective_sub_status` — unchanged; a Play grant is
  indistinguishable from an admin grant to the engine.
- Anti-hijack: a purchase token binds to one business (`play_purchase_tokens`);
  a second business presenting it gets 409.
- Acknowledgement is server-side in `verify-play-purchase` (stops Google's
  3-day auto-refund even if the app dies mid-flow).

---

## Restore — automatic, with no button

There is deliberately **no "Restore purchases" button**. A merchant who has paid
should not have to know the word "restore", let alone find it. Restore runs on
its own in five places:

| Trigger | Where |
|---|---|
| App start | `bootstrap.dart` → `PlayPurchaseSyncService.start()` then `restore()` |
| Opening Billing | `BillingCubit.load()`, only when Play has reported nothing owned |
| App resume | `BillingPage.didChangeAppLifecycleState` → `refresh()` → `load()` — this is what catches a change made in the Play subscriptions screen |
| Connectivity returns | `PlayPurchaseSyncService`, when retryable tokens are pending |
| Backoff retry | `PlayPurchaseSyncService`, 5s × 2ⁿ, max 5 attempts per token |

While one is in flight the Plans tab says *"Checking your Google Play
purchases…"* — silent background work on a billing page reads as a hang.

`load()` takes `restorePurchases:`, and the reload a successful grant triggers
passes `false`: that purchase is already verified, and restoring it re-emits it,
which grants again, which reloads — one edge-function invoke per lap.

Two manual paths remain for a merchant who is genuinely stuck:
**pull-to-refresh** on the Plans tab, and **Try again** in the
charged-but-not-granted dialog (`retryStuckPurchase()` → `reverifyActive()`,
falling back to `restore()`).

---

## Config health check (start here)

Before reading logs — and **before charging anyone to find out something is
broken** — run the probe.

This is a **support tool, not a merchant one**, so it has no UI. It reports on
*our* server configuration: a shop owner can neither read nor act on a failing
row, and a red row there reads to them as "the app is broken". Call it directly:

```bash
curl -sS -X POST "$SUPABASE_URL/functions/v1/verify-play-purchase" \
  -H "Authorization: Bearer $USER_ACCESS_TOKEN" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"probe": true}' | jq .
```

It calls `verify-play-purchase` with `{"probe": true}` — same auth as a real
verify (signed-in user with `billing.manage`), no purchase token, no secrets in
the response — and reports each stage:

| Check | Fails when |
|---|---|
| Server configuration | a secret is missing; reports the key's **length** (a real base64 key is thousands of chars — a length of 1 means the dashboard field truncated a multi-line paste) |
| Service account key | the secret isn't valid JSON/base64; reports `client_email` on success, which catches the *wrong* service account being wired up |
| Google sign-in | the key is revoked or disabled |
| Play Store access | the SA was never invited in Play Console (401/403), or `GOOGLE_PLAY_PACKAGE_NAME` is wrong (404) |
| Plan products | `play_product_map` and Play disagree — reports mismatches in both directions |

Checks run in order and stop at the first failure, since each depends on the one
before.

> Set `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` as **base64**, not raw JSON. The
> dashboard's secret field is single-line, and a pretty-printed key's first line
> is just `{` — pasting it raw silently stores one character. Base64 is one line
> with nothing for a field or shell to truncate:
> `[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((Get-Content -Raw key.json)))`

---

## Troubleshooting a failed verify

`verify-play-purchase` tags every failure with the stage that produced it, and
returns `{error, code, stage, detail}`. Find it with:

```
get_logs(service: "edge-function")      # or: npx supabase functions logs verify-play-purchase
# → verify-play-purchase [<stage>/<code>] <detail>
```

`code` drives the client's behaviour, so it matters more than the message:

| code | Meaning | Client behaviour |
|---|---|---|
| `play_config` | **We** are misconfigured — retrying can never succeed | Stops, shows a blocking dialog, leaves the purchase unacknowledged so Google refunds |
| `play_transient` | Network/5xx/DB blip | Exponential backoff, up to 5 attempts |
| `play_superseded` | The token is the old subscription of a completed plan change | Silent. No snackbar, no dialog — nothing is wrong |

| stage | Almost certainly |
|---|---|
| `secrets` | `GOOGLE_PLAY_PACKAGE_NAME` / `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` not set |
| `parse_sa` | Service-account JSON malformed, or `private_key` newlines escaped as literal `\n` (normalised automatically, but a truncated key still fails here) |
| `google_token` | SA key revoked or disabled |
| `google_get_sub` 401/403 | SA lacks Play Console access, **or the Google Play Android Developer API is not enabled** on the linked GCP project |
| `google_get_sub` 404 | `GOOGLE_PLAY_PACKAGE_NAME` ≠ `com.ledgidy.pos` |
| `google_ack` | Granted but NOT acknowledged — Google auto-refunds in 3 days **and Play blocks every plan change until it clears**. Never ignore this line. |
| `grant` | `apply_play_subscription` failed (check `service_role` GRANT) |

### Why a plan change gets "We are unable to change your subscription plan"

Play rejects the whole `SubscriptionUpdateParams`, not the tier. In order of
likelihood:

1. **A previous purchase is still unacknowledged** — usually a downstream effect
   of a failing verify. Fix the verify first; the dialog goes with it.
2. **Wrong replacement mode.** `chargeProratedPrice` is only valid for an upgrade
   that keeps the same billing period, so it fails on monthly↔annual. The client
   sends `withTimeProration` for immediate switches and `deferred` only for a
   same-period downgrade — do not reintroduce `chargeProratedPrice`.
3. **A stale `oldPurchaseDetails`.** Passing a canceled/expired/foreign-account
   token is rejected; the client drops its cached purchase on cancel, error, a
   409 verify, and sign-out.
4. **Wrong `offerToken`.** Play returns one `ProductDetails` per base plan *and
   per discounted offer*, all sharing the product id, so the offer must be
   selected by `basePlanId` (preferring the entry with no `offerId`) rather than
   by product id alone.
5. **`oldPurchaseDetails` was still null.** The restore that populates it runs
   when the Billing page opens; `buyPlan` waits up to 3 s for it before reading.
   Without that wait an early tap bought a *second* subscription instead of
   replacing the first.

### Why an upgrade succeeded but showed "we couldn't confirm your purchase"

Fixed 2026-07-28. Worth understanding, because the shape recurs.

After a plan change Play keeps returning the **replaced** subscription for a
while. The client verified it, Google reported `SUBSCRIPTION_STATE_EXPIRED`, the
server answered a bare 409, and the client — which treats every 4xx as
charged-but-not-granted — raised the blocking dialog. Meanwhile the new plan had
already been granted, so the page showed Growth *and* an error.

Three things now prevent it:

- The server distinguishes a **superseded** token (`code: "play_superseded"`)
  from a genuinely dead one, using two ordering-independent signals:
  `play_purchase_tokens.is_current = false`, or the business already living on a
  different token whose paid period hasn't run out.
- `linked_token` / `is_current` are finally written. A successful verify retires
  the subscription it replaced, which also feeds the stale-token guard in
  `apply_play_subscription` — without it a late RTDN for the old token silently
  downgraded the tenant back to the previous plan.
- The client memoises granted tokens, so `granted → reload → restore → verify →
  granted` no longer loops. `load()` only restores when it holds no purchase,
  and the grant-driven reload now passes `restorePurchases: false` outright
  rather than relying on that guard alone.
