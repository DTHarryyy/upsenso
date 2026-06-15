import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_timeline.dart';
import 'package:pos/features/procurement/domain/entities/po_status.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';

/// Builds a lifecycle timeline for a PO from the dates already on the entity
/// (created / submitted / approved) plus the current status — no extra data
/// source required. Pending future steps render as hollow nodes.
class PoTimeline extends StatelessWidget {
  final PurchaseOrder po;

  const PoTimeline({super.key, required this.po});

  @override
  Widget build(BuildContext context) {
    return AppTimeline(events: _buildEvents());
  }

  List<TimelineEvent> _buildEvents() {
    // Built chronologically below, then reversed so the most recent event is on
    // top and the original "Created" lands at the bottom (newest-first feed).
    final chronological = <TimelineEvent>[];

    // A cancelled PO short-circuits: show what happened, then the cancellation.
    if (po.status == PoStatus.cancelled) {
      chronological.addAll([
        _created(),
        if (po.submittedAt != null) _submitted(),
        if (po.approvedAt != null) _approved(),
        const TimelineEvent(
          icon: IconlyLight.close_square,
          color: AppColors.error,
          title: 'Cancelled',
        ),
      ]);
      return chronological.reversed.toList();
    }

    final received = po.status == PoStatus.received;
    final partial = po.status == PoStatus.partiallyReceived;

    chronological.addAll([
      _created(),
      // Hide the submit step only when the PO was approved straight from draft
      // (approved set, never submitted) — otherwise show it (done or pending).
      if (po.submittedAt != null || po.approvedAt == null) _submitted(),
      _approved(),
      TimelineEvent(
        icon: IconlyLight.bag,
        color: received ? AppColors.success : AppColors.brand,
        title: received
            ? 'Received'
            : partial
                ? 'Partially received'
                : 'Awaiting delivery',
        done: received || partial,
      ),
    ]);
    return chronological.reversed.toList();
  }

  TimelineEvent _created() => TimelineEvent(
        icon: IconlyLight.document,
        color: AppColors.brand,
        title: 'Created',
        subtitle: po.createdByName,
        time: _stamp(po.createdAt),
      );

  TimelineEvent _submitted() => TimelineEvent(
        icon: IconlyLight.send,
        color: Colors.orange,
        title: 'Submitted for approval',
        time: po.submittedAt != null ? _stamp(po.submittedAt!) : null,
        done: po.submittedAt != null,
      );

  TimelineEvent _approved() => TimelineEvent(
        icon: IconlyLight.shield_done,
        color: Colors.blue,
        title: 'Approved',
        subtitle: po.approvedByName,
        time: po.approvedAt != null ? _stamp(po.approvedAt!) : null,
        done: po.approvedAt != null,
      );

  String _stamp(DateTime d) =>
      '${AppFormatters.shortDate(d)} · ${AppFormatters.time12h(d)}';
}
