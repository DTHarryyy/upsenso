# UPSENSO — Fraud/Anomaly Triage Fix Plan (2026-07-17)

**Symptom reported:** On the Fraud & Risk page, clicking **Start Investigation /
Mark as Resolved / Dismiss / Not fraud** appears to do nothing.

**Status:** Investigation complete; root cause confirmed by code reading. Two
independent failure layers — a UI/navigation bug (the immediate symptom) and a
sync-convergence design gap (silent triage reverts).

**T0 + T1 IMPLEMENTED 2026-07-17** (self-closing detail + triage feedback;
pull guard, `.select()` rejection check, pendingUpload-preserving `resolve()`,
duplicate-id triage fallthrough, branch-scope client mirror). Verified:
`flutter analyze` clean; fraud DAO (9), fraud cubit (8), fraud engine + rules +
all DAO + alert tests (77) all passing. T2–T4 remain open below.

---

## 1. Root cause of the reported symptom

The alert page lives in **StatefulShellBranch 13** (`app_router.dart:695-701`),
so its `BuildContext` resolves `Navigator.of(context)` to the **branch
navigator**. But on desktop widths (≥1024 px — `breakpoint.dart:14`, i.e. every
Windows-desktop / wide-web session), the detail opens via `showDialog`
(`alert_page.dart:84`), which pushes onto the **root navigator**
(`useRootNavigator: true` is the Flutter default).

The shared triage callback then does:

```dart
// alert_page.dart:78-81
void onSetStatus(AlertStatus status, String? note) {
  cubit.setStatus(alert, status, note);   // local write DOES happen
  Navigator.of(context).pop();            // pops the BRANCH navigator, not the dialog
}
```

Result on desktop: the Drift row updates and the list behind the dialog
refreshes, but the dialog itself (a) never closes — the pop targets the wrong
navigator, and go_router is asked to pop the branch's only page (exception /
branch-stack corruption), and (b) never re-renders — `AlertDetailContent`
receives `alert` as an immutable constructor snapshot with no `BlocBuilder`, so
the status chip and buttons keep showing the old state. To the operator the
button is dead. On mobile widths the pushed `AlertDetailPage` pops correctly,
which is why the bug reads as intermittent/platform-specific.

The rest of the codebase already knows this trap — 9 call sites use
`Navigator.of(context, rootNavigator: true)` (pos_terminal_page, employees_page,
held_sales_page, …). The alert feature just missed the pattern.

**Second layer (why triage can *also* "undo itself" later):** even when the
local write lands, three sync bugs (BUG-5/6/7 below) can silently revert a
resolution back to `new` after the next sync cycle. Any production fix must
close both layers or the button will "work" and the resolution will still
vanish.

---

## 2. Bug inventory (verified against code, severity-ranked)

### Layer A — UI / immediate symptom

| # | Sev | Where | Bug |
|---|-----|-------|-----|
| 1 | **P0** | `alert_page.dart:80` | `Navigator.of(context).pop()` pops the shell **branch** navigator while the desktop dialog lives on the **root** navigator → dialog never closes; popping the branch's only page risks go_router "nothing to pop" / blank-tab corruption behind the dialog. |
| 2 | **P0** | `alert_detail_content.dart` / `alert_detail_dialog.dart` / `alert_detail_page.dart` | Detail renders a **stale snapshot** — `alert` is a constructor param, no `BlocBuilder` selecting the live row by id. Even with pop fixed, an open detail never reflects the new status/resolution note. |
| 3 | **P1** | `fraud_cubit.dart:103, 123-125` | Silent failures, violating the project error rule: `if (!canResolveAlert(alert)) return;` gives zero feedback, and `catch (e, st)` only `debugPrint`s — no snackbar/error UI. `setStatus` is also fire-and-forget: the pop runs before the write resolves, so a DAO failure is invisible. |
| 4 | **P2** | `fraud_cubit.dart:47-53` | `canResolveAlert` mirrors only the self-resolution block. It does **not** mirror the server's branch rules (NULL-branch/business-wide flags are owner-only per RLS `fraud_flags_update`; branch flags require `my_branch_ids()` membership). A Branch Manager therefore gets active buttons on a business-wide flag that the server will reject — feeding BUG-6. |
| 5 | **P2** | `fraud_alerts_card.dart` | Dashboard `FraudAlertsCard` is an unreferenced mockup: hardcoded fake alerts ("Hawak mo ang beat alert"), hardcoded badge `2`, dead `onPressed: () {}` on "View All Alerts", raw `Colors.*` values (style-rule violation). Delete it or rebuild it on real data + `/fraud` route. |
| 6 | **P3** | `alert_page.dart:78` + `alert_detail_content.dart:449` | `onSetStatus` closure reuses the captured list-page `context` after the awaited note dialog with no `mounted` check. |

