import 'package:flutter/material.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/app_data_table.dart';
import 'package:pos/core/widgets/app_view_toggle.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences key — persists the chosen view across restarts.
const _kViewPrefKey = 'reports_inventory_view';

// ─── Column definitions (flex mode — fills width, no horizontal scroll) ───────

const _kColumns = [
  AppTableColumn(label: 'Product', flex: 5),
  AppTableColumn(label: 'Status', flex: 2),
  AppTableColumn(label: 'Stock', flex: 2, align: TextAlign.center),
  AppTableColumn(label: 'Avg/Day', flex: 2, align: TextAlign.center),
  AppTableColumn(label: 'Days Left', flex: 2, align: TextAlign.center),
  AppTableColumn(label: 'Notes', flex: 3),
];

// ─── Status colour helpers ────────────────────────────────────────────────────

Color _statusFg(InventoryStatusType s) => switch (s) {
  InventoryStatusType.low => AppColors.error,
  InventoryStatusType.warning => AppColors.warning,
  InventoryStatusType.ok => AppColors.success,
  InventoryStatusType.slowMoving => AppColors.brand,
};

Color _statusBg(InventoryStatusType s) => switch (s) {
  InventoryStatusType.low => AppColors.errorSoft,
  InventoryStatusType.warning => AppColors.warningSoft,
  InventoryStatusType.ok => AppColors.successSoft,
  InventoryStatusType.slowMoving => AppColors.brandSoft,
};

// ─── Tab ──────────────────────────────────────────────────────────────────────

class InventoryHealthTab extends StatefulWidget {
  final ReportsData data;
  final bool isLoading;
  const InventoryHealthTab({
    super.key,
    required this.data,
    this.isLoading = false,
  });

  @override
  State<InventoryHealthTab> createState() => _InventoryHealthTabState();
}

class _InventoryHealthTabState extends State<InventoryHealthTab>
    with SingleTickerProviderStateMixin {
  AppViewMode _view = AppViewMode.table;
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    // SharedPreferences is pre-loaded at app start, so this is synchronous.
    final saved = sl<SharedPreferences>().getString(_kViewPrefKey);
    if (saved == AppViewMode.cards.name) _view = AppViewMode.cards;
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _setView(AppViewMode v) {
    setState(() => _view = v);
    sl<SharedPreferences>().setString(_kViewPrefKey, v.name);
  }

  Widget _buildHeader({int? itemCount}) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Inventory Status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (itemCount != null && itemCount > 0) ...[
          Text(
            '$itemCount items',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
        ],
        AppViewToggle(current: _view, onChanged: _setView),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _shimmerCtrl,
            // ignore: unnecessary_underscores
            builder: (_, __) => _InventorySkeleton(
              view: _view,
              shimmerPos: -0.3 + 1.6 * _shimmerCtrl.value,
            ),
          ),
        ],
      );
    }

    final items = widget.data.inventoryItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ────────────────────────────────────────────────────
        _buildHeader(itemCount: items.length),
        const SizedBox(height: 12),

        // ── Content ───────────────────────────────────────────────────────────
        if (_view == AppViewMode.table) ...[
          AppDataTable(
            columns: _kColumns,
            rowCount: items.length,
            rowCellsBuilder: (_, i) => _buildCells(items[i]),
            emptyState: const _EmptyState(),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            _TotalsBar(items: items),
          ],
        ] else
          _CardsGrid(items: items),
      ],
    );
  }

  List<Widget> _buildCells(InventoryStatusItem item) {
    final daysText = item.daysLeft == null
        ? '∞'
        : item.daysLeft! > 999
        ? '999+'
        : item.daysLeft!.toStringAsFixed(1);
    final isLow = item.status == InventoryStatusType.low;

    return [
      Text(
        item.productName,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: _StatusBadge(status: item.status),
      ),
      Text(
        item.currentStock % 1 == 0
            ? item.currentStock.toInt().toString()
            : item.currentStock.toStringAsFixed(1),
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      ),
      Text(
        item.avgDailySale < 0.01 ? '0' : item.avgDailySale.toStringAsFixed(1),
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      Text(
        daysText,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isLow ? FontWeight.w600 : FontWeight.normal,
          color: isLow ? AppColors.error : AppColors.textSecondary,
        ),
      ),
      Text(
        item.notes?.isNotEmpty == true ? item.notes! : '—',
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        overflow: TextOverflow.ellipsis,
      ),
    ];
  }
}

// ─── Totals bar ───────────────────────────────────────────────────────────────

class _TotalsBar extends StatelessWidget {
  final List<InventoryStatusItem> items;
  const _TotalsBar({required this.items});

