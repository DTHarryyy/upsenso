/// Severity levels for fraud flags — string values match the fraud_flags
/// CHECK constraint on both Drift and Supabase.
abstract final class FraudSeverity {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';
}

/// A detection produced by a [FraudRule] — pure data, not yet persisted.
/// The engine dedupes drafts (by [dedupeKey]) and writes fraud_flags rows.
class FraudFlagDraft {
  final String ruleCode;
  final String severity;
  final String title;
  final String description;
  final String? branchId;

  /// auth.uid() of the implicated employee (same id space as
  /// transactions.cashier_id / refunds.refunded_by); null when no single
  /// subject. Drives the server-side self-resolution block.
  final String? subjectUserId;

  /// Structured factors: {fact, value, baseline?, window?}. Human-readable
  /// values — flags are investigable leads, never verdicts.
  final List<Map<String, Object?>> evidence;

  /// Ids of the source records (transactions / refunds / ledger / audit rows).
  final List<String> relatedIds;

  /// EVENT time (when the suspicious activity happened), not detection time —
  /// a device sweeping after weeks offline must not present old incidents
  /// as new ones.
  final DateTime detectedAt;

  /// Deterministic per-incident key — every device and every re-sweep derives
  /// the same key for the same incident, so flags converge instead of
  /// duplicating (unique per business on both Drift and Supabase).
  final String dedupeKey;

  /// Stable identity of the OBSERVATION for the confirm-before-flag pipeline.
  /// The engine falls back to the raw evidence when null — fine for rules
  /// whose evidence is already stable, but evidence that embeds moving values
  /// (chain head positions, growing counts) would restart confirmation on
  /// every sweep and the flag would never surface. Such rules must set this
  /// to the parts of the observation that identify it, nothing more.
  final String? confirmationSignature;

  const FraudFlagDraft({
    required this.ruleCode,
    required this.severity,
    required this.title,
    required this.description,
    required this.dedupeKey,
    required this.detectedAt,
    this.branchId,
    this.subjectUserId,
    this.evidence = const [],
    this.relatedIds = const [],
    this.confirmationSignature,
  });

  FraudFlagDraft copyWith({
    String? severity,
    List<Map<String, Object?>>? evidence,
  }) {
    return FraudFlagDraft(
      ruleCode: ruleCode,
      severity: severity ?? this.severity,
      title: title,
      description: description,
      dedupeKey: dedupeKey,
      detectedAt: detectedAt,
      branchId: branchId,
      subjectUserId: subjectUserId,
      evidence: evidence ?? this.evidence,
      relatedIds: relatedIds,
      confirmationSignature: confirmationSignature,
    );
  }
}
