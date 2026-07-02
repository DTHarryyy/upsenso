# UPSENSO — Execution Sequence (what to do next, in order)

> Status: **active build sequence** · Branch: `claude/platform-features-roadmap-7bqdgn`
> This is the **ordered task list** from the current codebase to the product
> vision. The *what & why* live in `UPSENSO_PRODUCT_ROADMAP.md`; the *how* for the
> hard parts live in `UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md` and
> `UPSENSO_SUBSCRIPTION_AND_LIMITS_DESIGN.md`. **This doc says what to do first.**

## Priority override (current decision)

The product owner chose to **lead with visible value** rather than the trust
spine. So the near-term order is **M2 (proactive AI insights) → M5 (CRM
foundation)**, with **M1 (fraud + audit chain) deferred to the milestone right
after** (its full spec stays valid, just rescheduled). The phase numbering below
is unchanged for reference; the *active* work order is:

1. **Step 0 — Foundations** (below)
2. **Phase 3 — M2 Proactive AI Insights**  ⬅️ *in progress*
3. **M5 — CRM foundation** (customers + purchase history; loyalty stretch)
4. **Phase 1 + 2 — M1 audit chain + fraud engine** (deferred, next milestone)

Rationale: the AI assistant already exists, so making it *proactive* is the
highest-leverage, most demoable win; CRM fills the biggest functional gap
(customers are only a text field today). See the chat decision for full reasoning.

## How to use this

- Work **top to bottom** *within the active order above*. Each step is gated on
  the one before it.
- Finish a step *completely* (code → codegen → migration → RLS → tests → device
  QA) before starting the next. Vertical slices, not many half-built features.
- `[ ]` = todo · `[~]` = in progress · `[x]` = done. Update as you go so any
  session (yours or a fresh Claude one — no memory between sessions) resumes here.
- **Every step ends with a CHECKPOINT** — don't proceed until it's green.

---

## Step 0 — Foundations (do once, ~0.5 day)

- [ ] `flutter pub get`; confirm `flavors/dev.json` exists with Supabase keys.
- [ ] Baseline green: `flutter analyze` and `flutter test` both pass on this
      branch *before* changing anything.
- [ ] Add `crypto` to `pubspec.yaml` (needed for the audit hash; first-party,
      web-safe) and re-run `flutter pub get`.
- [ ] Confirm Supabase project access and that `supabase/migrations/` is the
      source of truth (95 migrations today).

**CHECKPOINT:** clean `flutter analyze` + `flutter test`, app runs.

---

## Phase 1 — M1.1 Tamper-Evident Audit Chain  *(~1 week)*

Spec: `UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md` Part 1. Self-contained, ships alone.

1. [ ] **Canonical serializer** — `lib/core/audit/audit_hash.dart`:
       `canonicalAuditPayload(...)` (sorted keys, UTC ISO-8601 ms, no sync
       fields) + `sha256` helper. *Pure, unit-testable first.*
   - [ ] Tests: stable output, metadata key-order independence, UTC formatting.
2. [ ] **Drift schema** — add `seq`, `prevHash`, `entryHash` (nullable) to
       `audit_logs_table.dart`; bump `schemaVersion` 51→52 in `app_database.dart`
       + `onUpgrade` (3× `ADD COLUMN`).
3. [ ] **Codegen** — `dart run build_runner build --delete-conflicting-outputs`.
4. [ ] **Supabase migration** — `<ts>_audit_chain_columns.sql` (additive, with
       rollback comment). Apply (ask before running the CLI/MCP write).
5. [ ] **Write path** — update `AuditLogService.log()` to allocate `seq` +
       compute the chain hash inside one Drift transaction (per-business/device).
   - [ ] Tests: seq increments per (business, device); genesis; concurrent writes.
6. [ ] **Verifier** — `lib/core/audit/audit_chain_verifier.dart` (re-walk +
       detect breaks).
   - [ ] Tests: clean chain passes; one mutated row → one break at right seq.
