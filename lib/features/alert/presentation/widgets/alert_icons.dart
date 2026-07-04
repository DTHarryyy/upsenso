import 'package:flutter/widgets.dart';
import 'package:iconly/iconly.dart';

/// Icon per rule code — unknown/future rules fall back to a generic shield.
IconData alertIconFor(String ruleCode) {
  switch (ruleCode) {
    case 'EXCESSIVE_REFUNDS':
    case 'REFUND_STRUCTURING':
    case 'QUICK_REFUND':
      return IconlyLight.arrow_left;
    case 'HIGH_DISCOUNT':
      return IconlyLight.discount;
    case 'SHRINKAGE_SPIKE':
      return IconlyBold.danger;
    case 'AUDIT_TAMPER':
      return IconlyBold.shield_fail;
    case 'TIME_REVERSAL':
      return IconlyLight.time_circle;
    case 'ORPHANED_RECORD':
      return IconlyLight.paper_negative;
    case 'PERMISSION_PROBING':
      return IconlyLight.lock;
    case 'CONTROL_CHANGE':
      return IconlyLight.setting;
    default:
      return IconlyLight.shield_done;
  }
}
