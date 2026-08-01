import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/fraud_candidates_dao.dart';
import 'package:pos/core/database/daos/fraud_flags_dao.dart';
import 'package:pos/core/database/daos/sync_state_dao.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/services/fraud_rules/fraud_flag_draft.dart';
import 'package:pos/core/services/fraud_rules/fraud_rule.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

/// Runs the deterministic fraud rules over local Drift data and persists
/// deduplicated fraud_flags. Entirely offline; flags sync like any entity.
///
/// Hardening properties (see the M1 design):
/// - No persisted sweep watermark: the periodic sweep ALWAYS rescans the full
///   trailing window, so deleting a flag locally just gets it re-detected and
///   advancing a stored cursor isn't possible — there is none (T8/T12).
/// - Runs regardless of the `audit` module gate — the gate hides UI, it is
///   not a detection kill switch (T7).
/// - Owner-as-subject drafts are downgraded, not dropped: the threat model
///   trusts the owner, but the record stays.
/// - Every NEW flag writes a chained audit entry, so suppressing the flag
///   before it syncs still leaves a tamper-evident hole (T8).
/// - The owner's device is the authoritative sweeper: it is the only device
///   that pulls the full audit mirror, so a compromised device can at most
///   suppress its own self-reporting, never veto detection of synced data.
class FraudDetectionEngine {
  final AppDatabase _db;
  final FraudFlagsDao _flagsDao;
  final FraudCandidatesDao _candidatesDao;
  final SyncStateDao _syncStateDao;
  final AuditLogService _auditLogService;
  final PermissionService _permissionService;
  final ActiveBusinessContext _activeBusinessContext;
  final List<FraudRule> _rules;

  static const _uuid = Uuid();

  /// Incremental post-commit runs look at recent data only; correctness does
  /// not depend on this — the periodic full sweep re-covers everything.
  static const Duration incrementalWindow = Duration(hours: 48);
  static const Duration fullWindow = Duration(days: 30);

  /// Rules whose false positives come from a STALE local mirror rather than
  /// real events (see docs/UPSENSO_FRAUD_FALSE_POSITIVE_FIX_PLAN.md). Their
  /// drafts must be re-observed across sweeps before becoming a user-visible
  /// flag — a first sighting that resolves itself (audit row arrives, hash
  /// verifies) never reaches the feed.
  static const Set<String> confirmationRules = {
    'ORPHANED_RECORD',
    'AUDIT_TAMPER',
    'TIME_REVERSAL',
  };

  /// Of the confirmation rules, the ones whose evidence depends on the audit
  /// mirror being current — promotion additionally requires a fresh audit
  /// pull between sightings (so a slow mirror can only delay, never flag).
  static const Set<String> mirrorDependentRules = {'ORPHANED_RECORD'};

  /// A candidate must be seen at least twice, with sightings at least this far
  /// apart, before it is promoted to a flag.
  static const Duration confirmationMinGap = Duration(minutes: 30);
  static const int confirmationMinSightings = 2;

  bool _running = false;

  FraudDetectionEngine({
    required AppDatabase db,
    required FraudFlagsDao flagsDao,
    required FraudCandidatesDao candidatesDao,
    required SyncStateDao syncStateDao,
    required AuditLogService auditLogService,
    required PermissionService permissionService,
    required ActiveBusinessContext activeBusinessContext,
    required List<FraudRule> rules,
  })  : _db = db,
        _flagsDao = flagsDao,
        _candidatesDao = candidatesDao,
        _syncStateDao = syncStateDao,
        _auditLogService = auditLogService,
        _permissionService = permissionService,
        _activeBusinessContext = activeBusinessContext,
        _rules = rules;

  /// Full periodic sweep (all rules, trailing 30 days). Safe to call often;
  /// overlapping calls coalesce.
  Future<void> runSweep() => _run(null, fullWindow);

  /// Cheap post-commit run of just the rules relevant to what committed.
  Future<void> runIncremental(Set<String> ruleCodes) =>
      _run(ruleCodes, incrementalWindow);

