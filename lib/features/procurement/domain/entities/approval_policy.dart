/// Resolves PO approval governance: instant-approve when authorized, with
/// separation-of-duties only above a per-business threshold.
///
/// Rules:
///  - Owners always have ultimate authority (no separation, no solo-founder
///    dead-end).
///  - A null threshold means "unset" → approvers may self-approve any amount
///    (startup-friendly default).
///  - When a threshold is set, a non-owner approver cannot approve their own PO
///    above it — a different approver is required.
abstract final class ApprovalPolicy {
  /// True when the order needs an approver different from its creator.
  static bool requiresSeparateApprover({
    required double total,
    required double? threshold,
    required bool actorIsOwner,
  }) {
    if (actorIsOwner) return false;
    if (threshold == null) return false;
    return total > threshold;
  }

  /// True when the creator may approve the PO immediately (one tap) instead of
  /// routing it for someone else's approval.
  static bool canInstantApprove({
    required bool canApprove,
    required double total,
    required double? threshold,
    required bool actorIsOwner,
  }) {
    if (!canApprove) return false;
    return !requiresSeparateApprover(
      total: total,
      threshold: threshold,
      actorIsOwner: actorIsOwner,
    );
  }
}
