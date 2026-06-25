import 'package:flutter/material.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// A single at-a-glance KPI: an accent icon badge, a bold value and a muted
/// label. Designed to read clearly at a glance in a [AppKpiStrip] or laid out
/// flexibly inside a [Row]/grid.
///
/// The value uses a scale-down [FittedBox] so long currency figures never
/// overflow a fixed-width tile — they shrink to fit instead.
class AppKpiTile extends StatelessWidget {
  final String label;
  final String value;

  /// Accent colour for the value and icon badge.
  final Color color;

  /// Optional leading icon shown in a soft-tinted badge.
  final IconData? icon;

  /// Fixed width override. Leave null to fill the parent's constraints (e.g.
  /// when wrapped in an [Expanded] inside a [Row]); [AppKpiStrip] supplies its
  /// own width so tiles stay uniform.
  final double? width;

  final VoidCallback? onTap;

  const AppKpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 12),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: getOutfitStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: getOutfitStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

/// Horizontally scrolling strip of [AppKpiTile]s with uniform width and height.
///
/// [IntrinsicHeight] keeps every tile as tall as the tallest so a wrapping
/// label or scaled value never leaves one card shorter than its neighbours.
class AppKpiStrip extends StatelessWidget {
  final List<AppKpiTile> tiles;
  final double tileWidth;
  final double gap;
  final EdgeInsetsGeometry padding;

  const AppKpiStrip({
    super.key,
    required this.tiles,
    this.tileWidth = 132,
    this.gap = 10,
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 6),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = padding.resolve(Directionality.of(context));
        final available = constraints.maxWidth - pad.horizontal;
        final needed = tiles.length * tileWidth + (tiles.length - 1) * gap;

        // Wide enough for every tile — justify them across the row so the strip
        // reads like a dashboard rather than a scrollable rail.
        if (available.isFinite && available >= needed) {
          return Padding(
            padding: padding,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    Expanded(child: tiles[i]),
                  ],
                ],
              ),
            ),
          );
        }

        //make this wrap instead of scrollable

        return SingleChildScrollView(
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  SizedBox(width: tileWidth, child: tiles[i]),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
