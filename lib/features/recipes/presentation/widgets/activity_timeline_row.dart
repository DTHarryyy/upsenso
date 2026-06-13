import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/recipes/domain/entities/stock_movement.dart';
import 'package:pos/features/recipes/utils/quantity_format.dart';

/// A single stock movement rendered as a timeline entry: a colored node
/// (in = green ↓, out = red ↑) connected to its neighbours, with the reason +
/// date on the left and the signed amount + running balance on the right.
class ActivityTimelineRow extends StatelessWidget {
  final StockMovement movement;
  final String unit;
  final bool isFirst;
  final bool isLast;

  const ActivityTimelineRow({
    super.key,
    required this.movement,
    required this.unit,
    required this.isFirst,
    required this.isLast,
  });

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${_months[local.month - 1]} ${local.day}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isIn = movement.isIncoming;
    final color = isIn ? AppColors.inStock : AppColors.outOfStock;
    final sign = isIn ? '+' : '−';
    final qty = '$sign${formatQuantity(movement.quantity)} $unit';

    // Running balance, only when the ledger captured the snapshot.
    final before = movement.quantityBefore;
    final after = movement.quantityAfter;
    final balance = (before != null && after != null)
        ? '${formatQuantity(before)} → ${formatQuantity(after)} $unit'
        : null;

    // Left meta prefers a human note; otherwise it anchors the row with a date.
    final note = movement.note?.isNotEmpty == true ? movement.note! : null;
    final leftMeta = note ?? _formatDate(movement.createdAt);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimelineRail(
              color: color, isIn: isIn, isFirst: isFirst, isLast: isLast),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  top: isFirst ? 1 : 5, bottom: isLast ? 1 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movement.reason,
                          style: getOutfitStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          leftMeta,
                          style: getOutfitStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        qty,
                        style: getOutfitStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      if (balance != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          balance,
                          style: getOutfitStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Vertical rail: a colored node with arrow, connected to its neighbours by a
// soft line above/below so the rows read as one continuous timeline.
class _TimelineRail extends StatelessWidget {
  final Color color;
  final bool isIn;
  final bool isFirst;
  final bool isLast;

  const _TimelineRail({
    required this.color,
    required this.isIn,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Column(
        children: [
          _line(visible: !isFirst, height: 4),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 15,
              color: color,
            ),
          ),
          Expanded(child: _line(visible: !isLast)),
        ],
      ),
    );
  }

  Widget _line({required bool visible, double? height}) {
    return Container(
      width: 2,
      height: height,
      color: visible ? AppColors.borderSoft : Colors.transparent,
    );
  }
}
