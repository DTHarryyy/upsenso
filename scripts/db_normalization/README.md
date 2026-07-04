# DB Normalization — Migration Sketches (REVIEW ONLY)

These `phase{1..5}_*.sql` files are **sketches for review, produced by the audit**
in [docs/UPSENSO_DB_ARCHITECTURE_AUDIT.md](../../docs/UPSENSO_DB_ARCHITECTURE_AUDIT.md).
**Nothing here has been applied.** They are the concrete form of Deliverable C
(migration plan). Do not run any of them without:

1. A fresh backup (prod is LIVE, Free plan = no PITR).
2. Turning each into a real timestamped `supabase/migrations/*.sql` file.
3. The matching **Drift** change (`app_database.dart` schemaVersion bump +
   `onUpgrade` step + sync mapper) in the **same** release — server-only changes
   desync offline clients.
4. Re-running `tool/schema_audit.sql` before/after to prove the issue count dropped.

Every file follows the project's safety protocol: **additive → backfill → verify →
drop**, never a bare destructive DDL, and each carries a rollback. FKs are added
`NOT VALID` then `VALIDATE` separately (live-Postgres pattern).

Order: phase1 (low-risk) → phase2 (FKs) → phase3 (constraints/conventions) →
phase4 (audit_logs + anomaly, hash-coordinated) → phase5 (cleanup).

⚠️ Phase 4 changes the audit hash canonical form → **coordinate an
`audit_hash.dart` version bump**; it affects sync + tamper-evidence.
