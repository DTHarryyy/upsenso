import 'package:flutter/material.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/app_data_table.dart';
import 'package:pos/core/widgets/app_view_toggle.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kViewPrefKey = 'reports_inventory_view';

// ─── Sub-filter ───────────────────────────────────────────────────────────────

enum _SubView { products, ingredients }

// ─── Column definitions ───────────────────────────────────────────────────────

const _kProductColumns = [
  AppTableColumn(label: 'Product', flex: 5),
  AppTableColumn(label: 'Status', flex: 2),
  AppTableColumn(label: 'Stock', flex: 2, align: TextAlign.center),
  AppTableColumn(label: 'Avg/Day', flex: 2, align: TextAlign.center),
  AppTableColumn(label: 'Days Left', flex: 2, align: TextAlign.center),
  AppTableColumn(label: 'Notes', flex: 3),
];

const _kIngredientColumns = [
  AppTableColumn(label: 'Ingredient', flex: 5),
  AppTableColumn(label: 'Status', flex: 2),
  AppTableColumn(label: 'Unit', flex: 2),
  AppTableColumn(label: 'Stock', flex: 2, align: TextAlign.center),
  AppTableColumn(label: 'Consumed', flex: 2, align: TextAlign.center),
  AppTableColumn(label: 'Days Left', flex: 2, align: TextAlign.center),
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

String _fmt(double v) =>
    v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

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
  _SubView _subView = _SubView.products;
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
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

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(int itemCount) {
    final title = _subView == _SubView.products
        ? 'Inventory Status'
        : 'Ingredient Status';
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (itemCount > 0) ...[
          Text(
            '$itemCount ${_subView == _SubView.products ? 'items' : 'ingredients'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
        ],
        AppViewToggle(current: _view, onChanged: _setView),
      ],
    );
  }

  // ── Sub-filter chips (Products | Ingredients) ────────────────────────────────

  Widget _buildSubFilter() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SubChip(
            label: 'Products',
            isSelected: _subView == _SubView.products,
            onTap: () => setState(() => _subView = _SubView.products),
          ),
          const SizedBox(width: 2),
          _SubChip(
            label: 'Ingredients',
            isSelected: _subView == _SubView.ingredients,
            onTap: () => setState(() => _subView = _SubView.ingredients),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final productItems = widget.data.inventoryItems;
    final ingredientItems = widget.data.ingredientItems;
    final itemCount = _subView == _SubView.products
        ? productItems.length
        : ingredientItems.length;

    if (widget.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(0),
          const SizedBox(height: 10),
          _buildSubFilter(),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _shimmerCtrl,
            // ignore: unnecessary_underscores
            builder: (_, __) => _Skeleton(
              view: _view,
              subView: _subView,
              shimmerPos: -0.3 + 1.6 * _shimmerCtrl.value,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(itemCount),
        const SizedBox(height: 10),
        _buildSubFilter(),
        const SizedBox(height: 12),
        if (_subView == _SubView.products)
          _buildProductsContent(productItems)
        else
          _buildIngredientsContent(ingredientItems),
      ],
    );
  }

  // ── Products content ─────────────────────────────────────────────────────────

  Widget _buildProductsContent(List<InventoryStatusItem> items) {
    if (_view == AppViewMode.table) {
      return Column(
        children: [
          AppDataTable(
            columns: _kProductColumns,
            rowCount: items.length,
            rowCellsBuilder: (_, i) => _buildProductCells(items[i]),
            emptyState: const _EmptyState(label: 'No tracked inventory items'),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ProductTotalsBar(items: items),
          ],
        ],
      );
    }
    return _ProductCardsGrid(items: items);
  }

  List<Widget> _buildProductCells(InventoryStatusItem item) {
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

  // ── Ingredients content ───────────────────────────────────────────────────────

  Widget _buildIngredientsContent(List<IngredientReportItem> items) {
    if (_view == AppViewMode.table) {
      return Column(
        children: [
          AppDataTable(
            columns: _kIngredientColumns,
            rowCount: items.length,
            rowCellsBuilder: (_, i) => _buildIngredientCells(items[i]),
            emptyState: const _EmptyState(label: 'No ingredients found'),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            _IngredientTotalsBar(items: items),
          ],
        ],
      );
    }
    return _IngredientCardsGrid(items: items);
  }

  List<Widget> _buildIngredientCells(IngredientReportItem item) {
    final daysText = item.daysLeft == null
        ? '∞'
        : item.daysLeft! > 999
        ? '999+'
        : item.daysLeft!.toStringAsFixed(1);
    final isLow = item.status == InventoryStatusType.low;

    return [
      Text(
        item.name,
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
        item.unit ?? 'pcs',
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      Text(
        _fmt(item.currentStock),
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      ),
      Text(
        item.consumed < 0.01 ? '0' : _fmt(item.consumed),
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
    ];
  }
}

// ─── Sub-filter chip ──────────────────────────────────────────────────────────

class _SubChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SubChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.brand : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Products — Totals bar ────────────────────────────────────────────────────

class _ProductTotalsBar extends StatelessWidget {
  final List<InventoryStatusItem> items;
  const _ProductTotalsBar({required this.items});

  @override
  Widget build(BuildContext context) {
    final totalStock = items.fold(0.0, (s, i) => s + i.currentStock);
    final lowCount =
        items.where((i) => i.status == InventoryStatusType.low).length;

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

// ─── Ingredients — Totals bar ─────────────────────────────────────────────────

class _IngredientTotalsBar extends StatelessWidget {
  final List<IngredientReportItem> items;
  const _IngredientTotalsBar({required this.items});

  @override
  Widget build(BuildContext context) {
    final totalStock = items.fold(0.0, (s, i) => s + i.currentStock);
    final totalConsumed = items.fold(0.0, (s, i) => s + i.consumed);
    final lowCount =
        items.where((i) => i.status == InventoryStatusType.low).length;

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
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 2,
            child: Text(
              _fmt(totalStock),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              totalConsumed < 0.01 ? '0' : _fmt(totalConsumed),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Expanded(flex: 2, child: SizedBox()),
        ],
      ),
    );
  }
}

// ─── Products — Cards grid ────────────────────────────────────────────────────

class _ProductCardsGrid extends StatelessWidget {
  final List<InventoryStatusItem> items;
  const _ProductCardsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(label: 'No tracked inventory items');
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) => _ProductCard(item: item)).toList(),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final InventoryStatusItem item;
  const _ProductCard({required this.item});

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

// ─── Ingredients — Cards grid ─────────────────────────────────────────────────

class _IngredientCardsGrid extends StatelessWidget {
  final List<IngredientReportItem> items;
  const _IngredientCardsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyState(label: 'No ingredients found');
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) => _IngredientCard(item: item)).toList(),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final IngredientReportItem item;
  const _IngredientCard({required this.item});

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
                  item.name,
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
          const SizedBox(height: 4),
          Text(
            item.unit ?? 'pcs',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 10),
          Row(
            children: [
              _CardMetric(label: 'Stock', value: _fmt(item.currentStock)),
              _CardMetric(
                label: 'Consumed',
                value: item.consumed < 0.01 ? '0' : _fmt(item.consumed),
              ),
              _CardMetric(
                label: 'Days Left',
                value: daysText,
                valueColor: isLow ? AppColors.error : AppColors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

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

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  final AppViewMode view;
  final _SubView subView;
  final double shimmerPos;
  const _Skeleton({
    required this.view,
    required this.subView,
    required this.shimmerPos,
  });

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

  // Column flex counts mirror _kProductColumns / _kIngredientColumns
  Widget _buildTable() {
    const rowCount = 6;
    final cols = subView == _SubView.products
        ? [5, 2, 2, 2, 2, 3]
        : [5, 2, 2, 2, 2, 2];

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: cols
                  .map(
                    (f) => Expanded(
                      flex: f,
                      child: _box(width: 48, height: 11, radius: 4),
                    ),
                  )
                  .toList(),
            ),
          ),
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
                  Expanded(
                    flex: cols[0],
                    child: _box(height: 13, radius: 5),
                  ),
                  Expanded(
                    flex: cols[1],
                    child: _box(width: 58, height: 22, radius: 6),
                  ),
                  ...cols.skip(2).map(
                    (f) => Expanded(
                      flex: f,
                      child: Center(
                        child: _box(width: 32, height: 13, radius: 5),
                      ),
                    ),
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
              if (subView == _SubView.ingredients) ...[
                const SizedBox(height: 4),
                _box(width: 36, height: 10, radius: 3),
              ],
              const SizedBox(height: 10),
              _box(height: 1, radius: 1),
              const SizedBox(height: 10),
              Row(
                children: List.generate(
                  3,
                  (_) => Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(width: 36, height: 10, radius: 3),
                        const SizedBox(height: 4),
                        _box(width: 32, height: 14, radius: 5),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
