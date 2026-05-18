import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/app_view_toggle.dart';

/// Shimmer skeleton for the Audit Logs page.
///
/// Adapts to the current [viewMode]: renders card placeholders in card mode
/// and a table placeholder in table mode — using the same shimmer animation
/// technique as the Dashboard skeleton.
class AuditLogSkeleton extends StatefulWidget {
  final AppViewMode viewMode;
  const AuditLogSkeleton({super.key, required this.viewMode});

  @override
  State<AuditLogSkeleton> createState() => _AuditLogSkeletonState();
}

class _AuditLogSkeletonState extends State<AuditLogSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final p = -0.3 + 1.6 * _ctrl.value;

        // Shimmer gradient that slides left-to-right.
        final grad = LinearGradient(
          colors: const [
            Color(0xFFE2E8F0),
            Color(0xFFECF0F6),
            Color(0xFFF5F8FC),
            Color(0xFFECF0F6),
            Color(0xFFE2E8F0),
          ],
          stops: [
            (p - 0.4).clamp(0.0, 1.0),
            (p - 0.2).clamp(0.0, 1.0),
            p.clamp(0.0, 1.0),
            (p + 0.2).clamp(0.0, 1.0),
            (p + 0.4).clamp(0.0, 1.0),
          ],
        );

        // Shimmer block helper.
        Widget box({
          double? width,
          double height = 14.0,
          double radius = 8.0,
        }) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: grad,
          ),
        );

        return widget.viewMode == AppViewMode.cards
            ? _buildCards(grad, box)
            : _buildTable(box);
      },
    );
  }

  // ── Card skeleton ──────────────────────────────────────────────────────────
  //
  // Mirrors the structure of auditLogMobileCard:
  //   Container(border, radius 12)
  //     Row
  //       Container(w:4)  ← left color accent
  //       Expanded → Padding → Column
  //         Row: badge + Spacer + timestamp
  //         entity / description
  //         Divider
  //         footer chips

  Widget _buildCards(
    LinearGradient grad,
    Widget Function({double? width, double height, double radius}) box,
  ) {
    Widget card() => Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar (mimics the action-colour strip).
            Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: grad,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),

            // Card body.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: action badge (left) + timestamp (right).
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        box(width: 72, height: 22, radius: 6),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            box(width: 80, height: 13),
                            const SizedBox(height: 2),
                            box(width: 55, height: 11),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Entity type line.
                    box(width: 100, height: 13),
                    const SizedBox(height: 4),

                    // Description (two lines).
                    box(width: 220, height: 12),
                    const SizedBox(height: 5),
                    box(width: 160, height: 12),

                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.borderSoft),
                    const SizedBox(height: 10),

                    // Footer: user chip + branch chip.
                    Row(
                      children: [
                        box(width: 80, height: 12),
                        const SizedBox(width: 8),
                        box(width: 72, height: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: 6,
      itemBuilder: (_, __) =>
          Padding(padding: const EdgeInsets.only(bottom: 10), child: card()),
    );
  }

  // ── Table skeleton ─────────────────────────────────────────────────────────
  //
  // Mirrors AppDataTable in fixed-width mode with _kColumns:
  //   [Timestamp:130, Action:110, Entity:140, User:120, Branch:120,
  //    Device/IP:140, Details:60]  columnGap:12

  static const _kColWidths = [130.0, 110.0, 140.0, 120.0, 120.0, 140.0, 60.0];
  static const _kColGap = 12.0;

  Widget _buildTable(
    Widget Function({double? width, double height, double radius}) box,
  ) {
    // Builds one row that matches AppDataTable's row/header padding & colours.
    Widget row({
      required List<Widget> cells,
      bool isHeader = false,
      bool isEven = true,
    }) {
      final children = <Widget>[];
      for (var i = 0; i < cells.length; i++) {
        children.add(
          SizedBox(
            width: _kColWidths[i],
            child: Align(
              // Last column (Details) is center-aligned.
              alignment: i == _kColWidths.length - 1
                  ? Alignment.center
                  : Alignment.centerLeft,
              child: cells[i],
            ),
          ),
        );
        if (i < cells.length - 1) {
          children.add(const SizedBox(width: _kColGap));
        }
      }
      return Container(
        decoration: BoxDecoration(
          color: isHeader
              ? AppColors.surfaceAlt
              : isEven
              ? Colors.transparent
              : AppColors.surfaceAlt.withValues(alpha: 0.5),
          border: Border(
            bottom: BorderSide(
              color: AppColors.borderSoft,
              width: isHeader ? 1.5 : 0.5,
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isHeader ? 14 : 16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      );
    }

    // One skeleton data row — content mirrors the real cell shapes.
    Widget dataRow(int i) => row(
      isEven: i.isEven,
      cells: [
        // Timestamp: date line + time line.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            box(width: 80, height: 13),
            const SizedBox(height: 3),
            box(width: 55, height: 12),
          ],
        ),
        // Action: badge pill.
        box(width: 72, height: 22, radius: 6),
        // Entity: type + name.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            box(width: 80, height: 13),
            const SizedBox(height: 3),
            box(width: 55, height: 11),
          ],
        ),
        // User.
        box(width: 90, height: 13),
        // Branch: icon + text.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            box(width: 14, height: 14, radius: 7),
            const SizedBox(width: 5),
            box(width: 70, height: 12),
          ],
        ),
        // Device / IP: icon + text.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            box(width: 13, height: 13, radius: 6),
            const SizedBox(width: 4),
            box(width: 80, height: 12),
          ],
        ),
        // Details: eye-button placeholder.
        box(width: 28, height: 28, radius: 8),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderSoft),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header.
                row(
                  isHeader: true,
                  cells: [
                    box(width: 68, height: 11),
                    box(width: 48, height: 11),
                    box(width: 55, height: 11),
                    box(width: 42, height: 11),
                    box(width: 50, height: 11),
                    box(width: 62, height: 11),
                    box(width: 28, height: 11),
                  ],
                ),
                // Six skeleton rows.
                ...List.generate(6, dataRow),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