  @override
  Widget build(BuildContext context) {
    final totalStock = items.fold(0.0, (s, i) => s + i.currentStock);
    final lowCount = items
        .where((i) => i.status == InventoryStatusType.low)
        .length;

    // Flex values mirror _kColumns so this bar aligns under the table above.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 5,
            child: Text(
              'TOTALS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$lowCount low',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              totalStock % 1 == 0
                  ? totalStock.toInt().toString()
                  : totalStock.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 3, child: SizedBox()),
        ],
      ),
    );
  }
}

// ─── Cards grid ───────────────────────────────────────────────────────────────

class _CardsGrid extends StatelessWidget {
  final List<InventoryStatusItem> items;
  const _CardsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyState();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) => _InventoryCard(item: item)).toList(),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryStatusItem item;
  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final daysText = item.daysLeft == null
        ? '∞'
        : item.daysLeft! > 999
        ? '999+'
        : item.daysLeft!.toStringAsFixed(1);
    final isLow = item.status == InventoryStatusType.low;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLow
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.borderSoft,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              _StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 10),
          Row(
            children: [
              _CardMetric(
                label: 'Stock',
                value: item.currentStock % 1 == 0
                    ? item.currentStock.toInt().toString()
                    : item.currentStock.toStringAsFixed(1),
              ),
              _CardMetric(
                label: 'Avg/Day',
                value: item.avgDailySale < 0.01
                    ? '0'
                    : item.avgDailySale.toStringAsFixed(1),
              ),
              _CardMetric(
                label: 'Days Left',
                value: daysText,
                valueColor: isLow ? AppColors.error : AppColors.textPrimary,
              ),
            ],
          ),
          if (item.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              item.notes!,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _CardMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _CardMetric({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status badge (shared by table cells and cards) ───────────────────────────

class _StatusBadge extends StatelessWidget {
  final InventoryStatusType status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _statusFg(status),
        ),
      ),
    );
  }
}

// ─── Skeleton (adapts to table / cards view) ─────────────────────────────────

class _InventorySkeleton extends StatelessWidget {
  final AppViewMode view;
  final double shimmerPos;
  const _InventorySkeleton({required this.view, required this.shimmerPos});

  Gradient get _shimmer => LinearGradient(
    colors: const [
      Color(0xFFE2E8F0),
      Color(0xFFECF0F6),
      Color(0xFFF5F8FC),
      Color(0xFFECF0F6),
      Color(0xFFE2E8F0),
    ],
    stops: [
      (shimmerPos - 0.4).clamp(0.0, 1.0),
      (shimmerPos - 0.2).clamp(0.0, 1.0),
      shimmerPos.clamp(0.0, 1.0),
      (shimmerPos + 0.2).clamp(0.0, 1.0),
      (shimmerPos + 0.4).clamp(0.0, 1.0),
    ],
  );

  Widget _box({double? width, double height = 14, double radius = 8}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: _shimmer,
        ),
      );

  @override
  Widget build(BuildContext context) =>
      view == AppViewMode.table ? _buildTable() : _buildCards();

  Widget _buildTable() {
    const rowCount = 6;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _box(width: 72, height: 11, radius: 4),
                ),
                Expanded(
                  flex: 2,
                  child: _box(width: 50, height: 11, radius: 4),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: _box(width: 40, height: 11, radius: 4)),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: _box(width: 46, height: 11, radius: 4)),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: _box(width: 52, height: 11, radius: 4)),
                ),
                Expanded(
                  flex: 3,
                  child: _box(width: 36, height: 11, radius: 4),
                ),
              ],
            ),
          ),
          // Data rows
          ...List.generate(rowCount, (i) {
            final isLast = i == rowCount - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: i.isOdd ? const Color(0xFFF7F9FC) : Colors.white,
                borderRadius: isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(12))
                    : null,
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: AppColors.borderSoft.withValues(alpha: 0.6),
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(flex: 5, child: _box(height: 13, radius: 5)),
                  Expanded(
                    flex: 2,
                    child: _box(width: 58, height: 22, radius: 6),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: _box(width: 30, height: 13, radius: 5),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: _box(width: 26, height: 13, radius: 5),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: _box(width: 34, height: 13, radius: 5),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _box(width: 80, height: 11, radius: 5),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCards() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(
        8,
        (_) => Container(
          width: 200,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _box(height: 13, radius: 5)),
                  const SizedBox(width: 6),
                  _box(width: 52, height: 22, radius: 6),
                ],
              ),
              const SizedBox(height: 10),
              _box(height: 1, radius: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(width: 30, height: 10, radius: 3),
                        const SizedBox(height: 4),
                        _box(width: 40, height: 14, radius: 5),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(width: 36, height: 10, radius: 3),
                        const SizedBox(height: 4),
                        _box(width: 32, height: 14, radius: 5),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(width: 44, height: 10, radius: 3),
                        const SizedBox(height: 4),
                        _box(width: 28, height: 14, radius: 5),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'No tracked inventory items',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