  Future<void> _run(Set<String>? onlyRules, Duration window) async {
    if (_running) return;
    _running = true;
    try {
      final businessId = _activeBusinessContext.businessId;
      if (businessId == null || businessId.isEmpty) return;

      // Drain any staged audit entries first, so the sweeping device never
      // races its own outbox — a refund's audit row must be materialized
      // before ORPHANED_RECORD looks for it.
      await _auditLogService.drainOutbox();

      final now = DateTime.now();
      // Scope every rule to activity AFTER M1 first ran on this business, so
      // the first-ever sweep doesn't retroactively flag months-old refunds/
      // discounts an owner can't act on. The M1 cutoff = the earliest chained
      // audit row (same "chain era" ORPHANED_RECORD already keys off).
      var windowStart = now.subtract(window);
      final m1Cutoff = await _m1Cutoff(businessId);
      if (m1Cutoff != null && m1Cutoff.isAfter(windowStart)) {
        windowStart = m1Cutoff;
      }
      final ctx = FraudScanContext(
        db: _db,
        businessId: businessId,
        windowStart: windowStart,
        now: now,
        ownerUserId: await _ownerUserId(businessId),
        auditMirrorFreshAt: await _auditMirrorFreshAt(businessId),
      );
      // Cross-checking records against audit entries needs the full audit
      // mirror, which only audit-viewing (owner) devices pull.
      final hasFullMirror =
          _permissionService.can(PermissionKeys.auditLogsView);

      // Collect every flag raised this sweep, then write ONE chained audit
      // entry (below) instead of one per flag — the fraud engine must not
      // flood its own tamper-evidence trail (60+ of 111 chain rows were
      // FRAUD_FLAG_RAISED on 2026-07-03).
      final raised = <FraudFlagDraft>[];

      // Only a FULL sweep sees every current incident, so only a full sweep
      // may conclude that an unseen candidate resolved itself.
      final fullSweep = onlyRules == null;

      for (final rule in _rules) {
        if (onlyRules != null && !onlyRules.contains(rule.code)) continue;
        if (rule.requiresFullAuditMirror && !hasFullMirror) continue;
        try {
          final drafts = await rule.evaluate(ctx);
          // Null = the rule had no basis to judge (gated / mirror never
          // pulled) — leave its candidates exactly as they were.
          if (drafts == null) continue;
          await _persist(ctx, rule.code, drafts, raised, fullSweep: fullSweep);
        } catch (e, st) {
          debugPrint('[FraudEngine] Error in rule ${rule.code}: $e\n$st');
        }
      }

      if (raised.isNotEmpty) _logRaisedBatch(ctx, raised);
    } catch (e, st) {
      debugPrint('[FraudEngine] Error in sweep: $e\n$st');
    } finally {
      _running = false;
    }
  }

  Future<void> _persist(
    FraudScanContext ctx,
    String ruleCode,
    List<FraudFlagDraft> drafts,
    List<FraudFlagDraft> raised, {
    required bool fullSweep,
  }) async {
    // Confirmation-gated rules stage drafts as candidates and only promote
    // the ones that survive re-observation; everything else flags immediately.
    final List<FraudFlagDraft> toFlag;
    if (confirmationRules.contains(ruleCode)) {
      toFlag = await _confirm(ctx, ruleCode, drafts, pruneStale: fullSweep);
    } else {
      toFlag = drafts;
    }

    var inserted = 0;
    var overflow = 0;
    for (var draft in toFlag) {
      if (draft.subjectUserId != null &&
          draft.subjectUserId == ctx.ownerUserId) {
        draft = draft.copyWith(
          severity: FraudSeverity.low,
          evidence: [
            ...draft.evidence,
            {
              'fact': 'Subject is the business owner',
              'value': 'severity downgraded — owners are trusted actors',
            },
          ],
        );
      }

      // Post-offline storm guard: a device replaying weeks of history must
      // not flood the feed — the tail collapses into one summary flag.
      if (inserted >= FraudDefaults.maxNewFlagsPerRulePerSweep) {
        overflow++;
        continue;
      }

      final isNew = await _flagsDao.insertIfNew(_companion(ctx, draft));
      if (!isNew) continue;
      inserted++;
      raised.add(draft);
    }

    if (overflow > 0) {
      final day = localDayString(ctx.now);
      final summary = FraudFlagDraft(
        ruleCode: ruleCode,
        severity: FraudSeverity.medium,
        title: 'Additional $ruleCode detections',
        description:
            '$overflow further $ruleCode detection(s) in this sweep were '
            'grouped into this summary to keep the feed readable. Re-open '
            'the period in reports for the full picture.',
        dedupeKey: '$ruleCode|aggregate|$day',
        detectedAt: ctx.now,
      );
      if (await _flagsDao.insertIfNew(_companion(ctx, summary))) {
        raised.add(summary);
      }
    }
  }