### Layer B — Sync / convergence (silent triage reverts)

| # | Sev | Where | Bug |
|---|-----|-------|-----|
| 7 (BUG-5) | **P0** | `sync_service.dart:2381-2384` + `fraud_flags_dao.dart:152-180` | **Pull clobbers pending local triage.** Pull upserts every server row via `insertOnConflictUpdate` with no skip for rows whose local `sync_status` is pending/failed, and stamps them `synced`. If a triage push fails (network blip, RLS deny, freeze-trigger error), the next successful pull reverts status to `new` **and erases the retry queue**. Violates "log conflicts, never silently discard". |
| 8 (BUG-6) | **P0** | `fraud_flags_remote_ds.dart:84-92` | **RLS denial is a silent fake success.** `updateTriage` uses `.update().eq('id', …)` without `.select()`; PostgREST returns 200 with 0 rows when RLS filters the row. Sync marks the flag `synced`, server still says `new`, pull reverts local. Any client/server permission divergence (offline default-matrix grant vs missing `effective_permissions` row; manager on a NULL-branch flag; self-resolution block) lands here. Combined with BUG-5 this is the production "resolutions keep coming back" failure mode. |
| 9 (BUG-7) | **P1** | `fraud_flags_dao.dart:55-72` | `resolve()` unconditionally sets `pendingUpdate`. If the row was still `pendingUpload` (flag detected offline, never inserted server-side), the needed INSERT becomes an UPDATE that matches 0 rows → the flag **and** its triage never reach the server. The DAO's own `bulkDismiss` comment documents this exact footgun; `resolve()` doesn't apply it. |
| 10 (BUG-8) | **P1** | pull path | No LWW for triage: pull ignores `client_updated_at`, so two-device triage = last-puller loses locally, last-pusher wins remotely, no conflict logged. |
| 11 | **P2** | `fraud_flags_remote_ds.dart:69-76` | Duplicate-**id** 23505 on insert is swallowed (`return`) and the row is marked synced — but if local content differs (e.g. a `bulkDismiss`-modified row that HAD reached the server as `new`), the dismissal never lands and pull resurrects it. Should fall through to a triage UPDATE, not swallow. |
| 12 | **P2** | `fraud_flags_remote_ds.dart:96-106` | Pull is a full-tenant `limit(500)` newest-first — no watermark; beyond 500 flags old triage never converges, and the full pull each cycle ignores the `_pullIncremental` pattern used by other entities. |
| 13 | **P3** | `fraud_flags_dao.dart:112-123, 186-198` | `getPendingSync()` / `watchPendingSyncCount()` aren't tenant-scoped — on a multi-business device they push/count another tenant's rows (guaranteed 42501 noise → spurious `onTenantRejected` calls). |
| 14 | **P3** | `entitlement_service.dart:231` | `cloudAuditEnabled` ("cross-device fraud sync, paid tiers") is defined but referenced nowhere — fraud sync isn't actually plan-gated. Decide per M7.1 (wire it or delete it). |

### Layer C — Coverage

| # | Sev | Bug |
|---|-----|-----|
| 15 | **P1** | Zero tests on the triage path: no `FraudCubit` tests, no `FraudFlagsDao.resolve` tests, no sync regression tests (push-fail → pull must not clobber; RLS 0-row must fail loudly). Engine/rules have tests; triage — the security-sensitive human workflow — has none. |

---

## 3. Fix plan

### Phase T0 — Hotfix: make the buttons visibly work *(small, ship first)*

