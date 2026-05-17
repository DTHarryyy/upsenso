import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/widgets/branch_action_dialog.dart';

export 'package:pos/core/widgets/branch_action_dialog.dart'
    show BranchSelection;

/// Backward-compatible sale-specific wrapper around the shared branch picker.
Future<BranchSelection?> showBranchSaleDialog(BuildContext context) {
  return showBranchActionDialog(
    context,
    title: 'Select Branch',
    description:
        "You're currently viewing all branches. Choose where to record this sale:",
    confirmPrefix: 'Confirm',
    icon: IconlyLight.work,
    emptyTitle: 'No branches available',
    emptyMessage: 'Please add a branch before making a sale.',
    selectLabel: 'Select a Branch',
  );
}