  /// Confirm-before-flag: returns the subset of [drafts] that have now been
  /// observed enough (≥[confirmationMinSightings] sightings ≥[confirmationMinGap]
  /// apart with a stable signature, plus a fresh audit pull for
  /// mirror-dependent rules). First sightings become candidates; candidates
  /// that stopped matching this sweep are deleted — silent auto-resolution
  /// before any noise reaches the feed.
  Future<List<FraudFlagDraft>> _confirm(
    FraudScanContext ctx,
    String ruleCode,
    List<FraudFlagDraft> drafts, {
    required bool pruneStale,
  }) async {
    final promoted = <FraudFlagDraft>[];
    final seenKeys = <String>{};
    final requiresMirrorAdvance = mirrorDependentRules.contains(ruleCode);

    for (final draft in drafts) {
      seenKeys.add(draft.dedupeKey);
      final signature = _signatureFor(draft);
      final existing =
          await _candidatesDao.getByKey(ctx.businessId, draft.dedupeKey);

      if (existing == null || existing.signature != signature) {
        // First sighting, or the observation changed — (re)start confirmation.
        await _candidatesDao.insertCandidate(
          businessId: ctx.businessId,
          dedupeKey: draft.dedupeKey,
          ruleCode: ruleCode,
          signature: signature,
          seenAt: ctx.now,
          watermark: ctx.auditMirrorFreshAt,
        );
        continue;
      }

      await _candidatesDao.incrementSighting(
        businessId: ctx.businessId,
        dedupeKey: draft.dedupeKey,
        seenAt: ctx.now,
      );

      final enoughSightings =
          existing.seenCount + 1 >= confirmationMinSightings;
      final enoughGap =
          ctx.now.difference(existing.firstSeenAt) >= confirmationMinGap;
      final mirrorAdvanced = !requiresMirrorAdvance ||
          _mirrorAdvancedSince(existing.watermarkAtFirstSeen, ctx);

      if (enoughSightings && enoughGap && mirrorAdvanced) {
        promoted.add(draft);
        await _candidatesDao.deleteByKey(ctx.businessId, draft.dedupeKey);
      }
    }

    // Candidates of this rule not re-observed this sweep resolved themselves
    // (the audit row arrived, the hash now verifies) — drop them silently.
    // Only a FULL sweep saw all current data, so only it may conclude that;
    // an incremental window not covering an old incident is not resolution.
    if (pruneStale) {
      await _candidatesDao.deleteStale(
        businessId: ctx.businessId,
        ruleCode: ruleCode,
        keepKeys: seenKeys,
      );
    }

    return promoted;
  }

  /// The mirror pulled fresh audit rows since the candidate's first sighting.
  bool _mirrorAdvancedSince(DateTime? firstWatermark, FraudScanContext ctx) {
    final now = ctx.auditMirrorFreshAt;
    if (now == null) return false;
    if (firstWatermark == null) return true; // had no baseline; any pull counts
    return now.isAfter(firstWatermark);
  }

  /// Stable fingerprint of an observation — a changed signature means a
  /// genuinely different sighting and restarts confirmation. Rules whose
  /// evidence embeds values that move between sweeps (chain head positions,
  /// counts) provide an explicit [FraudFlagDraft.confirmationSignature];
  /// falling back to the raw evidence for the rest.
  String _signatureFor(FraudFlagDraft draft) =>
      draft.confirmationSignature ?? jsonEncode(draft.evidence);

  /// The audit_logs delta-sync watermark = how recent the pulled mirror is.
  Future<DateTime?> _auditMirrorFreshAt(String businessId) async {
    try {
      final w = await _syncStateDao.getWatermark('audit_logs', businessId);
      return w.ts;
    } catch (e, st) {
      debugPrint('[FraudEngine] Error resolving mirror watermark: $e\n$st');
      return null;
    }
  }

