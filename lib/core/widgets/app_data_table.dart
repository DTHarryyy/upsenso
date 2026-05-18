import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// Column definition for [AppDataTable].
///
/// Use a [width] for a fixed-pixel column (table scrolls horizontally when
/// total content exceeds available space).  Omit [width] and supply [flex]
/// for a proportional column that fills the available width — no horizontal
/// scroll is added in that mode.
class AppTableColumn {
  final String label;

  /// Fixed pixel width. When null the column uses [flex] layout.
  final double? width;

  /// Flex factor used when [width] is null. Defaults to 1.
  final int flex;

  final TextAlign align;

  const AppTableColumn({
    required this.label,
    this.width,
    this.flex = 1,
    this.align = TextAlign.left,
  });

  bool get isFlexColumn => width == null;
}

/// A reusable data table with a sticky header row.
///
/// **Fixed-width mode** (all columns have [AppTableColumn.width]):
/// columns get exact pixel widths and the table scrolls horizontally.
///
/// **Flex mode** (all columns omit [AppTableColumn.width]):
/// columns share the available width proportionally — no horizontal scroll.
class AppDataTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final int rowCount;

  /// Returns one cell widget per column for the row at [index].
  final List<Widget> Function(BuildContext context, int index) rowCellsBuilder;

  final Widget? emptyState;

  /// When non-null, rows are tappable and this callback is invoked.
  final VoidCallback Function(int index)? onRowTap;

  /// Horizontal gap inserted between every pair of columns. Defaults to 0.
  final double columnGap;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.rowCellsBuilder,
    this.emptyState,
    this.onRowTap,
    this.columnGap = 0,
  });

  static const double _rowH = 16.0;

  bool get _flexMode => columns.every((c) => c.isFlexColumn);

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderRow(columns: columns, columnGap: columnGap),
        if (rowCount == 0)
          emptyState ?? const _DefaultEmpty()
        else
          Column(
            children: List.generate(rowCount, (i) {
              return _DataRow(
                columns: columns,
                cells: rowCellsBuilder(context, i),
                verticalPadding: _rowH,
                isEven: i.isEven,
                onTap: onRowTap?.call(i),
                columnGap: columnGap,
              );
            }),
          ),
      ],
    );

    return Container(
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
      child: _flexMode
          ? body
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicWidth(child: body),
            ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  final List<AppTableColumn> columns;
  final double columnGap;
  const _HeaderRow({required this.columns, required this.columnGap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: _buildCells()),
    );
  }

  List<Widget> _buildCells() {
    final result = <Widget>[];
    for (int i = 0; i < columns.length; i++) {
      final c = columns[i];
      final label = Text(
        c.label.toUpperCase(),
        textAlign: c.align,
        style: getOutfitStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.7,
        ),
      );
      if (c.isFlexColumn) {
        result.add(Expanded(flex: c.flex, child: label));
      } else {
        result.add(
          SizedBox(
            width: c.width,
            child: Align(
              alignment: c.align == TextAlign.right
                  ? Alignment.centerRight
                  : c.align == TextAlign.center
                  ? Alignment.center
                  : Alignment.centerLeft,
              child: label,
            ),
          ),
        );
      }
      if (i < columns.length - 1 && columnGap > 0) {
        result.add(SizedBox(width: columnGap));
      }
    }
    return result;
  }
}

// ── Data row ───────────────────────────────────────────────────────────────

class _DataRow extends StatefulWidget {
  final List<AppTableColumn> columns;
  final List<Widget> cells;
  final double verticalPadding;
  final bool isEven;
  final VoidCallback? onTap;
  final double columnGap;

  const _DataRow({
    required this.columns,
    required this.cells,
    required this.verticalPadding,
    this.isEven = true,
    this.onTap,
    this.columnGap = 0,
  });

  @override
  State<_DataRow> createState() => _DataRowState();
}

class _DataRowState extends State<_DataRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.onTap != null) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.brandSoft
                : widget.isEven
                ? Colors.transparent
                : AppColors.surfaceAlt.withValues(alpha: 0.5),
            border: const Border(
              bottom: BorderSide(color: AppColors.borderSoft, width: 0.5),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: widget.verticalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _buildCells(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCells() {
    final result = <Widget>[];
    for (int i = 0; i < widget.columns.length; i++) {
      final c = widget.columns[i];
      final child = i < widget.cells.length
          ? widget.cells[i]
          : const SizedBox.shrink();
      if (c.isFlexColumn) {
        result.add(
          Expanded(
            flex: c.flex,
            child: Align(
              alignment: c.align == TextAlign.right
                  ? Alignment.centerRight
                  : c.align == TextAlign.center
                  ? Alignment.center
                  : Alignment.centerLeft,
              child: child,
            ),
          ),
        );
      } else {
        result.add(
          SizedBox(
            width: c.width,
            child: Align(
              alignment: c.align == TextAlign.right
                  ? Alignment.centerRight
                  : c.align == TextAlign.center
                  ? Alignment.center
                  : Alignment.centerLeft,
              child: child,
            ),
          ),
        );
      }
      if (i < widget.columns.length - 1 && widget.columnGap > 0) {
        result.add(SizedBox(width: widget.columnGap));
      }
    }
    return result;
  }
}

// ── Default empty state ────────────────────────────────────────────────────

class _DefaultEmpty extends StatelessWidget {
  const _DefaultEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Text(
          'No records found.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
      ),
    );
  }
}