7. [ ] **UI hook** — "Verify integrity" action on the Audit Logs page, gated by
       `audit_logs.verify` (add the permission key + matrices first).

**CHECKPOINT:** new audit rows carry a valid chain; tampering with a row is
detected by the verifier; `flutter test` + `dart run tool/diff_matrices.dart` green.

---

## Phase 2 — M1.2 Fraud Detection Engine  *(~1.5 weeks)*

Spec: `UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md` Part 2. Replaces the mock `alert`.

8.  [ ] **Permissions wiring (do first, per CLAUDE.md order):** add `fraud.view`,
        `fraud.resolve`, `nav.fraud`, `audit_logs.verify` to `permission_keys.dart`
        → `AppPermission` values → `AppFeature.fraudAlerts` (module `audit`) →
        `role_permission_matrix.dart` + `default_permission_matrix.dart`.
    - [ ] `dart run tool/diff_matrices.dart` must report in-sync.
9.  [ ] **Drift table** — `fraud_flags_table.dart` + `fraud_flags_dao.dart`
        (+ unique index on `business_id, dedupe_key`); bump schemaVersion + upgrade;
        `build_runner`.
10. [ ] **Supabase migration** — `<ts>_fraud_flags.sql` mirror + RLS
        (`fraud.view` SELECT, `fraud.resolve` UPDATE, INSERT tenant-scoped, no
        DELETE). Rollback section. Apply (ask first).
11. [ ] **Rule framework** — `FraudRule` interface + `FraudScanContext` +
        `fraud_settings` thresholds.
12. [ ] **First 5 rules:** `EXCESSIVE_REFUNDS`, `HIGH_DISCOUNT`,
        `SALE_AFTER_SHIFT`, `INVENTORY_SHRINKAGE`, `AUDIT_TAMPER` (wires Phase 1
        verifier).
    - [ ] Tests per rule: positive, negative, boundary, dedupe.
13. [ ] **Engine** — `fraud_detection_engine.dart`: `runSweep()` + dedupe +
        notification; register in `di.dart`.
14. [ ] **Triggers** — post-commit hooks in `CheckoutService` / `RefundService` /
        `StockMovementService` (incremental) + foreground/periodic full sweep.
15. [ ] **UI swap** — replace `mockFraudAlerts` with a real `FraudCubit` →
        `FraudFlagsDao` stream in the existing `alert` feature; add resolve/dismiss
        (gated by `fraud.resolve`, writes an audit log).

**CHECKPOINT:** real refund/discount/shift/shrinkage abuse raises real flags; a
broken audit chain raises a CRITICAL flag; manager can triage; cashier denied;
all tests green.

> **M1 is now shippable.** This is the realistic 1-month (Max 5×) target. Stop
> here and release if time-boxed; continue if you have runway.

---

## Phase 3 — M2 Proactive AI Insights  *(~2 weeks)*

Spec: `UPSENSO_PRODUCT_ROADMAP.md` M2. Reuses the existing AI pipeline.