  /// Bumped when detection semantics change — lets a future investigator tell
  /// which engine produced a flag (evidence `_debug.engine`).
  static const int engineVersion = 2;

  FraudFlagsTableCompanion _companion(
    FraudScanContext ctx,
    FraudFlagDraft d,
  ) {
    // A machine-readable diagnostics footer on every flag: the engine version,
    // how fresh the audit mirror was at detection, and the grace window. Makes
    // a later "was this a false positive?" answerable from the flag alone.
    final evidence = [
      ...d.evidence,
      {
        'fact': '_debug',
        'value': {
          'engine': engineVersion,
          'mirror_fresh_at':
              ctx.auditMirrorFreshAt?.toUtc().toIso8601String(),
          'orphan_grace_seconds': FraudDefaults.orphanGraceSeconds,
          'detected_at': ctx.now.toUtc().toIso8601String(),
        },
      },
    ];
    return FraudFlagsTableCompanion.insert(
      id: _uuid.v4(),
      businessId: ctx.businessId,
      branchId: Value(d.branchId),
      ruleCode: d.ruleCode,
      severity: d.severity,
      title: d.title,
      description: d.description,
      subjectUserId: Value(d.subjectUserId),
      evidence: Value(jsonEncode(evidence)),
      relatedIds: Value(jsonEncode(d.relatedIds)),
      detectedAt: d.detectedAt,
      dedupeKey: d.dedupeKey,
    );
  }

  /// One chained trace per SWEEP, not per flag — deleting a local flag row
  /// still can't hide that it was raised (its dedupe key is listed here), but
  /// the fraud engine no longer floods its own tamper-evidence chain with a
  /// row per detection (the 2026-07-03 meta-noise).
  void _logRaisedBatch(FraudScanContext ctx, List<FraudFlagDraft> raised) {
    final worst = _worstSeverity(raised);
    _auditLogService.log(
      actionType: AuditLogActionType.fraudFlagRaised,
      entityType: 'fraud_flag',
      description:
          '${raised.length} unusual-activity alert(s) raised this sweep [worst: '
          '${worst.toUpperCase()}]',
      metadata: {
        'count': raised.length,
        'worst_severity': worst,
        'flags': [
          for (final d in raised)
            {
              'rule_code': d.ruleCode,
              'severity': d.severity,
              'dedupe_key': d.dedupeKey,
              if (d.subjectUserId != null) 'subject_user_id': d.subjectUserId,
            },
        ],
      },
      businessId: ctx.businessId,
    );
  }

  static String _worstSeverity(List<FraudFlagDraft> drafts) {
    const order = {
      FraudSeverity.low: 0,
      FraudSeverity.medium: 1,
      FraudSeverity.high: 2,
      FraudSeverity.critical: 3,
    };
    var worst = FraudSeverity.low;
    for (final d in drafts) {
      if ((order[d.severity] ?? 0) > (order[worst] ?? 0)) worst = d.severity;
    }
    return worst;
  }

  /// When M1 first ran on this business = the earliest chained audit row.
  /// Null when the chain era hasn't started (no seq-bearing rows yet).
  Future<DateTime?> _m1Cutoff(String businessId) async {
    try {
      final row = await _db
          .customSelect(
            'SELECT MIN(created_at) AS c FROM audit_logs '
            'WHERE business_id = ? AND seq IS NOT NULL',
            variables: [Variable.withString(businessId)],
          )
          .getSingleOrNull();
      final unix = row?.readNullable<int>('c');
      return unix == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    } catch (e, st) {
      debugPrint('[FraudEngine] Error resolving M1 cutoff: $e\n$st');
      return null;
    }
  }

  Future<String?> _ownerUserId(String businessId) async {
    try {
      final row = await _db
          .customSelect(
            'SELECT owner_id FROM businesses WHERE id = ? LIMIT 1',
            variables: [Variable.withString(businessId)],
          )
          .getSingleOrNull();
      return row?.readNullable<String>('owner_id');
    } catch (e, st) {
      debugPrint('[FraudEngine] Error resolving owner: $e\n$st');
      return null;
    }
  }
}