1. **Fix the pop target** (`alert_page.dart`). Stop popping from the captured
   page context. Preferred shape: the detail dialog/page closes **itself** with
   its own context, and the page awaits the result:
   - `onSetStatus` becomes `Future<void>` returning after `cubit.setStatus`.
   - `AlertDetailContent._ActionButtons` calls
     `Navigator.of(context).pop()` with **its own** context (inside the dialog
     route → resolves to the root navigator; inside the pushed page → branch
     navigator; both correct with zero special-casing).
   - Alternative if the callback must stay in `_AlertView`:
     `Navigator.of(context, rootNavigator: Breakpoints.isDesktop(context)).pop()`
     — but self-closing is the robust house pattern.
2. **Await + feedback** (`fraud_cubit.dart` + call site): `setStatus` returns
   a result (or emits a transient state). On success → close detail + snackbar
   "Alert marked <status>". On permission-refusal → visible message ("You can't
   triage an alert that implicates you" / "No permission"), **never** a silent
   return. On exception → error snackbar; keep dialog open. Use the existing
   shared feedback widgets from `lib/core/widgets/`.
3. **Keep "Start Investigation" open**: it currently pops the detail — with the
   reactive detail (T1.2) it should stay open and flip the chip to
   Investigating so the operator can keep reading evidence.

### Phase T1 — Correctness: stop silent reverts *(the real production fix)*

1. **Pull guard** (`fraud_flags_dao.upsertFromServer` or its call site):
   before upserting a pulled row, read the local row; if local
   `sync_status ∈ {pendingUpload, pendingUpdate, failed}` **skip** it (and
   `debugPrint` the conflict per project rule). Optional refinement: apply LWW
   on `client_updated_at` and only skip when local is newer — but skip-if-pending
   is the safe minimum (push runs before pull in `syncAll`, so a healthy row
   converges next cycle anyway).
2. **Fail loudly on 0-row updates** (`fraud_flags_remote_ds.updateTriage`):
   append `.select('id')`; empty result ⇒ throw a typed
   `FraudTriageRejected` — sync marks the row `failed` with a human-readable
   `sync_error` ("server refused: permission/branch/self-resolution") instead
   of fake-synced. The alert page surfaces failed triage rows (badge on the
   list item + reason in detail) using the existing `syncError` column.
3. **Fix the pendingUpload→pendingUpdate clobber**
   (`fraud_flags_dao.resolve`): inside a transaction, read the row's current
   `sync_status`; if it's `pendingUpload` (or `failed` after an insert attempt)
   keep it as `pendingUpload` so the row still syncs as a full INSERT carrying
   the triage fields; only rows already `synced` transition to `pendingUpdate`.
4. **Duplicate-id insert falls through to update**
   (`fraud_flags_remote_ds.insertFlag`): on plain-id 23505, retry as
   `updateTriage` instead of swallowing, so a locally-triaged copy of a row the
   server already holds still delivers its triage.
5. **Complete the client mirror** (`fraud_cubit.canResolveAlert`): add the
   branch rules — NULL-branch flags resolvable only when the viewer is
   owner/cross-branch; branch flags only when the viewer's branch matches or
   they hold `data.crossBranchAccess`. The UI must never offer a button the
   server is known to reject (that's what converts BUG-6 from "possible" to
   "daily").

### Phase T2 — Reactive detail UI

1. Rebuild detail on live state: `BlocBuilder<FraudCubit, FraudState>` (or
   `BlocSelector` on the alert id) inside `AlertDetailContent`'s host, so
   status chip, buttons, and resolution note update in place; buttons show a
   brief in-flight disable. The list page already streams from Drift — the
   detail just needs to select from the same stream instead of freezing a
   snapshot.
2. Show sync state honestly: "Resolved — pending sync" vs "Resolved ✓" using
   `sync_status`, and the `syncError` reason when failed. Offline-first rule:
   the local write is instant; the badge only reports convergence.
3. Dashboard card: delete `fraud_alerts_card.dart` or rewire it to
   `FraudFlagsDao.watchByBusiness` + `context.go(AppRoutes.fraud)`; either way
   the hardcoded mock must not ship.

### Phase T3 — Server-side hardening (long-term production posture)

1. **Move triage to an RPC** — `resolve_fraud_flag(p_flag_id, p_status,
   p_note, p_client_updated_at)`, SECURITY DEFINER, new timestamped migration:
   - re-checks permission + branch scope + self-resolution block and returns
     **typed error codes** (no more silent 0-row RLS filtering);
   - enforces a legal transition table (`new → investigating → resolved /
     dismissed / false_positive`; terminal states immutable; re-open =
     explicit separate action if ever wanted);
   - applies LWW on `client_updated_at` and reports `conflict` instead of
     clobbering;
   - writes the triage audit event **server-side** so the audit trail doesn't
     depend on the client remembering to log (today `fraud_cubit` logs
     client-side only).
   Client keeps offline-first: local write immediately, RPC replaces
   `updateTriage` in `_syncFraudFlags`. Keep the freeze trigger as
   defense-in-depth.
   ⚠️ Apply per the standing hazard: **never `supabase db push`** (would replay
   the 20260704 reset) — apply via `npx supabase db query --linked`, one
   statement at a time, after a backup, and ask before running any Supabase CLI
   command.
2. **Read-only prod verification before/after** (via `db query --linked`):
   `fraud_flags_status_check` includes `false_positive`; `fraud_flags_update`
   policy + `trg_fraud_flags_freeze` exist; `effective_permissions` actually
   contains `fraud.resolve` for a sample owner + branch manager (matrices and
   prod have drifted before — don't trust the migration files alone).
3. **Incremental pull**: move fraud flags onto the `_pullIncremental`
   watermark pattern (or raise/paginate past `limit(500)`), so old triage
   converges and each cycle stops re-downloading the tenant's full history.
4. **Entitlement decision (M7.1)**: wire `cloudAuditEnabled` to gate fraud
   push/pull (Starter+ per the pricing design) or delete the dead flag. On
   Free, SyncService is off entirely, so local-only triage already works — the
   gate is about paid-tier semantics, not correctness.
5. Tenant-scope `getPendingSync`/`watchPendingSyncCount` to the active
   business id.

### Phase T4 — Tests (regression gate for all of the above)

- `FraudCubit`: setStatus emits feedback on success/denial/exception; denial
  paths for subject-user and (new) branch-mirror rules.
- `FraudFlagsDao`: `resolve()` preserves `pendingUpload`; only `synced` rows
  become `pendingUpdate`.
- Sync (mocktail): push-fail → pull does **not** clobber and does **not**
  stamp `synced`; 0-row `updateTriage` → row marked `failed` with reason;
  duplicate-id insert falls through to update; dedupe-conflict → supersede.
- Widget test: desktop-width dialog — each button closes the dialog (or
  updates in place) and the list reflects the new status; mobile-width page
  ditto.

---

## 4. Execution order & effort

| Phase | Contents | Size | Risk |
|-------|----------|------|------|
| T0 | pop fix, feedback, await | ~3 files | trivial — pure client |
| T1 | pull guard, `.select()` check, resolve() transition, dup-id fallthrough, client mirror | ~4 files | low — flag-scoped, no schema change |
| T2 | reactive detail, sync badges, dashboard card | ~4 files | low |
| T3 | triage RPC migration + prod verify + incremental pull + entitlement | 1 migration + ~3 files | medium — prod migration discipline applies |
| T4 | tests | test-only | none |

T0+T1 together are the minimum honest fix: T0 makes the button visibly work;
T1 makes the result durable. Shipping T0 alone would reintroduce the classic
"it worked yesterday, the alert is back today" ticket.

## 5. Verification (after T0/T1)

1. `flutter analyze` + `flutter test` (including new T4 tests).
2. Run on Windows desktop ≥1024 px: open an alert → each of the four buttons →
   dialog closes (or updates), list chip changes, snackbar shows, Fraud tab
   not corrupted afterward.
3. Resize <1024 px and repeat on the pushed-page path.
4. Offline drill: airplane-mode → resolve a flag → go online → sync → confirm
   status survives the next **two** sync cycles (the revert bug's window).
5. Two-device drill (or simulated): device A resolves, device B pulls →
   B converges to resolved; B resolving a different flag concurrently doesn't
   lose either triage.
6. Denial drill: Branch Manager on a business-wide (NULL-branch) flag → button
   disabled with explanation (T1.5), not a fake success.
