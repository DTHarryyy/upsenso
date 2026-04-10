import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/core/widgets/app_search_bar.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

enum ExpenseStatus { approved, pending, rejected, draft }

class ExpenseItem {
  final String id;
  final DateTime date;
  final String category;
  final String vendor;
  final String branch;
  final double amount;
  final ExpenseStatus status;
  final String submittedBy;

  const ExpenseItem({
    required this.id,
    required this.date,
    required this.category,
    required this.vendor,
    required this.branch,
    required this.amount,
    required this.status,
    required this.submittedBy,
  });
}

// ─── Static sample data ───────────────────────────────────────────────────────

final _sampleExpenses = [
  ExpenseItem(
    id: 'EXP-001',
    date: DateTime(2026, 4, 8),
    category: 'Supplies',
    vendor: 'Office Depot',
    branch: 'Main Branch',
    amount: 2450.00,
    status: ExpenseStatus.approved,
    submittedBy: 'Maria Santos',
  ),
  ExpenseItem(
    id: 'EXP-002',
    date: DateTime(2026, 4, 9),
    category: 'Utilities',
    vendor: 'Meralco',
    branch: 'North Branch',
    amount: 8750.00,
    status: ExpenseStatus.pending,
    submittedBy: 'Juan Dela Cruz',
  ),
  ExpenseItem(
    id: 'EXP-003',
    date: DateTime(2026, 4, 7),
    category: 'Maintenance',
    vendor: 'Fix-It Services',
    branch: 'South Branch',
    amount: 1200.00,
    status: ExpenseStatus.rejected,
    submittedBy: 'Ana Reyes',
  ),
  ExpenseItem(
    id: 'EXP-004',
    date: DateTime(2026, 4, 10),
    category: 'Supplies',
    vendor: 'SM Hypermarket',
    branch: 'Main Branch',
    amount: 3600.00,
    status: ExpenseStatus.draft,
    submittedBy: 'Carlo Bautista',
  ),
];

// ─── Main page ────────────────────────────────────────────────────────────────

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  bool _isTableView = true;
  ExpenseStatus? _statusFilter; // null = All
  String _searchQuery = '';
  String? _categoryFilter; // null = All Categories

  static const _categories = [
    'Supplies',
    'Utilities',
    'Maintenance',
    'Salaries',
    'Marketing',
    'Other',
  ];

  List<ExpenseItem> get _filtered {
    return _sampleExpenses.where((e) {
      final matchSearch = _searchQuery.isEmpty ||
          e.vendor.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchStatus =
          _statusFilter == null || e.status == _statusFilter;
      final matchCategory =
          _categoryFilter == null || e.category == _categoryFilter;
      return matchSearch && matchStatus && matchCategory;
    }).toList();
  }

  // ── Stat helpers ─────────────────────────────────────────────────────────

  double get _totalApproved => _sampleExpenses
      .where((e) => e.status == ExpenseStatus.approved)
      .fold(0.0, (s, e) => s + e.amount);

  double get _totalPending => _sampleExpenses
      .where((e) => e.status == ExpenseStatus.pending)
      .fold(0.0, (s, e) => s + e.amount);

  int get _pendingCount =>
      _sampleExpenses.where((e) => e.status == ExpenseStatus.pending).length;

  // ── Date range picker ─────────────────────────────────────────────────────

  DateTimeRange? _dateRange;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.brand,
            onPrimary: AppColors.textInverse,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  String get _dateRangeLabel {
    if (_dateRange == null) return 'Date Range';
    final s = _dateRange!.start;
    final e = _dateRange!.end;
    String fmt(DateTime d) => '${d.month}/${d.day}/${d.year}';
    return '${fmt(s)} – ${fmt(e)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Expenses',
          style: getOutfitStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Add Expense',
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textInverse,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Stat cards ───────────────────────────────────────────────────
          _StatCardsRow(
            totalApproved: _totalApproved,
            totalPending: _totalPending,
            expenseCount: _sampleExpenses.length,
            pendingCount: _pendingCount,
          ),
          const SizedBox(height: 16),

          // ── Filter bar ───────────────────────────────────────────────────
          _FilterBar(
            isTableView: _isTableView,
            onToggleView: () => setState(() => _isTableView = !_isTableView),
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            dateRangeLabel: _dateRangeLabel,
            onDateRangeTap: _pickDateRange,
            categoryFilter: _categoryFilter,
            categories: _categories,
            onCategoryChanged: (v) => setState(() => _categoryFilter = v),
          ),
          const SizedBox(height: 10),

          // ── Status filter tabs ───────────────────────────────────────────
          _StatusTabBar(
            selected: _statusFilter,
            pendingCount: _pendingCount,
            onSelected: (s) => setState(() => _statusFilter = s),
          ),
          const SizedBox(height: 12),

          // ── Data view ────────────────────────────────────────────────────
          if (_isTableView)
            _TableView(items: _filtered)
          else
            _CardView(items: _filtered),
        ],
      ),
    );
  }
}

