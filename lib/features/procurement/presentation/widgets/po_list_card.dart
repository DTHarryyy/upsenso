import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/business_clock.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_progress_bar.dart';
import 'package:pos/features/procurement/domain/entities/po_status.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/presentation/widgets/po_status_badge.dart';

/// Rich purchase-order row for the PO list.
///
/// Surfaces the full status of a PO without opening it: lifecycle stage track,
/// supplier, an overdue/due-soon delivery chip, and total. The progress track
/// reflects pipeline position (draft → received), not received quantity — the
/// list stream carries no line data, so the precise receiving meter lives on
/// the detail page instead.
class PoListCard extends StatelessWidget {
  final PurchaseOrder po;
  final VoidCallback onTap;

  const PoListCard({super.key, required this.po, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final showTrack = po.status != PoStatus.cancelled;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    po.poNumber,
                    style: getOutfitStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                PoStatusBadge(status: po.status),
              ],
            ),
            if (po.supplierName != null) ...[
              const SizedBox(height: 4),
              Text(
                po.supplierName!,
                style: getOutfitStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (showTrack) ...[
              const SizedBox(height: 10),
              // Once receiving, show the real received meter so it matches the
              // detail page; earlier stages show the lifecycle stage track.
              if (_isReceiving(po.status))
                _ReceivedBar(po: po)
              else
                _StageTrack(status: po.status),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _DeliveryChip(po: po),
                const Spacer(),
                Text(
                  AppFormatters.currency(po.totalAmount),
                  style: getOutfitStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isReceiving(PoStatus status) =>
      status == PoStatus.partiallyReceived || status == PoStatus.received;
}

/// Real receiving meter for the list card — mirrors the detail page's
/// "Received x / y (z%)" so the same PO reads identically on both screens.
class _ReceivedBar extends StatelessWidget {
  final PurchaseOrder po;

  const _ReceivedBar({required this.po});

  @override
  Widget build(BuildContext context) {
    final ordered = po.quantityOrdered;
    final received = po.quantityReceived;
    final done = ordered > 0 && received >= ordered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Received',
              style: getOutfitStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const Spacer(),
            Text(
              '${AppFormatters.quantity(received)} / ${AppFormatters.quantity(ordered)}'
              '  (${(po.receivedFraction * 100).round()}%)',
              style: getOutfitStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppProgressBar(
          value: po.receivedFraction,
          color: done ? AppColors.success : po.status.color,
          height: 5,
        ),
      ],
    );
  }
}

/// Segmented lifecycle track: Ordered → Submitted → Approved → Received.
///
/// Each reached milestone fills a segment, so the bar reads as a discrete stage
/// position rather than a "% received" meter. A partially-received PO shows the
/// final segment half-filled to signal receiving is underway — the list stream
/// carries no line data, so the exact received amount isn't known here.
class _StageTrack extends StatelessWidget {
  final PoStatus status;

  const _StageTrack({required this.status});

  @override
  Widget build(BuildContext context) {
    const total = 4;
    // (filled segments, whether the next segment is in-progress)
    final (int filled, bool partial) = switch (status) {
      PoStatus.draft => (1, false),
      PoStatus.submitted => (2, false),
      PoStatus.approved => (3, false),
      PoStatus.partiallyReceived => (3, true),
      PoStatus.received => (4, false),
      PoStatus.cancelled => (0, false),
      PoStatus.closed => (4, false),
    };
    final color = status.color;

    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: _Segment(
              isFull: i < filled,
              isPartial: partial && i == filled,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  final bool isFull;
  final bool isPartial;
  final Color color;

  const _Segment({
    required this.isFull,
    required this.isPartial,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(3);
    final track = DecoratedBox(
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: radius),
      child: const SizedBox(height: 5, width: double.infinity),
    );

    if (isFull) {
      return DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: radius),
        child: const SizedBox(height: 5, width: double.infinity),
      );
    }
    if (isPartial) {
      return Stack(
        children: [
          track,
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.5,
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, borderRadius: radius),
              child: const SizedBox(height: 5),
            ),
          ),
        ],
      );
    }
    return track;
  }
}

/// Delivery date chip that turns amber when due soon and red when overdue —
/// but only while the PO is still open (closed/cancelled POs show a plain date).
class _DeliveryChip extends StatelessWidget {
  final PurchaseOrder po;

  const _DeliveryChip({required this.po});

  @override
  Widget build(BuildContext context) {
    final due = po.expectedDelivery;
    final open = !po.status.isClosed && po.status != PoStatus.cancelled;

    Color color = AppColors.textMuted;
    IconData icon = IconlyLight.calendar;
    String label;

    if (due != null && open) {
      final days = _daysUntil(due);
      if (days < 0) {
        color = AppColors.error;
        icon = IconlyLight.time_circle;
        label = 'Overdue ${-days}d';
      } else if (days == 0) {
        color = AppColors.warning;
        icon = IconlyLight.time_circle;
        label = 'Due today';
      } else if (days <= 3) {
        color = AppColors.warning;
        label = 'Due in ${days}d';
      } else {
        label = AppFormatters.shortDate(due);
      }
    } else if (due != null) {
      label = AppFormatters.shortDate(due);
    } else {
      label = AppFormatters.shortDate(po.createdAt);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: getOutfitStyle(
            fontSize: 12,
            fontWeight: color == AppColors.textMuted
                ? FontWeight.w400
                : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // Whole-day difference from today (date-only) so "due today" is exact.
  int _daysUntil(DateTime due) {
    final today = BusinessClock.today();
    final target = DateTime(due.year, due.month, due.day);
    return target.difference(today).inDays;
  }
}
