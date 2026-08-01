/// Why a branch create did or didn't happen.
///
/// `addBranch` used to return a bare `String?`, so a permission denial, a plan
/// cap and a server rejection were all indistinguishable `null`s — which is why
/// the caller had to re-run `canAddAnother` afterwards just to guess which one
/// it had hit.
enum AddBranchOutcome {
  created,

  /// The role (or a per-employee override) doesn't allow managing branches.
  notPermitted,

  /// The plan's branch cap is already reached — this is the upgrade moment.
  capReached,

  /// The server refused the insert. Distinct from [capReached] only in that we
  /// learned it late; the local row has been rolled back either way.
  rejectedByServer,
}

class AddBranchResult {
  final AddBranchOutcome outcome;

  /// The new branch id, set only when [outcome] is [AddBranchOutcome.created].
  final String? branchId;

  const AddBranchResult(this.outcome, {this.branchId});

  const AddBranchResult.created(String id)
    : outcome = AddBranchOutcome.created,
      branchId = id;

  bool get isCreated => outcome == AddBranchOutcome.created;

  /// Both cap outcomes want the same upsell — one was caught locally, the
  /// other by the server, and the merchant doesn't care which.
  bool get isCapped =>
      outcome == AddBranchOutcome.capReached ||
      outcome == AddBranchOutcome.rejectedByServer;
}
