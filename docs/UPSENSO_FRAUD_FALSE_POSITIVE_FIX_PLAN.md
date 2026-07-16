# Fraud/Anomaly False-Positive Incident (2026-07-03) — Investigation + Fix Plan

> **2026-07-16 hardening round (accuracy pass on the shipped P0/P1 code):**
> 1. **Audit mirror late-arrival repair** (`AuditMirrorRepair`, runs after
>    every audit pull): the created_at-keyset pull permanently skips rows
>    another device pushed late (offline backlog / chain-conflict holdback) —
>    the resulting local seq holes read as `seqGap` (critical tamper FP) and
>    missing REFUND_CREATED tails re-create the orphan FP. Repair refetches
>    missing seq ranges + other devices' stale tails by seq; own chain's tail
>    is never touched (writer/verifier semantics preserved).
> 2. **Inconclusive scans** — `FraudRule.evaluate` may now return null ("no
>    verdict": mirror never pulled, empty judgeable window); the engine leaves
>    candidate state untouched instead of treating it as "all clean" and
>    wiping candidates. `deleteStale` additionally runs on FULL sweeps only.
> 3. **Stable tamper confirmation** — AUDIT_TAMPER drafts carry an explicit
>    `confirmationSignature` built from stable break identities; truncation
>    evidence embeds moving head seqs and previously restarted confirmation
>    every sweep (the flag could never surface).
> 4. **Chain-safe prune** — `pruneOlderThan` deletes chained rows only as a
>    contiguous per-chain seq prefix (bounded by the first row newer than the
>    cutoff or not yet synced); a plain created_at delete carved mid-chain
>    holes out of re-chained blocks and around stuck unsynced rows → seqGap
>    FPs.
> 5. **TIME_REVERSAL `_rechained` check** parses metadata JSON in Dart instead
>    of SQL LIKE (jsonb round trips reordering keys/whitespace can no longer
>    resurrect the re-chain FP; markers inside string values don't suppress).
> 6. **Cross-branch aggregation** — EXCESSIVE_REFUNDS / REFUND_STRUCTURING
>    group per employee(+day) across branches (split-across-branches evasion
>    + colliding dedupe keys fixed); branch attributed only when unique.
> 7. Minor: PERMISSION_PROBING orders denials by created_at (correct
>    detectedAt/branch); HIGH_DISCOUNT 30-day rate excludes voided sales.
> Regression tests restored + extended (61 green): `test/core/services/…`,
> `test/core/audit/audit_mirror_repair_test.dart`.

> **Status: P0 + P1 + §4c + §5 IMPLEMENTED (2026-07-04), not yet deployed.**
> Code landed on the working tree; Drift schema is at **v56**; full suite green
> (200 tests, +12 regression). Three Supabase migrations are **written but NOT
> applied**:
> `20260704000001_fraud_fp_hardening.sql` (hash_version + indexes + orphan RPC),
> `20260704000002_devices_directory.sql` (normalized device table + RLS),
> `20260704000003_fraud_flag_false_positive_status.sql` (status CHECK widening).
> Companion design doc: `UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md`.
>
> **⚠ Deployment ordering (must hold):** apply all three migrations **before**
> shipping this client build. The audit sync mapper now sends `hash_version`
> (errors without the column), the client pushes to `devices` (table must
> exist), and it may set status `false_positive` (CHECK must allow it). All are
> additive + reversible (rollback in each header). After deploy,
> `FraudMaintenanceService` auto-dismisses the existing false-positive flags
> once per install (P0.4), gated by `fraud.resolve`.
>
> **What shipped:** P0.1–P0.5; P1.1–P1.6, P1.8, P1.9 (best-effort web
> `navigator.locks`), P1.10; P1.7 orphan RPC; §4c (`devices` table normalizing
> the label out of every audit row, indexes, verifier/alert read the canonical
> label); §5 (`false_positive` status, per-device-per-day tamper digest,
> CONTROL_CHANGE burst digest, "Business-wide" display, sweep `_debug`
> evidence, audit-push pagination). **Deferred:** §4c derived descriptions
> (still stores prose `description` — deferred to avoid a second hashed-payload
> change), server-side action_type CHECK constraints (skipped — brittle on a
> live table), configurable EXCESSIVE_REFUNDS thresholds UI.

---

## §1 Incident summary + verified evidence

On 2026-07-03 the owner stress-tested refunds (and bulk-set permission
overrides) on the web app. The Alerts page then showed:

| Alert | Severity | Count | Verdict |
|---|---|---|---|
| Audit trail integrity broken ("Web · chrome" 6 + 55 issues, "Web · safari" 1) | critical | 3 flags | **FALSE POSITIVE** |
| Refund with no audit trail (₱150, ₱100 — Harry, Main) | high | 2+ flags | **FALSE POSITIVE** |
| Device clock moved backwards ("5 minute(s) BEFORE") | high | 1 flag | **FALSE POSITIVE** |
| Unusual refund volume (6 refunds ₱840) | high | 1 flag | True detection (testing) |
| Fraud-control setting changed (sensitive overrides granted) | low | 3+ flags | True detection (testing) |

Nothing was altered, removed, or truncated. Evidence gathered live from prod
(`npx supabase db query --linked`, read-only, 2026-07-03):

1. **Both flagged refunds have their audit rows on the server.**
   `5cb699f4-…` (₱150) and `0c3467a6-…` (₱100), created 03:44 UTC (= 11:44 AM
   PH), each have exactly **1** matching `audit_logs` row
   (`entity_id = refund.id`). The refund flow logged correctly; the *scanning
   device's local mirror* just hadn't pulled the audit rows yet.
2. **The audit chain is seq-complete on the server — no gaps, no tampering.**
   Chain `b318a37a-…` covers seq 1–112 contiguously (99 rows labeled
   "Web · chrome" + 12 labeled "Web · safari" + 1 later). Chain `8e14c790-…`
   covers seq 1–15 with 0 missing.
3. **The "clock moved backwards" flag is a re-chaining artifact.** On chain
   `b318a37a`: seq 55 is stamped 22:58:35 UTC, then **seq 56 jumps back to
   22:53:29**. Seq 56–100 form a contiguous, internally time-ordered block
   (USER_LOGIN → 6× REFUND_CREATED → FRAUD_FLAG_RAISED…) — the signature of a
   conflicted chain tail transplanted by `reconcileConflictedTail` (seq
   reassigned, original `created_at` preserved). The device clock was never
   set back.
4. **Two concurrent app instances shared one `device_uid`.** Rows labeled
   "Web · chrome" and "Web · safari" interleave within seconds on the same
   chain (seq 1 chrome 22:48:21 → seq 2 safari 22:48:59 → seq 3 chrome). This
   concurrency is what forced the chain conflict → re-chain → time-reversal FP.
5. **`fraud_flags` on the server: 0 rows** while the UI shows many local
   flags. Note: earlier the same day, 46 false server flags were deleted
   (execution-sequence footer, fix F5) — so the push path *has* worked before;
   either sync hasn't succeeded since, or the new flags fail to push.
6. **Audit chain meta-noise:** 60+ of the 111 entries on chain `b318a37a` are
   `FRAUD_FLAG_RAISED` — the fraud system's own logging dominates the
   tamper-evidence trail.

Alerts showed **"All branches"** because `fraud_flags.branch_id` is NULL for
tamper/control flags and the cubit renders NULL as the literal string
(`lib/features/alert/presentation/cubit/fraud_cubit.dart:172-174`).

---

## §2 Root-cause analysis

All detection is **client-side over the local Drift mirror** — the server only
stores rows, enforces `ux_audit_chain UNIQUE(business_id, device_uid, seq)`,
and serves chain-head RPCs (`supabase/migrations/20260703000002_audit_chain_columns.sql`).
A client mirror is *inherently stale*; every rule that treats local absence as
proof of absence will false-positive. That is the common thread.

### RC-1 · "Refund with no audit trail" (`ORPHANED_RECORD`)
`lib/core/services/fraud_rules/rules/orphaned_record_rule.dart:43-78` flags any
refund with `NOT EXISTS (SELECT 1 FROM audit_logs a WHERE a.entity_id = r.id)`:

- Scans the **local** audit mirror only, but the 10-min grace
  (`FraudDefaults.orphanGraceSeconds`, `fraud_rule.dart:28`) is measured
  against the refund's **event time**, not mirror freshness. A refund that
  synced to the scanning device before its audit row got pulled is flagged
  once it's >10 min old — precisely what happened.
- The subquery has **no `business_id` or `action_type` filter**; the local
  mirror is pruned to 90 days (`audit_logs_dao.dart:274`).
- Structural contributors that widen the window:
  - The audit entry is written **after** the refund's Drift transaction
    commits, fire-and-forget, all errors swallowed
    (`refund_service.dart:190`; `audit_log_service.dart:145,152-160,223-226`
    — silent drop on empty business, tenant-guard mismatch, any exception).
  - Sync pushes **refunds before audit logs** each cycle
    (`sync_service.dart:520` vs `:529`).
  - Audit push is **unsorted** and capped at 500
    (`audit_logs_dao.dart:178-188`), and a chain conflict **aborts the rest of
    the audit push cycle** (`sync_service.dart:2252-2259`).

### RC-2 · "Audit trail integrity broken" (`AUDIT_TAMPER`)
Residue of the same-day false-tamper flood (wiped IndexedDB + surviving
localStorage uid restarted chains at seq 1; fixes F1–F3 already in the working
tree: `_resolveResume`, uid rotation, `reconcileConflictedTail`, verifier-only
rule). Residual FP vectors in `lib/core/audit/audit_chain_verifier.dart`:

- **Legacy canonicalization drift**: rows written before the metadata
  double-encode fix (old mapper sent the metadata JSON *string* → Postgres
  stored a double-encoded jsonb scalar; `upsertFromServer` now normalizes via
  `_metadataText`, `audit_logs_dao.dart:258-262`) can recompute to a different
  hash than the one stored → mass `hashMismatch` on historical rows.
- **Web storage split**: chain uid lives in localStorage
  (`device_identity_service.dart:44`) but the Drift DB lives in IndexedDB —
  browsers evict them independently → `truncatedTail`
  (`audit_chain_verifier.dart:158-167`) from a benign storage event.
- **Coercion invariants are accidental**: the device hashes `''` for missing
  branch/user while the mapper ships `NULL` (`audit_log_sync_mapper.dart:16-17`);
  the pull path happens to coerce back. Same for entity_id UUID-nulling
  (`audit_hash.dart:82`) and the fixed timestamp format.

### RC-3 · "Device clock moved backwards" (`TIME_REVERSAL`)
`time_reversal_rule.dart:20-37` compares adjacent seq pairs per device chain
(`a.created_at < p.created_at - tolerance`). `reconcileConflictedTail`
(`audit_log_service.dart:300-347`) reassigns seq for a transplanted tail but
**preserves original timestamps** — so the first row of a re-chained block
always looks like a clock rollback. The rule cannot distinguish the two.

### RC-4 · Concurrent writers on one `device_uid`
Two app instances (chrome- and safari-labeled) wrote the same chain
concurrently. Each held its own in-memory head → seq collision at push →
conflict → re-chain (→ RC-3). The uid-sharing mechanism needs code-level
confirmation (`device_identity_service.dart`; drift-web multi-tab; browserName
label flapping in `device_info_service.dart:29-31` may mean it was two tabs of
one browser mislabeled, not two browsers).

### RC-5 · "All branches" display
`AuditTamperRule` (and control-change drafts with empty branch) set no
`branchId` → NULL renders as 'All branches' (`fraud_cubit.dart:172-174`), even
though the broken/affected audit rows carry `branch_id` and the branch is
derivable. Device labels shown in alerts ("Web · chrome") are the non-unique
display column, not the chain identity.

### RC-6 · `fraud_flags` sync not landing
0 rows server-side with many local flags. M1 fraud code is entirely
**uncommitted working-tree code** — deployed-build provenance is a prerequisite
question. Independent known defect: the mapper sends `evidence`/`related_ids`
as JSON **text** into jsonb columns (`fraud_flags_remote_ds.dart`) — same bug
class as the audit metadata double-encode.

### RC-7 · Meta-noise + true-positive tuning
`FRAUD_FLAG_RAISED` is chained per flag → the fraud system floods its own
evidence trail. `EXCESSIVE_REFUNDS` and `CONTROL_CHANGE` fired correctly on the
testing session (6 refunds ₱840; 45 `PERMISSION_OVERRIDE_SET` rows at 22:52) —
they need thresholds/digesting and better branch display, not correctness
fixes.

---

## §3 P0 — Stop the bleed (no schema changes; one hotfix build)

### ⬜ P0.1 Diagnose + fix fraud_flags sync
Ordered, cheapest first:
1. Confirm the deployed build contains `_syncFraudFlags`
   (`sync_service.dart:2287`) — M1 is uncommitted; check live version vs
   `pubspec.yaml` (`1.4.7+238`).
2. On the owner device: local flags' `sync_status` / `sync_error`
   (`getPendingSync` caps 200, statuses 0/1/4).
3. Check whether an earlier entity in `syncAll()`'s big `try` throws before
   `_syncFraudFlags` runs (it aborts the whole block).
4. Supabase API logs for `fraud_flags` INSERT 4xx; verify RLS
   `fraud_flags_insert` (`WITH CHECK business_id = get_my_business_id()`) and
   the `severity`/`status` CHECKs against what the client sends.
5. **Fix regardless:** mapper double-encode — decode `evidence`/`related_ids`
   to objects before send (mirror `decodeMetadataForRemote`,
   `audit_log_sync_mapper.dart:44`); keep `FraudFlagsDao.upsertFromServer`
   tolerant of both forms.
6. Add fraud_flags synced/failed counts to `SyncResult` (currently
   debugPrint-only).

### ⬜ P0.2 OrphanedRecordRule — mirror-freshness gate + query scoping
Files: `orphaned_record_rule.dart`, `fraud_rule.dart`,
`fraud_detection_engine.dart`.
- Engine injects the audit pull watermark into `FraudScanContext`
  (`SyncStateDao.getWatermark('audit_logs', businessId)` — already exists,
  advanced by `_pullWithWatermark`). New field `DateTime? auditMirrorFreshAt`.
- Judge only records with
  `created_at <= min(now, auditMirrorFreshAt) - grace`; if the watermark is
  null (mirror never pulled) the rule returns `[]`. Lag can only *suppress*
  flags, never create them — this alone kills the verified FP.
- Scope the subquery: `a.business_id = ?` and `a.action_type IN
  ('REFUND_CREATED')` (resp. `'STOCK_ADJUSTED'` for the ledger branch). Land
  together with the freshness gate (stricter matching alone would add FPs).
- Exclude records older than the local prune window minus a safety margin
  (codify even though 30-day rule window < 90-day prune today).
- Severity high → **medium** until the P1.4 confirmation pipeline exists.

### ⬜ P0.3 AuditTamperRule — severity split + legacy cutoff
Files: `audit_tamper_rule.dart`, `audit_chain_verifier.dart`.
- Severity by worst break reason: own-chain `hashMismatch`/`linkMismatch`/
  `seqGap` → **critical**; `truncatedTail` and foreign-chain `seqGap` →
  **medium** with storage-eviction/sync copy.
- Date-based grandfather cutoff for pre-canonicalization-fix rows: hash
  recompute skipped (reported as informational `legacyHash`), link/seq checks
  still run. Stopgap until P1.3 `hash_version`.
- Description gains per-reason counts so "6 issue(s)" self-explains.

### ⬜ P0.4 One-time reset of the existing FP flags
- New `FraudFlagsDao.bulkDismiss({businessId, ruleCodes, before})`:
  `status='dismissed'`, `resolved_by=<user>`, resolution note
  "Auto-dismissed: 2026-07-03 false-positive incident (see this doc)", for
  `rule_code IN ('AUDIT_TAMPER','ORPHANED_RECORD','TIME_REVERSAL') AND
  status='new' AND detected_at < <fix deploy time>`. Refund-volume and
  control-change flags **stay** (true detections; dismiss manually).
- **Sync-status subtlety:** these rows never reached the server → set
  `sync_status = pendingUpload` (NOT pendingUpdate, whose UPDATE would match 0
  rows and silently lose the record) so the dismissed flag inserts once,
  preserving the forensic record server-side.
- Write one chained audit entry recording the bulk dismissal count.
- Run as a versioned maintenance task (pref key `fraud_maintenance_v1_done`)
  on devices with `fraud.resolve`. **Never `clearAll()`** (hard delete of
  business data). `insertIfNew` dedupes on `(businessId, dedupeKey)` with no
  status filter, so dismissed incidents cannot re-flood.

### ⬜ P0.5 Audit push ordering
Files: `audit_logs_dao.dart:178`, `sync_service.dart`.
- `getPendingSync()` → `ORDER BY device_uid, seq ASC` (unsorted pushes can
  land seq N+1 before N; a mid-cycle failure then leaves a server hole other
  devices verify as `seqGap`).
- On a non-conflict row failure, skip the remaining rows *of that device's
  chain* for the cycle.
- Move `_syncAuditLogs()` **before** `_syncRefunds()` in `syncAll` so audit
  rows land no later than the records they explain.

---

## §4 P1 — Correctness (one Drift bump v54→v55 + Supabase migrations)

### ⬜ P1.1 Drift schema v55 (single bump + onUpgrade + build_runner)
- `audit_outbox` table: `id`, `payload` (JSON: actionType, entityType/Id/Name,
  description, metadata, businessId, branchId, userId, userName, enqueuedAt),
  `attempts`, `lastError`, `createdAt`.
- `fraud_candidates` table (local-only, never synced): `businessId`,
  `ruleCode`, `dedupeKey`, `firstSeenAt`, `lastSeenAt`, `seenCount`,
  `signature` (JSON), `draft` (JSON).
- `audit_logs.hash_version` INT nullable (writer stamps 2; NULL = legacy).
- Optional: `sync_state.last_pull_completed_at` so an idle business still
  advances mirror freshness.

### ⬜ P1.2 Refund→audit atomicity via outbox
Files: `audit_log_service.dart`, `refund_service.dart:190`,
`stock_movement_service.dart`.
- **Not** an in-transaction chained write — `_tail` queue + `insertChained`'s
  own transaction would deadlock on Drift's single executor. Instead:
  `enqueueInTransaction()` inserts a plain outbox row inside the caller's
  refund transaction (businessId/branchId/userId captured at enqueue time);
  `drainOutbox()` funnels FIFO through the existing `_tail`-serialized write
  path, deleting the outbox row in the same transaction as the chained insert.
- Drain triggers: post-commit, app startup, sweep start, before
  `_syncAuditLogs`.
- Remove silent drops: outbox-sourced entries bypass the active-context tenant
  guard (the businessId was captured transactionally — trust it); direct
  `log()` failures log loudly (`[AuditLogService] Error in …: $e\n$st`) and
  the outbox row is retained with `attempts++`/`lastError`, never vanished.

### ⬜ P1.3 Hash canonicalization v2 + `hash_version`
Files: `audit_hash.dart`, `audit_log_service.dart`, `audit_chain_verifier.dart`,
`audit_log_sync_mapper.dart`, `audit_logs_dao.dart`; server migration adds the
column (rollback: drop column).
- v2 canonical form: `''` → NULL for branch/user **at hash time** (make the
  roundtrip invariant explicit, not accidental); entity_id UUID-nulling,
  fixed timestamp format, metadata decode-then-canonical-encode stay.
- Verifier: `hash_version >= 2` → full recompute; NULL/1 → link+seq checks
  only (replaces the P0.3 date cutoff). Existing chain rows are **never
  rewritten**.

### ⬜ P1.4 Confirmation pipeline (flag only on re-observation)
Applies to `ORPHANED_RECORD`, `AUDIT_TAMPER`, `TIME_REVERSAL`; event-shaped
rules (EXCESSIVE_REFUNDS etc.) stay immediate.
- Draft → upsert into `fraud_candidates` keyed `(businessId, dedupeKey)` with
  a rule-specific stable `signature` (orphan: record id + watermark; tamper:
  `uid|reason|seq|expected|actual`).
- Promote to a real flag only when: `seenCount >= 2`, sightings ≥30 min apart,
  signature unchanged, **and** ≥1 successful audit pull between sightings.
- Candidates that stop matching (audit row arrived; hash verifies) are deleted
  silently — auto-resolution *before* any user-visible noise.

### ⬜ P1.5 Branch scoping + device identity on alerts (the "All branches" fix)
Files: `audit_chain_verifier.dart`, `audit_tamper_rule.dart`,
`fraud_cubit.dart:172-174`, `device_identity_service.dart`,
`device_info_service.dart`.
- Verifier reports `Set<String> branchIds` per device (distinct non-empty
  `branch_id` over the broken rows; fallback: whole retained chain).
- Rule: exactly one branch → set `draft.branchId` (**decision D4** — the flag
  becomes branch-manager-visible under existing RLS); several → keep NULL but
  list branch names in description + `evidence['affected_branches']`.
- Alerts show the device short-uid: `"Web · chrome (b318a37a)"`. Cubit renders
  'All branches' only when there is genuinely no branch info.
- Label stability: persist the first-resolved label next to the uid
  (`device_chain_label` pref in `DeviceIdentityService`, written at
  mint/rotate) so one uid keeps one label for life. (Superseded by the
  `devices` table in §4c when that lands.)

### ⬜ P1.6 Web storage-eviction detection
- localStorage sentinel `last_local_head_seq:<businessId>` updated after each
  chained write. On startup, local DB head < sentinel ⇒ IndexedDB was evicted
  independently of localStorage ⇒ verifier tags this device's `truncatedTail`
  as a new `storageLoss` reason (low/medium, distinct copy).
- Call `navigator.storage.persist()` once on web (conditional import).

### ⬜ P1.7 Server-side authoritative orphan check (recommended in P1 — D3)
- Migration: `get_unaudited_record_ids(p_ids uuid[], p_kind text)` SECURITY
  DEFINER, permission-gated, returns the subset with no matching server-side
  audit row (action_type-filtered). Rollback: `DROP FUNCTION`.
- Candidate promotion consults it when online — server truth overrides the
  local mirror **both ways** (present server-side → delete candidate; absent →
  promote immediately). Offline falls back to P1.4 rules. Detection still
  originates locally, so offline-first is preserved.

### ⬜ P1.8 TimeReversalRule re-chain awareness
- `reconcileConflictedTail` already recomputes seq/prev_hash/entry_hash via
  `rewriteChainRow` — additionally stamp `_rechained: true` into each
  rewritten row's metadata (re-hashed anyway, chain stays valid) and write one
  chained `AUDIT_CHAIN_RECONCILED` entry recording the seq range.
- `TimeReversalRule` skips pairs whose later row carries the marker, and skips
  block-transplant signatures (regression at the boundary, but the following
  rows internally time-ordered + contiguous).
- Route through the P1.4 confirmation pipeline; record the server↔client clock
  offset at each sync (in `sync_state`) to distinguish genuine manipulation
  from clock correction.

### ⬜ P1.9 Single-writer guard per device_uid
- Confirm how two instances shared uid `b318a37a` (two tabs of one browser
  with separate in-memory heads? identity fallback? label flap masking one
  browser?) — `device_identity_service.dart` + drift-web multi-tab behavior.
- Web: acquire a `navigator.locks` (or localStorage lease) named by the uid
  before chained writes; a second instance waits or rotates to its own uid.
- Regression test for concurrent `log()` from two service instances.

### ⬜ P1.10 Stop audit meta-noise
- `FRAUD_FLAG_RAISED` must not be one chained entry per flag: batch per sweep
  (one entry, flag count + rule codes in metadata) or exclude sweep-generated
  flags from chained logging entirely (flags are already synced evidence).

---

## §4c Normalization & scalability workstream

Coordinate with P1.3 — device label / description / metadata sit **inside the
hashed payload**, so shape changes apply to v2+ rows only; legacy rows are
never touched.

- ⬜ **`devices` table** (Drift + Supabase migration): `device_uid` PK,
  `business_id`, stable `label`, `platform`, `first_seen_at`, `last_seen_at`.
  `audit_logs.device_uid` becomes the FK; v2 rows stop writing the per-row
  `device_id` label (column kept nullable for legacy). This is the P1.5
  label fix done properly, deduplicates the label from every audit row, and
  gives alerts a canonical device name + short-uid.
- ⬜ **Derived descriptions**: v2 rows stop storing prose `description`;
  render from `action_type` + `metadata` via a template registry (i18n-ready,
  smaller rows, no drift between description and metadata). Canonical payload
  v2 drops `description`.
- ⬜ **Indexes** (local Drift + server migration): `audit_logs`
  `(business_id, created_at)`, `(entity_id)` (feeds the orphan NOT EXISTS),
  `(business_id, action_type, created_at)` (feeds control rules); server
  already has unique `(business_id, device_uid, seq)`. `fraud_flags`:
  `(business_id, status, detected_at)`, `(business_id, rule_code)`.
- ⬜ **Constrain enums**: server CHECK on `audit_logs.action_type` and
  `fraud_flags.rule_code` (severity/status already checked).
- **Out of scope**: relationalizing `metadata`/`evidence` jsonb — flexible-by-
  design payloads, premature at current volume.

---

## §5 P2 — Production hardening

- ⬜ `false_positive` flag status: server CHECK extension (rollback: restore
  4-value CHECK) + client enum/UI; feeds FP-rate tuning per rule.
- ⬜ Tamper digest: dedupe key `AUDIT_TAMPER|<deviceUid>|<localDay>` — max one
  flag per device per day (flags are immutable; day-scoped dedupe is the
  compatible "update in place"); break detail stays in evidence.
- ⬜ CONTROL_CHANGE digest: bulk permission grants by one actor within a short
  window collapse into one flag listing the keys (the 45-override burst
  produced several separate flags).
- ⬜ Per-business configurable thresholds for EXCESSIVE_REFUNDS / structuring
  (fraud settings page gated by existing fraud permissions; fixed floors stay
  as minimums).
- ⬜ Business-wide alerts (CONTROL_CHANGE, multi-branch tamper) display
  **"Business-wide"** instead of "All branches" and show the target employee's
  assigned branches from `employee_branches`.
- ⬜ Sweep observability: bounded local sweep log (rules run, drafts,
  inserted, candidates pending/promoted/expired, watermark, duration) +
  `_debug` entry in every flag's evidence (engine version, watermark at
  detection, grace values); collapsed Diagnostics section gated by
  `fraud.view`.
- ⬜ Audit push cap pagination (drain long offline backlogs fully) + immediate
  re-push after `reconcileConflictedTail`.
- ⬜ Update `UPSENSO_FRAUD_AND_AUDIT_CHAIN_DESIGN.md` (canonicalization v2,
  outbox, confirmation pipeline, devices table).
- ⬜ Regression tests: canonical v2 roundtrip (`''`↔NULL, legacy
  double-encoded metadata, non-uuid entity_id), verifier hash_version gating,
  orphan freshness-gate boundaries (watermark null/behind/ahead), candidate
  promotion state machine, outbox drain idempotency + crash-window replay,
  `bulkDismiss` sync-status routing, fraud mapper jsonb symmetry,
  time-reversal re-chain skip, single-writer lock.

---

## §6 Sequencing + decision points

Sequencing:
- **Prerequisite: commit the uncommitted M1 working tree** (build provenance
  is the first P0.1 question).
- P0 ships as **one hotfix build**; P0.4's dismissal cutoff = that build's
  deploy time. P0.2's freshness gate and subquery scoping land together.
- P1.1 (schema) gates P1.2–P1.4. P1.3's server migration is additive and can
  go first. Nothing ever rewrites existing chain rows.
- A re-sweep after fixes does **not** auto-clear old flags (immutable +
  dedupe) — P0.4 is the reset; P1.4 is what prevents future noise.

Decisions to confirm with the owner (recommendations recorded):
- **D1** Reset scope: dismiss only `AUDIT_TAMPER`/`ORPHANED_RECORD`/
  `TIME_REVERSAL` flags predating the fix build. *(recommended)*
- **D2** Push dismissed FP flags to the server for the forensic record.
  *(recommended: yes)*
- **D3** P1.7 server RPC in P1 rather than P2. *(recommended: P1)*
- **D4** Deriving `branchId` makes tamper flags visible to that branch's
  manager (today: owner-only via NULL-branch RLS). Intended, but changes who
  sees critical alerts — needs explicit sign-off.
- **D5** Normalization timing: `devices` table + indexes ride P1 (same
  hash-v2 payload change); derived descriptions may slip to P2.

## Key files

`lib/core/services/fraud_rules/rules/orphaned_record_rule.dart` ·
`audit_tamper_rule.dart` · `time_reversal_rule.dart` ·
`control_change_rule.dart` · `excessive_refunds_rule.dart` ·
`lib/core/services/fraud_detection_engine.dart` ·
`lib/core/audit/audit_log_service.dart` · `audit_chain_verifier.dart` ·
`audit_hash.dart` · `lib/core/database/daos/audit_logs_dao.dart` ·
`fraud_flags_dao.dart` · `lib/core/database/tables/audit_logs_table.dart` ·
`lib/core/sync/sync_service.dart` ·
`lib/features/alert/data/datasources/fraud_flags_remote_ds.dart` ·
`lib/features/alert/presentation/cubit/fraud_cubit.dart` ·
`lib/core/device/device_identity_service.dart` · `device_info_service.dart` ·
`supabase/migrations/20260703000002_audit_chain_columns.sql` ·
`20260703000003_fraud_flags.sql`
