import 'package:flutter/material.dart';
import 'package:pos/core/widgets/app_status_badge.dart';
import 'package:pos/features/procurement/domain/entities/po_status.dart';

/// PO status pill — thin adapter over the shared [AppStatusBadge] so procurement
/// statuses render identically to every other badge in the app while keeping the
/// status→label/color mapping in one place ([PoStatus]).
class PoStatusBadge extends StatelessWidget {
  final PoStatus status;

  const PoStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(label: status.label, color: status.color);
  }
}