// ─── Stat cards row ───────────────────────────────────────────────────────────

class _StatCardsRow extends StatelessWidget {
  final double totalApproved;
  final double totalPending;
  final int expenseCount;
  final int pendingCount;

  const _StatCardsRow({
    required this.totalApproved,
    required this.totalPending,
    required this.expenseCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Approved',
            sublabel: 'This Month',
            value: '₱${_fmt(totalApproved)}',
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.success,
            iconBg: AppColors.successSoft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Pending Approval',
            sublabel: '$pendingCount item${pendingCount == 1 ? '' : 's'}',
            value: '₱${_fmt(totalPending)}',
            icon: Icons.hourglass_top_rounded,
            iconColor: AppColors.warning,
            iconBg: AppColors.warningSoft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Expense Count',
            sublabel: 'All time',
            value: expenseCount.toString(),
            icon: Icons.receipt_long_rounded,
            iconColor: AppColors.brand,
            iconBg: AppColors.brandSoft,
          ),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}k';
    }
    return v.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: getOutfitStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: getOutfitStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sublabel,
            style: getOutfitStyle(fontSize: 10, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final bool isTableView;
  final VoidCallback onToggleView;
  final ValueChanged<String> onSearchChanged;
  final String dateRangeLabel;
  final VoidCallback onDateRangeTap;
  final String? categoryFilter;
  final List<String> categories;
  final ValueChanged<String?> onCategoryChanged;

  const _FilterBar({
    required this.isTableView,
    required this.onToggleView,
    required this.onSearchChanged,
    required this.dateRangeLabel,
    required this.onDateRangeTap,
    required this.categoryFilter,
    required this.categories,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search + toggle row
        Row(
          children: [
            Expanded(
              child: AppSearchBar(
                hint: 'Search by vendor or category...',
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(width: 8),
            // Table / Card view toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ViewToggleBtn(
                    icon: Icons.table_rows_rounded,
                    selected: isTableView,
                    tooltip: 'Table view',
                    onTap: () { if (!isTableView) onToggleView(); },
                    isLeft: true,
                  ),
                  _ViewToggleBtn(
                    icon: Icons.grid_view_rounded,
                    selected: !isTableView,
                    tooltip: 'Card view',
                    onTap: () { if (isTableView) onToggleView(); },
                    isLeft: false,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Date range + Category row
        Row(
          children: [
            // Date range button
            Expanded(
              child: GestureDetector(
                onTap: onDateRangeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dateRangeLabel,
                          style: getOutfitStyle(
                            fontSize: 13,
                            color: dateRangeLabel == 'Date Range'
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (dateRangeLabel != 'Date Range')
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Category dropdown
            Expanded(
              child: AppDropdown<String>(
                hint: 'All Categories',
                value: categoryFilter,
                items: [
                  ...categories.map(
                    (c) => AppDropdownItem(value: c, label: c),
                  ),
                ],
                onChanged: onCategoryChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;
  final bool isLeft;

  const _ViewToggleBtn({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand : Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: isLeft ? const Radius.circular(9) : Radius.zero,
              bottomLeft: isLeft ? const Radius.circular(9) : Radius.zero,
              topRight: !isLeft ? const Radius.circular(9) : Radius.zero,
              bottomRight: !isLeft ? const Radius.circular(9) : Radius.zero,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? AppColors.textInverse : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Status tab bar ───────────────────────────────────────────────────────────

class _StatusTabBar extends StatelessWidget {
  final ExpenseStatus? selected;
  final int pendingCount;
  final ValueChanged<ExpenseStatus?> onSelected;

  const _StatusTabBar({
    required this.selected,
    required this.pendingCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (null, 'All', null),
      (ExpenseStatus.pending, 'Pending', pendingCount),
      (ExpenseStatus.approved, 'Approved', null),
      (ExpenseStatus.rejected, 'Rejected', null),
      (ExpenseStatus.draft, 'Draft', null),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final (status, label, badge) = tab;
          final isSelected = selected == status;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelected(status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.brand : AppColors.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brand
                        : AppColors.borderSoft,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: getOutfitStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.textInverse
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (badge != null && badge > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$badge',
                          style: getOutfitStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.textInverse
                                : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

(Color bg, Color text, String label) _statusStyle(ExpenseStatus s) {
  return switch (s) {
    ExpenseStatus.approved =>
      (AppColors.successSoft, AppColors.success, 'Approved'),
    ExpenseStatus.pending =>
      (AppColors.warningSoft, AppColors.warning, 'Pending'),
    ExpenseStatus.rejected =>
      (AppColors.errorSoft, AppColors.error, 'Rejected'),
    ExpenseStatus.draft =>
      (AppColors.surfaceAlt, AppColors.textSecondary, 'Draft'),
  };
}

class _StatusBadge extends StatelessWidget {
  final ExpenseStatus status;

  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (bg, text, label) = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: getOutfitStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}

// ─── Row action buttons ───────────────────────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}

Widget _buildActions(BuildContext context, ExpenseItem item) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _ActionIcon(
        icon: Icons.visibility_outlined,
        color: AppColors.brand,
        bg: AppColors.brandSoft,
        tooltip: 'View',
        onTap: () => _showExpenseDetail(context, item),
      ),
      if (item.status == ExpenseStatus.pending) ...[
        _ActionIcon(
          icon: Icons.check_rounded,
          color: AppColors.success,
          bg: AppColors.successSoft,
          tooltip: 'Approve',
          onTap: () {},
        ),
        _ActionIcon(
          icon: Icons.close_rounded,
          color: AppColors.error,
          bg: AppColors.errorSoft,
          tooltip: 'Reject',
          onTap: () {},
        ),
      ],
    ],
  );
}

void _showExpenseDetail(BuildContext context, ExpenseItem item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ExpenseDetailSheet(item: item),
  );
}

// ─── Table column widths (fixed — avoids Expanded in unbounded horizontal scroll) ─

const double _colDate = 100;
const double _colCategory = 110;
const double _colVendor = 140;
const double _colBranch = 120;
const double _colAmount = 100;
const double _colStatus = 100;
const double _colSubmitted = 140;
const double _colActions = 100;

// ─── Table view ───────────────────────────────────────────────────────────────

class _TableView extends StatelessWidget {
  final List<ExpenseItem> items;

  const _TableView({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyState();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TableHeader(),
              const Divider(height: 1, color: AppColors.borderSoft),
              ...items.asMap().entries.map((entry) {
                final isLast = entry.key == items.length - 1;
                return Column(
                  children: [
                    _TableRow(item: entry.value),
                    if (!isLast)
                      const Divider(height: 1, color: AppColors.borderSoft),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _HeaderCell('Date', width: _colDate),
          _HeaderCell('Category', width: _colCategory),
          _HeaderCell('Vendor', width: _colVendor),
          _HeaderCell('Branch', width: _colBranch),
          _HeaderCell('Amount', width: _colAmount, align: TextAlign.right),
          _HeaderCell('Status', width: _colStatus),
          _HeaderCell('Submitted By', width: _colSubmitted),
          _HeaderCell('Actions', width: _colActions),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double width;
  final TextAlign align;

  const _HeaderCell(this.label,
      {required this.width, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label.toUpperCase(),
        textAlign: align,
        style: getOutfitStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final ExpenseItem item;

  const _TableRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final d = item.date;
    final dateStr =
        '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: _colDate,
            child: Text(
              dateStr,
              style: getOutfitStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          SizedBox(
            width: _colCategory,
            child: Text(
              item.category,
              style: getOutfitStyle(fontSize: 13, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: _colVendor,
            child: Text(
              item.vendor,
              style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: _colBranch,
            child: Text(
              item.branch,
              style: getOutfitStyle(fontSize: 13, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: _colAmount,
            child: Text(
              '₱${item.amount.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ),
          SizedBox(
            width: _colStatus,
            child: _StatusBadge(item.status),
          ),
          SizedBox(
            width: _colSubmitted,
            child: Text(
              item.submittedBy,
              style: getOutfitStyle(fontSize: 13, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: _colActions,
            child: Builder(builder: (ctx) => _buildActions(ctx, item)),
          ),
        ],
      ),
    );
  }
}

// ─── Card view ────────────────────────────────────────────────────────────────

class _CardView extends StatelessWidget {
  final List<ExpenseItem> items;

  const _CardView({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyState();

    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ExpenseCard(item: item),
              ))
          .toList(),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseItem item;

  const _ExpenseCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final d = item.date;
    final dateStr =
        '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: vendor + amount
          Row(
            children: [
              // Category icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  color: AppColors.brand,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.vendor,
                      style: getOutfitStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      item.category,
                      style: getOutfitStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${item.amount.toStringAsFixed(2)}',
                    style: getOutfitStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  _StatusBadge(item.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 12),

          // Meta row
          Row(
            children: [
              _MetaChip(
                  icon: Icons.calendar_today_rounded, label: dateStr),
              const SizedBox(width: 8),
              _MetaChip(
                  icon: Icons.store_mall_directory_outlined,
                  label: item.branch),
              const SizedBox(width: 8),
              _MetaChip(
                  icon: Icons.person_outline_rounded,
                  label: item.submittedBy),
            ],
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Builder(builder: (ctx) => _buildActions(ctx, item)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style:
                  getOutfitStyle(fontSize: 11, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 32,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No expenses found',
            style: getOutfitStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your filters or add a new expense.',
            style: getOutfitStyle(
                fontSize: 13, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Expense detail bottom sheet ──────────────────────────────────────────────

class _ExpenseDetailSheet extends StatelessWidget {
  final ExpenseItem item;

  const _ExpenseDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final (statusBg, statusText, statusLabel) = _statusStyle(item.status);
    final d = item.date;
    final dateStr =
        '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),

            // Gradient header
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.id,
                          style: getOutfitStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.vendor,
                          style: getOutfitStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.category,
                          style: getOutfitStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₱${item.amount.toStringAsFixed(2)}',
                        style: getOutfitStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          statusLabel,
                          style: getOutfitStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable body
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Details card
                  _DetailCard(
                    children: [
                      _DetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: dateStr,
                      ),
                      const _DetailDivider(),
                      _DetailRow(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        value: item.category,
                      ),
                      const _DetailDivider(),
                      _DetailRow(
                        icon: Icons.store_mall_directory_outlined,
                        label: 'Branch',
                        value: item.branch,
                      ),
                      const _DetailDivider(),
                      _DetailRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Submitted By',
                        value: item.submittedBy,
                      ),
                      const _DetailDivider(),
                      _DetailRow(
                        icon: Icons.tag_rounded,
                        label: 'Reference ID',
                        value: item.id,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Amount summary card
                  _DetailCard(
                    children: [
                      _AmountRow(label: 'Subtotal', value: item.amount),
                      const _DetailDivider(),
                      const _AmountRow(label: 'Tax (0%)', value: 0.0),
                      const _DetailDivider(),
                      _AmountRow(
                        label: 'Total',
                        value: item.amount,
                        isTotal: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  if (item.status == ExpenseStatus.pending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: Text(
                              'Reject',
                              style: getOutfitStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: Text(
                              'Approve',
                              style: getOutfitStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textInverse,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderSoft),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Close',
                          style: getOutfitStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: AppColors.brand),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const Spacer(),
          Text(
            value,
            style: getOutfitStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;

  const _AmountRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: getOutfitStyle(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
              color: isTotal ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            '₱${value.toStringAsFixed(2)}',
            style: getOutfitStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal ? AppColors.brand : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1, color: AppColors.borderSoft, indent: 16, endIndent: 16);
  }
}
