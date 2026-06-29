# UPSENSO — Fraud Detection Engine & Tamper-Evident Audit Chain (Design)

> Status: **proposed** · Owner: platform · Branch: `claude/platform-features-roadmap-7bqdgn`
> Closes the gap between the product promise ("fraud detection", "tamper-evident
> audit chain") and the code, where today both are absent or mocked.

## Why this doc exists

Two things UPSENSO advertises do **not** exist in code:

1. **Tamper-evident audit chain.** `docs/AI_CONTEXT.md` describes `previous_hash`
   / `hash` fields and an "append-only, never modify" trail. The real
   `audit_logs` table (`lib/core/database/tables/audit_logs_table.dart`) has no
   hash columns. Append-only is enforced at the RLS layer
   (`20260627000006_enforce_settings_and_audit_immutability.sql` drops the
   UPDATE policy), but there is **no cryptographic tamper-evidence** — a
   privileged actor with DB access, or a desync, can still rewrite history
   undetectably.
2. **Fraud detection.** The `alert` feature
   (`lib/features/alert/data/alert_model.dart`) is a hardcoded
   `mockFraudAlerts` list. There is no engine, no `fraud_flags` table, no rules,
   no permissions.

This document specifies both, end to end, following the mandatory feature
checklist in `CLAUDE.md` (PermissionKeys → AppPermission → AppFeature → both
matrices → module table → PermissionService → guards/logic → tests).

## Why NOT blockchain (recorded decision)

The original goal was a public blockchain for tamper-proofing. We are **not**
doing that. Reasons:

- **Offline-first is incompatible with on-chain writes.** UPSENSO writes locally
  first and syncs later under Last-Write-Wins. A blockchain needs connectivity
  and consensus *at write time*. The two models fight each other.
- **Volume & cost.** A busy POS produces thousands of writes/day/branch.
  On-chain storage (or per-record anchoring) is absurd cost and latency for an
  SMB tool.
- **Wrong threat model.** Public chains buy *trustlessness* against a distrusted
  central operator. Here the operator (the business owner + Supabase) is trusted.
  The real requirement is **tamper-EVIDENCE**, not trustless consensus.

A **hash-chained append-only ledger** delivers ~95% of the benefit at ~0% of the
cost and is offline-first native. Optional daily anchoring (below) covers the
remaining external-proof case without per-record chain writes.

---

# Part 1 — Tamper-Evident Audit Chain

## 1.1 Concept

Each audit row stores a `entry_hash` derived from the previous row's hash plus a
canonical serialization of this row's content:

```
entry_hash = SHA256( prev_hash + "|" + canonical_payload )
```

Changing any historical row changes its `entry_hash`, which breaks every
subsequent row's hash — making tampering detectable by re-walking the chain. The
chain is scoped **per `(business_id, device_id)`** rather than globally, because
UPSENSO is offline-first and multi-device: each device produces an independent
local sequence, and a single global chain would be unmaintainable when two
offline devices both append before syncing. Per-device chains each verify
independently and never need reordering.

> Decision: **per-(business, device) chains**, not one global chain. LWW sync
> stays valid; verification is per-device.

## 1.2 Canonical payload

Determinism is everything — both the writer and the verifier must produce byte
-identical input. Canonical payload is a sorted-key, no-whitespace JSON of the
*immutable* fields only (never include `sync_status`, `last_sync_attempt`,
`sync_error`, or the hashes themselves):

```
{"action_type":..,"branch_id":..,"business_id":..,"created_at":<ISO8601 UTC>,
 "description":..,"device_id":..,"entity_id":..,"entity_type":..,
 "metadata":<canonicalized>,"seq":<int>,"user_id":..}
```

- `created_at` serialized as UTC ISO-8601 with millisecond precision, fixed
  format. Never the local-zone string.
- `metadata` is re-canonicalized (keys sorted recursively) before hashing.
- `seq` is the per-(business, device) monotonically increasing counter
  (see 1.4).

A `canonicalAuditPayload(AuditLogRow)` pure function lives in
`lib/core/audit/audit_hash.dart` and is the **single** serializer used by both
the writer and the verifier. One serializer = no drift between sides.

## 1.3 Schema changes

### Drift (`audit_logs_table.dart`) — bump `schemaVersion` 51 → 52

Add nullable columns (nullable so existing rows + the v51→v52 upgrade don't need
backfill values at insert time; the writer always populates them going forward):

```dart
IntColumn  get seq        => integer().nullable()();      // per (business, device)
TextColumn get prevHash   => text().nullable()();         // hash of prior entry, '' for genesis
TextColumn get entryHash  => text().nullable()();         // this row's hash
```

`onUpgrade` step for v52: `ALTER TABLE audit_logs ADD COLUMN seq INTEGER;` (×3).
Historical rows keep `seq/prev_hash/entry_hash = NULL` and are treated as the
**pre-chain segment** — the verifier starts the chain at the first non-null row
(its `prev_hash` is the genesis sentinel). This avoids a destructive backfill.

> Per `CLAUDE.md` Database & Migration Safety: this is **additive only** — no
> drops, no type changes. Rollback = ignore the columns (or `ALTER TABLE DROP
> COLUMN` on the local DB, which is a fresh-install-safe no-op for most users).

### Supabase migration `…_audit_chain_columns.sql`

```sql
ALTER TABLE public.audit_logs
  ADD COLUMN IF NOT EXISTS seq        bigint,
  ADD COLUMN IF NOT EXISTS prev_hash  text,
  ADD COLUMN IF NOT EXISTS entry_hash text;
-- append-only is already enforced (UPDATE policy dropped in ...000006);
-- DELETE already denied. No new policy needed for INSERT — keep existing.
-- ROLLBACK: ALTER TABLE public.audit_logs DROP COLUMN seq, prev_hash, entry_hash;
```

The columns are **synced like any other field** (the existing audit sync path in
`SyncService` just carries three more text/int columns). No RLS change: the
chain is *self-verifying*, so even if the server stored a tampered row, the
verifier detects the broken link. We do **not** trust the server to compute the
hash.

## 1.4 Write path

`AuditLogService.log()` (`lib/core/audit/audit_log_service.dart`) currently
inserts a bare row. Change it to, **inside a single Drift transaction** (so
`seq` allocation can't race between two concurrent `log()` calls on one device):

1. Resolve `(business_id, device_id)` as it already does.
2. `SELECT seq, entry_hash FROM audit_logs WHERE business_id=? AND device_id=?
   ORDER BY seq DESC LIMIT 1` → `(lastSeq, lastHash)`.
3. `seq = (lastSeq ?? 0) + 1`; `prevHash = lastHash ?? GENESIS` (GENESIS =
   `'0' * 64`).
4. `entryHash = sha256(canonicalAuditPayload(row, seq, prevHash))`.
5. Insert with the three new fields populated.

Keep the existing fire-and-forget + tenant-guard behavior. Hashing is local,
deterministic, and offline-safe — **no behavioral change for the caller**.

Use `package:crypto` (`sha256`). Check `pubspec.yaml`; if absent, add it (it is
a first-party Dart package, no platform plugins, web-safe).

## 1.5 Verifier

New `AuditChainVerifier` in `lib/core/audit/audit_chain_verifier.dart`:

```dart
Future<List<AuditChainBreak>> verify({required String businessId});
```

For each `device_id` in the business: load rows ordered by `seq`, walk them,
recompute each `entry_hash`, and assert `row.prevHash == previous.entryHash` and
`row.seq == previous.seq + 1`. Any mismatch yields an `AuditChainBreak`
(deviceId, seq, expectedHash, actualHash, reason). The pre-chain NULL segment is
skipped.

Trigger points:
- On demand from the Audit Logs page ("Verify integrity" button, gated by
  `audit_logs.verify`).
- As a **fraud rule** (`AUDIT_TAMPER`, see Part 2) run during the periodic
  sweep — a break raises a `CRITICAL` fraud flag automatically.

## 1.6 Optional external anchoring (Phase 2, deferred)

To prove the chain wasn't rewritten *wholesale* while offline, a daily job can
hash each device chain head and persist `(business_id, device_id, seq, head_hash,
anchored_at)` to a write-once `audit_anchors` Supabase table (server timestamp,
INSERT-only RLS). One row/device/day — negligible cost. A future, fully optional
enhancement could post that single daily head hash to an external timestamping
service (e.g. OpenTimestamps); explicitly **out of scope** for v1 and the only
place any chain-anchoring tech would ever appear. Documented here so the schema
leaves room; not built in Phase 1.

---

# Part 2 — Fraud Detection Engine

## 2.1 Concept

A deterministic, offline-first rules engine that scans existing local data
(`transactions`, `refunds`, `stock_ledger`, shifts, `audit_logs`) and writes
`fraud_flags`. No ML in v1 — rules are explainable, testable, and run on-device.
The AI assistant later *summarizes* flags (it does not replace the engine).

Replaces the mock `lib/features/alert/data/alert_model.dart`. The existing
`alert` UI (`alert_page.dart`, filter bar, detail views) is reused — only its
data source changes from `mockFraudAlerts` to a real cubit backed by a
`FraudFlagsDao`.

## 2.2 `fraud_flags` schema

### Drift `fraud_flags_table.dart` (`@DataClassName('FraudFlagRow')`)

```dart
TextColumn get id           => text()();
TextColumn get businessId   => text()();
TextColumn get branchId     => text().nullable()();
TextColumn get ruleCode     => text()();   // e.g. 'EXCESSIVE_REFUNDS'
TextColumn get severity     => text()();   // 'low'|'medium'|'high'|'critical'
TextColumn get status       => text().withDefault(const Constant('new'))(); // new|investigating|resolved|dismissed
TextColumn get title        => text()();
TextColumn get description  => text()();
TextColumn get subjectUserId=> text().nullable()(); // employee implicated, if any
TextColumn get evidence     => text().withDefault(const Constant('{}'))(); // JSON
TextColumn get relatedIds   => text().withDefault(const Constant('[]'))(); // JSON list of source ids
TextColumn get resolvedBy   => text().nullable()();
TextColumn get resolutionNote => text().nullable()();
DateTimeColumn get detectedAt => dateTime().withDefault(currentDateAndTime)();
DateTimeColumn get createdAt  => dateTime().withDefault(currentDateAndTime)();
DateTimeColumn get updatedAt  => dateTime().withDefault(currentDateAndTime)();
DateTimeColumn get clientUpdatedAt => dateTime().withDefault(currentDateAndTime)();
DateTimeColumn get deletedAt  => dateTime().nullable()();
// Sync tracking — same 0/1/2/3/4 pattern as every table.
IntColumn  get syncStatus => integer().withDefault(const Constant(0))();
DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
TextColumn get syncError  => text().nullable()();
// Idempotency: a deterministic key so the same window/subject isn't flagged
// twice across sweeps. e.g. sha1('EXCESSIVE_REFUNDS|user|2026-06-29T14').
TextColumn get dedupeKey  => text()();
```

Add a unique index on `(business_id, dedupe_key)` so re-running a sweep updates
rather than duplicates. Same schemaVersion bump that adds the chain columns can
add this table (v52), or sequence it as v53 — keep one DAO change per version.

### Supabase migration `…_fraud_flags.sql`

Mirror the columns. RLS:
- SELECT: tenant-scoped **and** `has_permission('fraud.view')` (RESTRICTIVE),
  matching the branch/ownership scoping pattern in
  `20260627000014_scope_select_rls_branch_and_ownership.sql`.
- INSERT: tenant-scoped (the client engine writes flags). Consider also allowing
  server-side detectors via SECURITY DEFINER later.
- UPDATE: `has_permission('fraud.resolve')` (status/resolution only).
- DELETE: denied (soft-delete via `deleted_at`).
- Rollback section dropping table + policies.

## 2.3 Rules (v1)

Each rule is a class implementing:

```dart
abstract class FraudRule {
  String get code;
  AlertSeverity get severity;
  Future<List<FraudFlagDraft>> evaluate(FraudScanContext ctx);
}
```

`FraudScanContext` carries `businessId`, the scan window, configured thresholds,
and DAO handles. Rules are **pure reads** + return drafts; the engine dedupes and
persists. Thresholds live in a `fraud_settings` row (per business) so owners can
tune them — default values below.

| code | trigger | default threshold | severity | data source |
|---|---|---|---|---|
| `EXCESSIVE_REFUNDS` | refunds by one user in window | >5 / 2h | high | `refunds.refunded_by` |
| `HIGH_DISCOUNT` | discount % on a sale over cap | >30% | medium | `transactions.discount_amount` vs subtotal |
| `SALE_AFTER_SHIFT` | sale timestamped after shift close | any | medium | transaction vs shift close time |
| `INVENTORY_SHRINKAGE` | OUT ledger w/ reason Adjustment/Damage over cap | > configurable units or value | high | `stock_ledger` (reason, sourceType) |
| `REPEATED_VOIDS` | voids by one user in window | >3 / 1h | high | transactions status='void' / audit |
| `NEGATIVE_MARGIN_SALE` | item sold below cost | any | medium | transaction_items vs product cost |
| `AUDIT_TAMPER` | `AuditChainVerifier` finds a break | any | critical | Part 1 verifier |
| `AFTER_HOURS_LOGIN` | login outside branch hours | any | low | audit_logs login events |

Start with the first four + `AUDIT_TAMPER` (these map directly to the existing
mock alert types, so the UI lights up immediately). Add the rest incrementally.

## 2.4 Engine & scheduling

`FraudDetectionEngine` (`lib/core/services/fraud_detection_engine.dart`):

- `Future<void> runSweep({DateTime? since})` — runs all enabled rules, dedupes by
  `dedupe_key`, inserts new `fraud_flags`, and emits a `notifications` entry +
  raises severity-appropriate alerts.
- **Triggers:**
  - *Event-driven, cheap:* after a refund/void/adjustment commits, run only the
    relevant rule for that subject+window (incremental).
  - *Periodic sweep:* on app foreground + every N minutes while active, run the
    full set since the last sweep watermark (stored in `sync_state`/a settings
    row). Offline-safe — operates entirely on local Drift data.
- All work is local-first; flags sync to Supabase like any entity.

Wire registration in `lib/core/config/di.dart` (singleton), and run the
post-commit hooks from the existing `CheckoutService` / `RefundService` /
`StockMovementService` rather than from UI.

## 2.5 UI

Reuse the `alert` feature. Replace mock with `FraudCubit` → `FraudFlagsDao`
stream. Keep `AlertSeverity`/`AlertStatus`/`AlertType` enums but source them from
real rows (map `ruleCode`→`AlertType`, or generalize `AlertType` to the rule
code). Add a resolve/dismiss action gated by `fraud.resolve`, writing
`resolvedBy`/`resolutionNote` + an audit log entry (`fraudFlagResolved`).

---

# Part 3 — Permissions, modules, wiring (mandatory checklist)

Per `CLAUDE.md`, in this exact order:

### 3.1 `PermissionKeys` (`permission_keys.dart`)
```dart
// ── Fraud / Risk ──
static const String fraudView    = 'fraud.view';
static const String fraudResolve = 'fraud.resolve';
static const String navFraud     = 'nav.fraud';
// ── Audit ── (extend existing block)
static const String auditLogsVerify = 'audit_logs.verify';
```
Add all four to the `all` list.

### 3.2 `AppPermission` (`app_permission.dart`)
Add enum values `viewFraudAlerts`, `resolveFraudAlerts`, `verifyAuditChain`
mapped to the keys above (follow the existing enum↔key mapping convention in the
file).

### 3.3 `AppFeature` (`app_feature.dart`)
Add `fraudAlerts`:
- `displayLabel` → "Fraud & Risk"
- `moduleCode` → `'audit'` (reuse the existing audit module gate — fraud and
  audit are the same "security" surface; avoids a new module toggle. If product
  wants independent toggling, add a `fraud` module instead — see 3.6).
- `navKey` → `'nav.fraud'`

### 3.4 `role_permission_matrix.dart`
- Owner/Super Admin/Business Owner: already get all (no edit needed).
- **Branch Manager:** `viewFraudAlerts`, `resolveFraudAlerts`, `verifyAuditChain`
  (managers police their branch).
- Cashier / Inventory Staff: none.

### 3.5 `default_permission_matrix.dart`
Mirror 3.4 exactly with the string keys. **Run
`dart run tool/diff_matrices.dart`** afterward — must report in-sync.

### 3.6 Module gate (`business_modules_table.dart` + module settings page)
Default: gate fraud under the existing `audit` module. Only if product wants a
separate switch, register a new `fraud` module code and add it to the module
settings UI. (Recommendation: reuse `audit` for v1.)

### 3.7 Enforcement
- GoRouter guard for the fraud route → `canAccessFeature(AppFeature.fraudAlerts)`.
- `FraudCubit` checks `can(fraudView)` before loading; resolve action checks
  `can(fraudResolve)`. **Checks live in cubit/engine, not just hidden UI.**
- Audit "Verify integrity" button + verifier entry point check
  `can(auditLogsVerify)`.
- Server: the RLS policies in 2.2 are the real enforcement.

---

# Part 4 — Offline / sync / AI

- **Offline-first:** hashing and rule evaluation are 100% local. Flags and audit
  chain columns sync via the existing `SyncService` paths (just more columns / a
  new entity). LWW applies; fraud flags are append-mostly (status updates use the
  standard `pendingUpdate` path).
- **Sync of chain:** per-device chains never need conflict resolution — each
  device owns its `seq` sequence; two devices can't collide.
- **AI integration:** add an `AiToolService` method
  `getFraudSummary(businessId, dateFilter, {branchId})` reading `fraud_flags`
  (branch-filtered, permission-aware exactly like the existing sales queries).
  Enables NL queries ("any fraud alerts this week?") and the proactive-insights
  digest. The AI **reads** flags; it never creates or resolves them.

---

# Part 5 — Phasing & tests

**Phase 1 (audit chain):** Drift v52 + Supabase columns → `audit_hash.dart`
canonical serializer → writer change → `AuditChainVerifier` → verify button +
`AUDIT_TAMPER` hook. Ship independently of fraud.

**Phase 2 (fraud engine):** `fraud_flags` table → `FraudFlagsDao` → 4 rules +
`AUDIT_TAMPER` → engine + triggers → swap `alert` UI to real data → permissions.

**Phase 3 (polish/deferred):** remaining rules, `fraud_settings` tuning UI,
optional `audit_anchors` anchoring, AI fraud summary + proactive digest.

### Tests (a feature isn't done without these — `CLAUDE.md`)
- `audit_hash`: canonical serialization is stable & order-independent for
  metadata; UTC formatting fixed.
- Writer: `seq` increments per (business, device); genesis handling; concurrent
  `log()` calls don't duplicate `seq` (transaction test).
- Verifier: clean chain passes; mutate one row → exactly one break at the right
  `seq`; pre-chain NULL segment skipped.
- Each `FraudRule`: positive case flags, negative case doesn't, threshold
  boundary, dedupe (re-run = no duplicate, updates existing).
- Permission resolution: manager sees fraud, cashier denied; resolve gated.
- Sync: flag status transition `new→resolved` carries `pendingUpdate`.

---

## File-change summary

| Action | Path |
|---|---|
| edit | `lib/core/database/tables/audit_logs_table.dart` (+3 cols) |
| new | `lib/core/audit/audit_hash.dart` |
| edit | `lib/core/audit/audit_log_service.dart` (chain write) |
| new | `lib/core/audit/audit_chain_verifier.dart` |
| edit | `lib/core/database/app_database.dart` (schemaVersion 51→52 + onUpgrade) |
| new | `lib/core/database/tables/fraud_flags_table.dart` |
| new | `lib/core/database/daos/fraud_flags_dao.dart` |
| new | `lib/core/services/fraud_detection_engine.dart` + `lib/core/services/fraud_rules/*.dart` |
| edit | `lib/features/alert/**` (mock → real cubit) |
| edit | `permission_keys.dart`, `app_permission.dart`, `app_feature.dart`, `role_permission_matrix.dart`, `default_permission_matrix.dart` |
| edit | `lib/core/config/di.dart`, `lib/app_router.dart` (guard) |
| edit | `lib/features/ai_assistant/services/ai_tool_service.dart` (fraud summary) |
| new | `supabase/migrations/<ts>_audit_chain_columns.sql`, `<ts>_fraud_flags.sql` |
| new | tests mirroring the above under `test/` |
