# UPSENSO — Launch Readiness Checklist

Last reviewed: 2026-06-21. Use this before officially going to Pro / opening to real users.

Legend: ✅ done · ⬜ your action · 🔒 dashboard/billing only (Claude can't do) · ⚙️ Claude can do on request

---

## 0. Already verified (no action needed)
- ✅ **DB normalization complete** — 7 migrations applied, `flutter analyze` clean, 41 tests pass, merged to `main`.
- ✅ **DB ⇄ app build in lock-step** — the migrated columns require the `main` build; do NOT ship an older build.
- ✅ **Tenant isolation** — RLS on every table (only `role_permissions` is intentionally policy-less, read via functions).
- ✅ **Privileged RPCs guarded** — `create_employee_auth_account`, `apply_business_template`, `set_module_enabled`, `set_employee_permission_override` all enforce cross-tenant authorization.
- ✅ **No client secrets** — config is env-injected (`--dart-define-from-file`), anon key only, no `service_role` in `lib/`, flavor files gitignored.

---

## 1. Decide production home (do this FIRST — it gates the purge)
- ⬜ Choose: **(A)** promote the current project (`dmhyfezuravbjpoxjesb` / Upsenso) to prod, or **(B)** stand up a fresh prod project.
  - **(A) Promote current** — fastest. The verified schema already lives here. Requires purging the 21 test businesses (script ready, see §3).
  - **(B) Fresh project** — cleaner separation. ⚠️ The migration files do NOT recreate the base tables, so a fresh project needs a **full `supabase db dump` of the current project** as its baseline — not just the 7 migration files.
- ⬜ Whichever you pick, **the other project becomes dev/staging** so you never test migrations against prod again.

## 2. Backups & plan (🔒 dashboard / billing — only you)
- 🔒 Upgrade plan off Free.
- 🔒 Enable **PITR / daily backups** on the production project.
- 🔒 **Run one test restore** to confirm backups actually work. (A POS that loses sales data is existential — do not skip.)
- 🔒 Enable **leaked-password protection** (Auth settings; Pro-gated).

## 3. Production data prep (⚙️ Claude can run, with your go-ahead)
- ⬜ **Enable backups (§2) BEFORE running any destructive purge.**
- ⚙️ Run `supabase/scripts/purge_test_data.sql` — deletes all tenant data, KEEPS seed/reference tables (`modules`, `permissions`, `business_templates*`). Only for path (A).
- ⬜ (Optional) Clean orphaned **test `auth.users`** accounts (auth schema — handle via dashboard or a separate script).
- ⬜ Confirm seed data is present post-purge: `modules`, `permissions`, `business_templates`.

## 4. Build & release (⬜ you; ⚙️ Claude can help with config)
- ⬜ Confirm `flavors/prod.json` points at the **production** project URL + anon key (not dev).
- ⬜ Cut the release build from `main` with `--dart-define-from-file=flavors/prod.json` and `FLAVOR=prod`.
- ⬜ Verify the built app connects to prod and a smoke sale → sync round-trips cleanly.
- ⬜ Configure OAuth redirect URLs (`SUPABASE_OAUTH_REDIRECT_URL`) for prod in the Supabase Auth settings (🔒).

## 5. Observability (⚙️ Claude can wire on request — needs your Sentry/Crashlytics DSN)
- ⬜ Provide a Sentry (or Crashlytics) DSN.
- ⚙️ Wire it so production **sync/transaction failures surface** (today they only `debugPrint` into the void — you'd be blind to failed sales syncs at launch).

## 6. Pre-launch security pass (mostly ✅; a couple ⬜)
- ✅ RLS + RPC tenant-isolation audit done.
- ⬜ Run `/security-review` on the final release diff (your command).
- ⬜ Consider a lightweight external auth/RLS review before real money flows (recommended for a financial POS).
- ⚙️ (Optional hardening) Tighten `create_employee_auth_account` to also require an employee-management permission within the business — today any business member can create employee logins in their own tenant (within-tenant only, not a cross-tenant leak).

## 7. Fast-follow (days after launch, not blockers)
- ⬜ Account-delete / data-retention path (GDPR-lite) if you'll have EU/real users — schema currently only soft-deletes; no hard-delete/anonymize path exists.
- ⚙️ Separate dev/staging project (one-time dump of prod) so migrations are tested off-prod.
- ⬜ Re-run Supabase performance advisors once real data accumulates (FK indexes, RLS initplan) — premature at current volume.

---

## What needs YOU vs what Claude can do
- **Only you (dashboard/billing/deploy):** create project, enable PITR/plan, leaked-password, OAuth redirects, deploy keys, cut & submit the release build, test restore.
- **Claude can do on request:** run the purge script, wire observability (with your DSN), tighten the employee-creation RPC, produce a schema dump via SQL for path (B), re-audit secrets/RLS.
