/// Per-business procurement configuration.
///
/// [approvalThreshold] null = unset → approvers may self-approve any amount.
/// When set, POs above it require a separate approver (see ApprovalPolicy).
class ProcurementSettings {
  final String businessId;
  final double? approvalThreshold;

  const ProcurementSettings({
    required this.businessId,
    this.approvalThreshold,
  });
}