16. [~] **Analytics tool methods** in `ai_tool_service.dart` (branch-filtered,
        permission-aware like existing queries):
    - [x] `getSalesTrend` (+ `previousPeriod` helper, `SalesTrendResult`) and
          `getApprovedExpenseTotal` — with pure-logic unit tests for the
          period math. **Verified green locally 2026-06-30.**
    - [x] `getTopProducts` (thin ranking wrapper over `getSalesByProduct`) and
          `getLowStockCount` (reuses `ProductVariantsDao.getLowStockByBusinessId`
          so it matches the dashboard low-stock card). Added 2026-06-30; analyze
          clean. SQL methods exercised in device QA per this file's convention.
    - [x] `getMarginMovers` (+ `MarginMoverResult` with pure-tested `margin` /
          `marginPercent`). **Decision (2026-06-30): current-cost approximation** —
          uses `product_variants.cost_price` (cost-at-sale isn't stored);
          null-cost variants excluded. Added 2026-06-30; analyze clean, 13 tests
          pass. Revisit once M4 lands real COGS / cost-at-sale.
    - [ ] `getFraudSummary` — **blocked:** reads Phase 2 / M1 (fraud engine),
          which is deferred under the current priority order. Defer with it.
17. [x] **Insights generator** — `lib/features/insights/`: pure
        `InsightsGenerator.generate(InsightsMetrics)` → ordered `List<Insight>`
        (deterministic template phrasing, works on web), fed by
        `InsightsRepository` (gathers via Task-16 `AiToolService` methods,
        permission-gated). Added 2026-06-30; 13 generator tests pass.
        **Note:** the LLM-rephrasing layer is deferred — template phrasing is
        the shipping implementation (robust + offline/web-safe); an optional LLM
        polish pass can wrap the generator later without changing the numbers.
18. [x] **Permissions** — `insights.view` wired end to end: `PermissionKeys`
        → `AppPermission.viewInsights` → both matrices (Owner auto, Branch
        Manager granted; Cashier/Inventory denied) → reports-module gate added to
        `PermissionService._moduleCodeForKey`. Matrix sync verified IN SYNC.
        (No new table/write → no new RLS; the underlying read queries already run
        under existing RLS on transactions/expenses/product_variants.)
19. [x] **Dashboard card** — `InsightsCubit` + reusable `InsightCard`
        (`DashboardCard` shell, `AppColors`, `Theme` text — no hardcoded styles).
        Self-hides when the role lacks `insights.view` or there's nothing to
        report, so it sits unconditionally on the dashboard. Replaced the old
        mock `ai_insights_card.dart` (deleted). Repo registered in `di.dart`.

**CHECKPOINT:** ✅ owner opens the app and sees a plain-language daily "what
changed + what needs attention" card, generated on-device, permission-scoped.
Code-verified (analyze clean, 83 tests pass); **on-device visual QA still owed**
(run the app on Owner + Branch Manager + Cashier to confirm show/hide + phrasing).

---

## Phase 4+ — remaining milestones (sequence, lower detail)

Detail these into their own task lists when you reach them. Order is dependency-
driven (see the roadmap's dependency graph).

20. [ ] **M3.1 Stock transfers** — `stock_transfers` + items tables (both sides),
        send/receive legs write `stock_ledger`, reconciliation → `transferMismatch`
        fraud rule.
21. [ ] **M3.2/3.3** Reorder points + lightweight forecasting → feeds insights.
22. [ ] **M4 Procurement intelligence** — auto-PO suggestions, supplier perf,
        landed cost/COGS (COGS also powers `NEGATIVE_MARGIN_SALE`).
23. [ ] **M5 Customers/CRM + loyalty** — new `customers` module, link to
        transactions/refunds, loyalty ledger.
24. [ ] **M6 Money** — reports overhaul, tax engine, accounting export, budgets.
25. [ ] **M-BIR — BIR compliance & invoice (CRITICAL, pre-commercial-launch)** —
        full spec in `UPSENSO_BIR_COMPLIANCE.md`. The legal gate before selling
        to any registered PH business. Highlights: rename the document to
        **INVOICE** (EOPT), all mandatory invoice fields + VAT breakdown +
        SC/PWD discounts, **per-device gapless sequential numbering** (offline-
        safe via `pos_devices` series), Accumulated Grand Total, X/Z readings,
        tamper-proof (reuses M1 audit chain), then eAccReg enrollment + TWG demo.
        Build the `pos_devices` model **together with** M7.1's device cap. Note:
        once accredited, major invoice-logic changes require **re-accreditation**.
26. [ ] **M7.1 Subscription & limits** — spec in
        `UPSENSO_SUBSCRIPTION_AND_LIMITS_DESIGN.md` (PHP pricing, entitlement
        layer, offline distributed-limit reconciliation). Needs a payment gateway
        (GCash/Maya/card) — its own sub-project.
27. [ ] **M7.2–7.4** multi-currency, hardware/integrations, push notifications.
28. [ ] **M8** (continuous) — delta-sync at scale + conflict UI, security/RLS
        audit, CI test gates, performance, web parity.

---

## 🚦 Pre-ship launch gate (do LAST, before any public/commercial release)

These are not features — they're the legal/trust requirements that must be in
place **before real users touch the app**. App stores also require them.

29. [ ] **M-LEGAL — Terms, Privacy & Data Privacy Act** (do last, before ship):
    - [ ] **Privacy Policy** (required by Google Play / App Store; explains what
          data is collected, why, retention, user rights).
    - [ ] **Terms of Service** — including the **provisional-invoice notice** from
          `UPSENSO_BIR_COMPLIANCE.md` §9.4 (UPSENSO docs are not BIR-official in
          provisional mode; businesses remain responsible for official receipts).
    - [ ] **Data Privacy Act (RA 10173)** compliance — you process personal data
          (employees, customers): lawful basis, consent where needed, security
          measures, breach-response plan; register with the **NPC** if/when you
          meet the thresholds (sensitive data / scale).
    - [ ] In-app **first-run consent / acceptance** of Terms + Privacy.
    - [ ] Confirm **business + BIR registration** is done *if* taking real
          payments at launch (see `UPSENSO_BIR_ACTION_PLAN`); free beta with the
          §9 non-official disclaimer needs no registration.

> This gate is independent of feature milestones — even a free beta with real
> users needs Privacy + Terms. Keep it as the final checklist before flipping the
> app public.

---

## Definition of done — applies to EVERY step above

From `CLAUDE.md` — a step isn't `[x]` until all hold:

1. PermissionKeys → AppPermission → AppFeature → role matrix → default matrix
   (`dart run tool/diff_matrices.dart` in-sync).
2. Module gate set; permission checks in Bloc/UseCase **and** GoRouter guard.
3. Server-side RLS enforces every write (UI hiding ≠ security).
4. Offline-first: local write → background sync; `sync_status` lifecycle; LWW;
   soft deletes.
5. Drift schemaVersion bumped + `onUpgrade` + Supabase migration with rollback
   (additive, non-destructive).
6. Every `catch (e, st)` logs with stack trace + graceful UI.
7. Reuses `lib/core/widgets/`; no hardcoded colors/styles/spacing.
8. Tests for critical paths; `flutter analyze` + `flutter test` green.
9. AI-queryable where relevant (branch-filtered, permission-scoped).

## 📌 Current position / session handoff

> Live status so any session (or a fresh Claude one — no memory between sessions)
> resumes exactly here. **Last updated: 2026-07-02 (M5 code-complete + migrated +
> QA gaps closed; manual QA still owed).**

### Active priority order
**M2 (AI insights) → M5 (CRM) → M1 (fraud+audit, deferred) → M-BIR → M-LEGAL → ship.**
(See the "Priority override" section near the top for the rationale.)

### Done
- ✅ All planning/spec docs (on `main`).
- ✅ **M2 Task 16 analytics methods** — `getSalesTrend`, `getApprovedExpenseTotal`,
  `getTopProducts`, `getLowStockCount`, `getMarginMovers` in
  `lib/features/ai_assistant/services/ai_tool_service.dart`. Tests pass.
  Committed on `main`. Only `getFraudSummary` remains (deferred with M1).
- ✅ **M2 Tasks 17 + 18 + 19 — Proactive AI Insights. COMMITTED to `main`.**
  - **17 (generator):** `lib/features/insights/` — pure `InsightsGenerator`
    + `InsightsMetrics` + `Insight` entity; `InsightsRepository` gathers via
    `AiToolService`, permission-gated at the repository layer.
  - **18 (permission):** `insights.view` fully wired — `PermissionKeys` →
    `AppPermission.viewInsights` → both matrices (branchManager + above = true,
    cashier/inventory = false). `_adminMatrix` picks it up via `PermissionKeys.all`.
  - **19 (card):** `InsightsCubit` + `InsightCard` on the dashboard (self-hiding
    when denied or empty); old mock `ai_insights_card.dart` deleted; repo in DI.
  - **Bug fix (same commit):** `PermissionService.loadEnabledModules` now always
    sets `_moduleStates` (even to `{}` when no rows), so the "absent = enabled"
    path runs instead of the null-guard fail-closed path that was blocking the
    `reports` module (and therefore `insights.view`) for businesses with no
    `business_modules` rows.
  - **Gates:** `flutter analyze` clean, `flutter test` 83 pass, visual QA done.

### M5 — CRM foundation — CODE COMPLETE + MIGRATED + GAPS CLOSED, manual QA owed
Full customers module built end-to-end, mirroring the procurement/suppliers
pattern. Reuses the **existing `crm` module** (already seeded + enabled in the
Supabase `modules` catalogue — no new module invented).
- **Permissions:** `crm.view` / `crm.manage` / `nav.customers` wired through
  `PermissionKeys` → `AppPermission` (viewCustomers/manageCustomers) →
  `AppFeature.customerDirectory` (module `crm`) → both matrices (Owner all;
  Branch Manager view+manage+nav; **Cashier `crm.view` only** so they can attach
  an *existing* customer at the till but not quick-add; Inventory none) +
  `_moduleCodeForKey` `crm` case.
- **Drift (schemaVersion 51→52):** new `customers` table + `customers_dao`
  (mirrors suppliers), nullable `transactions.customer_id` FK, onUpgrade
  (createTable + addColumn + 2 indexes). `build_runner` run.
- **Supabase migration WRITTEN + APPLIED (2026-07-02, user ran it directly in the
  SQL Editor on the live prod project `dmhyfezuravbjpoxjesb`):**
  `supabase/migrations/20260702000001_crm_customers.sql` (customers table + RLS
  [tenant SELECT, `crm.manage`-gated INSERT/UPDATE, no DELETE] + transactions
  `customer_id`). **Confirmed working** — prior `[SYNC] Customer ... FAILED:
  PGRST205 (Could not find the table 'public.customers')` errors are gone and
  customer push/pull sync succeeds.
- **Feature `lib/features/crm/`:** entity + `CustomerStats`/`CustomerPurchase`,
  `ICustomerRepository` + `CustomerRepository` (local-first, audit-logged via new
  `customerCreated/Updated/Archived` audit types), `CustomerRemoteDs`,
  `CustomerCubit`/state + `CustomerDetailCubit`, customers list/detail pages,
  form sheet, `CustomerCard`, and the checkout **`CustomerInlinePicker`** — an
  inline typeahead (no bottom sheet): type in the field and matching customers
  appear instantly below it. Three paths from one field: (1) tap a match →
  **link** the saved customer (customer_id + name, builds history), (2) just
  leave the typed text → **name only** (customer_name, no record — everyone incl.
  cashiers), (3) **Save "X" as a customer** inline row (`crm.manage`-gated, opens
  a tiny name+phone quick-add prefilled from the query). `CustomerSelection`
  (`customer_selection.dart`) carries record / nameOnly / walkIn and is emitted
  via `onChanged`; a linked selection shows a "purchase history will be tracked"
  confirmation.
- **POS:** checkout free-text field replaced by the inline picker in **both**
  checkout screens — the **live** `products/checkout/product_checkout_page.dart`
  (used by the POS terminal, held sales, product cart) **and** the legacy/unused
  `pos/.../checkout_payment_page.dart`. Widget:
  `crm/.../widgets/customer_inline_picker.dart`. A saved-customer sale stores
  `customer_id` + `customer_name`; a name-only sale stores just `customer_name`.
  Purchase history = completed sales where `customer_id = X` (new
  `TransactionsDao.watchByCustomerId`).
- **Wiring:** DI (`CustomersDao`/`CustomerRemoteDs`/`ICustomerRepository` + into
  `SyncService`), `SyncService._syncCustomers` push + pull + clearAll + pending
  counts, routes (`/more/customers` [+detail]) with permission+module route
  guards, router Branch 12, sidebar + mobile More nav (gated by
  `nav.customers` + `crm` module).
- **Gates:** `flutter analyze` clean; **full `flutter test` green.**

### Post-commit QA prep (2026-07-02) — two real gaps found and closed
Preparing on-device QA surfaced two things that would have made the QA checklist
undoable / the permission model dishonest. Both fixed, tested, and verified before
any manual QA ran:
1. **`crm` module was missing from Module Management** — an Owner had no way to
   toggle Customers off/on (`isModuleEnabled` treats an absent module as enabled,
   so it silently worked, but the toggle UI itself didn't exist). Added a `crm`
   `_ModuleInfo` entry to `_kModules` in
   `lib/features/settings/presentation/module_settings_page.dart`.
2. **`crm.view` was a dead permission** — nothing enforced it; the checkout
   customer search was open to every role regardless of the matrix. Gated the
   existing-customer suggestions (search results + "no match" hint +
   "save as customer" row) in `CustomerInlinePicker` behind `can(PermissionKeys.crmView)`
   — the name-only typing path stays open to everyone. Since `can()` already
   resolves `crm.view` through the `crm` module gate, disabling the module also
   hides checkout suggestions for free.
- **New tests** (both green, `flutter analyze` clean):
  - `test/core/permissions/crm_permissions_test.dart` — locks
    `crm.view`/`crm.manage`/`nav.customers` per role against both
    `DefaultPermissionMatrix` (offline) and `RolePermissionMatrix` (online), and
    asserts the two stay in sync.
  - `test/features/crm/customer_inline_picker_test.dart` — widget-level: `crm.view
    =false` shows zero suggestions (name-only still emits); `crm.view=true,
    crm.manage=false` (cashier) shows matches but no save row, tap-to-link works;
    `crm.manage=true` shows the save row.
- **Full suite: 109 tests, all green** (was 94; +12 permission-matrix +
  3 widget-gating tests).

3. **[SEVERE] `crm.view`/`crm.manage`/`nav.customers` were never seeded server-side**
   — user's own question ("did you consider employee accounts have default
   permissions that can be overridden?") caught this. `20260702000001_crm_
   customers.sql`'s RLS policies call `has_permission('crm.manage')`, but no
   migration ever inserted `crm.view`/`crm.manage`/`nav.customers` into
   Supabase's `permissions` catalogue (confirmed: only `20260609000001`,
   `20260611000001`, and `20260627000007` ever `INSERT INTO permissions`, none
   mention `crm`). Consequence: `has_permission('crm.manage')`'s `role_allow`
   branch can never resolve a `permission_id` for a code that doesn't exist, so
   it always falls through to `false` for every non-owner — **only the literal
   `businesses.owner_id` account can write to `customers` online right now.** A
   Branch Manager's create/edit passes every client-side check (both
   `RolePermissionMatrix` and `DefaultPermissionMatrix` say they're allowed),
   writes succeed locally (offline-first), then **silently fail to sync** with
   an RLS-denied Postgrest error. Per-employee overrides for crm.* would also be
   unsettable (`set_employee_permission_override` resolves the same
   nonexistent `permission_id`).
   - **Client fix (done):** added a "Customers" `_PermGroup` (`crm.view` /
     `crm.manage`) to `_kGroups` in
     `lib/features/employees/presentation/pages/employee_permissions_page.dart`
     — previously CRM had no entry at all, so no admin could set a per-employee
     override for it even through the UI. Mirrors the existing Suppliers group;
     no `nav.customers` entry (nav keys are never listed — they resolve via the
     access key, matching the established convention).
   - **Server fix WRITTEN, NOT APPLIED:**
     `supabase/migrations/20260703000001_seed_crm_permissions.sql` — seeds the 3
     codes into `permissions`, wires `role_permissions` (Business Owner +
     Branch Manager full; Cashier `crm.view` only; Inventory Staff none, matching
     the client matrices), wires `business_template_role_permissions` so new
     businesses inherit it, and recomputes `effective_permissions` for existing
     employees. Modeled directly on the two prior instances of this exact class
     of bug: `20260627000007_seed_recipe_ingredient_permissions.sql` and
     `20260615000001_wire_procurement_role_permissions.sql`. **Needs explicit
     go-ahead before applying** (same as the customers-table migration).
- **These fixes are UNCOMMITTED** on top of `971e8ae` — see Repo/branch state.

### Next action
- ✅ **Supabase migration applied** 2026-07-02 — `public.customers` exists on
  prod, RLS active, customer sync push/pull confirmed working end-to-end.
- ✅ **Client-side permission/module gaps (#1, #2) fixed + test-locked** 2026-07-02.
- ✅ **Client-side employee-permission-editor gap (#3) fixed** 2026-07-02 —
  Customers group added.
- ⬜ **Apply `20260703000001_seed_crm_permissions.sql`** (ask first — same rule as
  every Supabase write). Until applied, non-owner writes to `customers`
  (create/edit/archive by anyone but the literal business owner) will fail to
  sync — silently, since local-first writes still succeed offline.
- ⬜ **On-device manual QA — NOT YET RUN.** Full checklist in the session's plan
  file (`C:\Users\User\.claude\plans\steady-launching-puzzle.md`, Part 3):
  directory CRUD, checkout attribution, purchase history + stats, module-toggle,
  sync re-check. **Caveat:** as scoped (Owner-account happy path), it will
  **not** surface gap #3 — `has_permission()`'s owner bypass means the Owner
  account's writes always pass RLS regardless of the missing permission rows.
  Catching #3 live requires testing as a **non-owner** role (Branch Manager or
  Cashier) after the new migration is applied, or trusting the migration-file
  analysis above.
- ⬜ **Commit** all gap-fixes + new tests + new migration (needs explicit green
  light) — planned as a follow-up `fix(m5): …` commit on top of `971e8ae`.
- ⬜ Backlog within M5: loyalty (separate `loyalty` module), thread
  `customer_id` through drafts + the AI checkout path, AI "top customers" tool.
- ⬜ Backlog within M2: optional LLM-rephrasing layer; `getFraudSummary` (waits
  on M1 fraud engine).

### Repo/branch state
- M2 + M5 are both on `main` as of commit `971e8ae` (2026-07-02). `main` is
  **7 commits ahead of `origin/main`** — **not pushed** yet.
- **Uncommitted working-tree changes on top of `971e8ae`:** the three gap-fixes
  (`module_settings_page.dart`, `customer_inline_picker.dart`,
  `employee_permissions_page.dart`) + two new test files
  (`crm_permissions_test.dart`, `customer_inline_picker_test.dart`) + one new
  **unapplied** migration (`20260703000001_seed_crm_permissions.sql`) + this
  doc. Awaiting explicit go-ahead to commit and to apply the migration.
- Working rule: **never `git push` / commit without an explicit green light** from
  the user.

### Environment note for future sessions
- This local Windows session **DOES** have the Flutter SDK → you CAN run
  `flutter analyze` / `flutter test` / `build_runner` here. (Earlier remote
  sessions could not — if a future session is remote with no SDK, fall back to
  write+self-review and say so honestly; never claim tests passed when not run.)
  Note: `dart run tool/diff_matrices.dart` can't run via plain `dart` (it imports
  `package:flutter/foundation`); verify matrix sync via `flutter test` instead.
