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
| Store driver (query/buy/restore/complete) | `lib/features/billing/data/iap_service.dart` |
| Purchase flow, offers, restore, error states | `lib/features/billing/presentation/cubit/billing_cubit.dart` |
| Android→Play / Web→read-only UI | `lib/features/billing/presentation/billing_page.dart` |

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
| `upsenso_growth_annual`   | `annual`  | P1Y | ₱4,990 |

- Activate each product + base plan.
- Add **license testers** (Play Console → Setup → License testing) so test buys
  don't charge real money.
- Upload a **signed** build to at least the **internal testing** track — Play
  returns no product details until the app is on a track with the same
  `applicationId` (`com.ledgidy.pos`).

### 2. GCP — service account + API

1. In the Google Cloud project linked to Play, **enable** the *Google Play
   Android Developer API*.
2. Create a **service account**; download its **JSON key**.
3. In Play Console → Users & permissions, invite the service-account email and
   grant **View financial data** + **Manage orders and subscriptions** for the
   app. (Account-level API access can take a few hours to propagate.)

### 3. GCP + Play — RTDN (Pub/Sub push)

1. Create a Pub/Sub **topic**, e.g. `play-rtdn`.
2. Grant publish rights on it to
   `google-play-developer-notifications@system.gserviceaccount.com`.
3. Play Console → Monetization setup → **Real-time developer notifications**:
   set the topic to `projects/<gcp-project>/topics/play-rtdn` and Send test.
4. Create a **push subscription** on the topic with endpoint:
   `https://<project-ref>.supabase.co/functions/v1/google-play-rtdn?secret=<PLAY_RTDN_SHARED_SECRET>`
   (The function checks `?secret=` constant-time; the value is set in step 5.)

### 4. Supabase — migrations, secrets, functions, seed

**⚠️ NEVER `supabase db push`** (it would replay the 2026-07-04 reset and wipe
prod). Apply migrations statement-by-statement with `npx supabase db query
--linked`, in this order (the `20260707*`/`20260717*` billing engine must exist
first):

```
20260723000001_play_billing_foundation.sql
20260723000002_play_grant_fns.sql
```

Set the secrets:

```bash
npx supabase secrets set GOOGLE_PLAY_PACKAGE_NAME=com.ledgidy.pos
npx supabase secrets set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="$(cat sa-key.json)"
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

### 6. Test end-to-end (license tester on Android internal track)

1. Open Billing → tier cards show live Play prices → tap Upgrade.
2. Complete the Play sheet → cubit verifies → plan flips to active; `subscriptions`
   shows `provider='google_play'` with `current_period_end` = Google's expiry.
3. **Restore purchases** on a reinstall re-verifies and re-grants.
4. RTDN: cancel in Play → `SUBSCRIPTION_CANCELED` keeps access to expiry;
   let it expire / refund → entitlement lapses, cloud pauses, local data intact.
5. Run `tool/billing_rls_checks.sql` §7–§11 against a preview branch.

---

## Verification cross-references

- `has_cloud_access()` / `effective_sub_status` — unchanged; a Play grant is
  indistinguishable from an admin grant to the engine.
- Anti-hijack: a purchase token binds to one business (`play_purchase_tokens`);
  a second business presenting it gets 409.
- Acknowledgement is server-side in `verify-play-purchase` (stops Google's
  3-day auto-refund even if the app dies mid-flow).
