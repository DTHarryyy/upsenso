import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/services/fraud_rules/fraud_flag_draft.dart';

/// Hardcoded default floors — deliberately NOT stored in an editable
/// settings table for v1: an editable threshold is itself an insider attack
/// surface (whoever can raise it desensitizes detection silently). The
/// adaptive part comes from RobustBaseline, which has no knob to turn.
/// An owner tuning UI is a Phase 3 item, audit-logged and CONTROL_CHANGE-
/// watched when it lands.
abstract final class FraudDefaults {
  // Refunds
  static const int excessiveRefundCountPerDay = 5;
  static const double excessiveRefundValuePerDay = 5000; // ₱, per employee/day
  static const int structuringCount7d = 3;
  static const double structuringBandLow = 0.70; // 70–100% of approval threshold
  static const int quickRefundSeconds = 15 * 60;

  // Discounts
  static const double highDiscountRatio = 0.30;

  // Inventory
  static const double shrinkageValuePerDay = 3000; // ₱ cost-weighted, per branch/day

  // Audit / control plane
  static const int timeReversalToleranceSeconds = 300;
  static const int probingDenialsPerDay = 6;
  static const int probingDistinctPerms = 3;
  static const int orphanGraceSeconds = 10 * 60;

  /// Permissions whose grant via override is itself a signal (client mirror
  /// of the server's is_dangerous notion).
  static const Set<String> sensitiveOverrideKeys = {
    'fraud.view',
    'fraud.resolve',
    'settings.edit_business',
    'audit_logs.view',
    'audit_logs.verify',
    'audit_logs.delete',
    'pos.approve_refund',
    'pos.refund_sale',
    'employees.assign_role',
    'data.cross_branch_access',
  };

  // Baselines
  static const int baselineMinSamples = 14; // ~2 weeks of daily aggregates
  static const double baselineK = 4.0;
  static const double baselineMinSpreadValue = 500; // ₱ for money series
  static const double baselineMinSpreadCount = 2; // for count series

  /// Cap per rule per sweep — a reconnecting device replaying weeks of
  /// history must not storm the feed; the overflow becomes one summary flag.
  static const int maxNewFlagsPerRulePerSweep = 15;
}

/// One deterministic detection rule. Rules are pure reads over local Drift
/// data returning drafts — the engine owns dedupe, persistence, owner
/// suppression, and audit logging. Constructor-inject heavier dependencies
/// (e.g. the chain verifier); everything else comes from the context.
abstract class FraudRule {
  String get code;

  /// True when the rule can only produce correct results on a device holding
  /// the FULL audit mirror (audit pull is owner-only) — e.g. cross-checking
  /// business records against audit entries would false-positive on a
  /// cashier device that never pulls other devices' audit rows.
  bool get requiresFullAuditMirror => false;

  Future<List<FraudFlagDraft>> evaluate(FraudScanContext ctx);
}

/// Everything a rule needs to run one scan.
class FraudScanContext {
  final AppDatabase db;
  final String businessId;

  /// Scan window start. Periodic sweeps ALWAYS use the full trailing window
  /// (no persisted watermark — a watermark would itself be a tamper target,
  /// T12); post-commit incremental runs pass a short recent window.
  final DateTime windowStart;

  /// Injectable "now" so boundary tests are deterministic.
  final DateTime now;

  /// The business owner's user id (owner-as-subject flags get downgraded —
  /// the threat model trusts the owner; their own inventory day must not
  /// spam the feed).
  final String? ownerUserId;

  /// How fresh the LOCAL audit mirror is: the created_at of the last audit
  /// row pulled from the server for this business (the audit_logs delta-sync
  /// watermark). Null when the mirror was never pulled. Rules that treat
  /// "no local audit row" as evidence (ORPHANED_RECORD) must not judge a
  /// record newer than this — the audit row may simply not have arrived yet.
  /// This is the freshness signal missing on 2026-07-03: refunds synced to
  /// the sweeping device before their audit rows did.
  final DateTime? auditMirrorFreshAt;

  const FraudScanContext({
    required this.db,
    required this.businessId,
    required this.windowStart,
    required this.now,
    this.ownerUserId,
    this.auditMirrorFreshAt,
  });

  int get windowStartUnix => windowStart.toUtc().millisecondsSinceEpoch ~/ 1000;
  int get nowUnix => now.toUtc().millisecondsSinceEpoch ~/ 1000;

  /// Mirror freshness as unix seconds, or null when never pulled.
  int? get auditMirrorFreshUnix => auditMirrorFreshAt == null
      ? null
      : auditMirrorFreshAt!.toUtc().millisecondsSinceEpoch ~/ 1000;
}

/// Local-calendar day (yyyy-MM-dd), matching SQLite's
/// DATE(..,'unixepoch','localtime') buckets. Businesses operate in the
/// device's local zone (PH = UTC+8); UTC days would split their evenings.
String localDayString(DateTime dt) {
  final l = dt.toLocal();
  final m = l.month.toString().padLeft(2, '0');
  final d = l.day.toString().padLeft(2, '0');
  return '${l.year}-$m-$d';
}
