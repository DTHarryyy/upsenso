import 'package:flutter/material.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/services/refund_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_count_stepper.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_inline_banner.dart';
import 'package:pos/core/widgets/app_bottom_sheet_scaffold.dart';
import 'package:pos/core/widgets/app_modal.dart';
import 'package:pos/core/widgets/app_switch.dart';
import 'package:pos/features/sales/domain/entities/sale_item.dart';
import 'package:pos/features/sales/domain/entities/sale_transaction.dart';
import 'package:pos/features/sales/presentation/widgets/refund_confirm_sheet.dart';

/// Opens the refund sheet for [transaction]. Returns the refunded amount if
/// a refund was recorded (so the caller can show "Refunded $X" feedback and
/// refresh its cached line-item data), or `null` if the user cancelled.
Future<double?> showRefundSheet(
  BuildContext context, {
  required SaleTransaction transaction,
  required List<SaleItem> items,
}) {
  return showAppModal<double>(
    context: context,
    forceDialog: true,
    builder: (_) => RefundSheet(transaction: transaction, items: items),
  );
}

class RefundSheet extends StatefulWidget {
  final SaleTransaction transaction;
  final List<SaleItem> items;

  const RefundSheet({super.key, required this.transaction, required this.items});

  @override
  State<RefundSheet> createState() => _RefundSheetState();
}

class _RefundSheetState extends State<RefundSheet> {
  // Selecting this reason defaults every line's restock toggle off — a
  // damaged/defective return is unlikely to be resellable. Still shown and
  // overridable per line rather than hidden: the reason is a hint, not a
  // hard rule (e.g. cosmetic-only damage the business still wants to stock).
  static const _notResellableReason = 'Damaged / defective';
  static const _reasonPresets = [
    'Changed mind',
    'Wrong item',
    _notResellableReason,
    'Duplicate charge',
  ];

  late final List<SaleItem> _refundable;
  final Map<String, double> _selectedQty = {};
  // Defaults to true: most returns ARE resellable. The refunder opts OUT
  // per line for damaged/expired/opened goods rather than opting in.
  final Map<String, bool> _restock = {};
  final TextEditingController _reason = TextEditingController();
  String? _selectedReasonPreset;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refundable = widget.items.where((i) => i.remainingQty > 0).toList();
    for (final item in _refundable) {
      _selectedQty[item.id] = 0;
      _restock[item.id] = true;
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  double get _selectedTotal {
    var total = 0.0;
    for (final item in _refundable) {
      final qty = _selectedQty[item.id] ?? 0;
      if (qty <= 0) continue;
      final unitTotal = item.qty == 0 ? 0.0 : item.lineTotal / item.qty;
      total += unitTotal * qty;
    }
    return total;
  }

  // Whether anything is selected — independent of dollar amount, since a
  // free/zero-priced line (promo items, ₱0 line, etc.) is still a valid
  // qty selection even though it never makes _selectedTotal positive.
  bool get _hasSelection => _selectedQty.values.any((qty) => qty > 0);

  /// Preset alone, note alone, both joined, or `null` if neither is set.
  String? get _composedReason {
    final preset = _selectedReasonPreset;
    final note = _reason.text.trim();
    if (preset == null) return note.isEmpty ? null : note;
    return note.isEmpty ? preset : '$preset — $note';
  }

  /// Re-defaults every line's restock toggle when the reason changes — off
  /// for "Damaged / defective", on for everything else (including no
  /// reason). Still a default, not a lock: the per-line switch stays
  /// visible and the refunder can flip it right back.
  void _onReasonChanged(String? preset) {
    setState(() {
      _selectedReasonPreset = preset;
      final defaultRestock = preset != _notResellableReason;
      for (final item in _refundable) {
        _restock[item.id] = defaultRestock;
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (final item in _refundable) {
        _selectedQty[item.id] = item.remainingQty;
      }
    });
  }

  void _clearAll() {
    setState(() {
      for (final item in _refundable) {
        _selectedQty[item.id] = 0;
      }
    });
  }

  /// Builds the refund line tuples shared by the confirm-summary and the
  /// actual submit call, so they can never disagree with each other.
  List<({String transactionItemId, double qty, bool restock})> get _lines =>
      _refundable
          .map(
            (i) => (
              transactionItemId: i.id,
              qty: _selectedQty[i.id] ?? 0.0,
              // Untracked items never actually move stock — record that
              // honestly rather than carrying over a hidden toggle's default.
              restock: i.isStockTracked && (_restock[i.id] ?? true),
            ),
          )
          .where((l) => l.qty > 0)
          .toList();

  /// Shows the final review step; only calls [_performRefund] if confirmed.
  Future<void> _confirmAndSubmit() async {
    final lines = _lines;
    if (lines.isEmpty) return;

    final byId = {for (final i in _refundable) i.id: i};
    final summaryLines = lines
        .map(
          (l) => (
            label: byId[l.transactionItemId]!.productName,
            qty: l.qty,
            amount:
                (byId[l.transactionItemId]!.qty == 0
                    ? 0.0
                    : byId[l.transactionItemId]!.lineTotal /
                        byId[l.transactionItemId]!.qty) *
                l.qty,
            restock: l.restock,
          ),
        )
        .toList();

    final confirmed = await showRefundConfirmSheet(
      context,
      lines: summaryLines,
      total: _selectedTotal,
      reason: _composedReason,
    );
    if (confirmed && mounted) await _performRefund();
  }

  Future<void> _performRefund() async {
    final lines = _lines;
    if (lines.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final activeBusiness = sl<ActiveBusinessContext>();
    final businessId = activeBusiness.businessId;
    final userId = activeBusiness.userId;
    if (businessId == null || userId == null) {
      setState(() {
        _saving = false;
        _error = 'No active session — please sign in again.';
      });
      return;
    }

    final refundedAmount = _selectedTotal;
    try {
      await sl<RefundService>().refund(
        transactionId: widget.transaction.id,
        lines: lines,
        businessId: businessId,
        refundedBy: userId,
        reason: _composedReason,
      );
      if (mounted) Navigator.pop(context, refundedAmount);
    } on RefundPermissionDeniedException {
      setState(() {
        _error = "You don't have permission to refund sales.";
      });
    } on RefundOverRefundException {
      setState(() {
        _error = 'One or more items exceed the refundable quantity. '
            'Pull down to refresh and try again.';
      });
    } on RefundValidationException catch (e) {
      setState(() => _error = e.message);
    } catch (e, st) {
      debugPrint('[RefundSheet] Error in _performRefund: $e\n$st');
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetScaffold(
      title: 'Refund Items',
      fullHeight: true,
      maxHeightFactor: 0.9,
      titleTrailing: IconButton(
        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
        visualDensity: VisualDensity.compact,
        tooltip: 'Close',
        onPressed: _saving ? null : () => Navigator.pop(context),
      ),
      action: AppFilledButton(
        label: _hasSelection
            ? 'Refund ${AppFormatters.currency(_selectedTotal)}'
            : 'Select items to refund',
        loading: _saving,
        onPressed: _saving || !_hasSelection ? null : _confirmAndSubmit,
      ),
      child: _refundable.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Every item on this sale has already been refunded.',
                style: AppTextStyles.body(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) ...[
                    AppInlineBanner(message: _error),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sale ${widget.transaction.invoiceNumber ?? '#${widget.transaction.id.substring(0, 8)}'}',
                        style: AppTextStyles.caption(
                          context,
                        ).copyWith(color: AppColors.textMuted),
                      ),
                      GestureDetector(
                        onTap: _saving
                            ? null
                            : (_hasSelection ? _clearAll : _selectAll),
                        child: Text(
                          _hasSelection ? 'Clear all' : 'Refund all',
                          style: AppTextStyles.caption(context).copyWith(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._refundable.map(_buildLine),
                  const SizedBox(height: 14),
                  Text(
                    'Reason (optional)',
                    style: AppTextStyles.caption(
                      context,
                    ).copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  AppDropdown<String>(
                    value: _selectedReasonPreset,
                    hint: 'Select a reason',
                    items: _reasonPresets
                        .map(
                          (preset) =>
                              AppDropdownItem(value: preset, label: preset),
                        )
                        .toList(),
                    onChanged: _onReasonChanged,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _reason,
                    maxLength: 200,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add details (optional)',
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLine(SaleItem item) {
    final selected = _selectedQty[item.id] ?? 0;
    final isSelected = selected > 0;
    final restock = _restock[item.id] ?? true;
    final unitTotal = item.qty == 0 ? 0.0 : item.lineTotal / item.qty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surfaceAlt : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.brand.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.variantName != 'Default'
                          ? '${item.productName} (${item.variantName})'
                          : item.productName,
                      style: AppTextStyles.body(
                        context,
                      ).copyWith(color: AppColors.textPrimary),
                    ),
                    Text(
                      '${AppFormatters.quantity(item.remainingQty)} of '
                      '${AppFormatters.quantity(item.qty)} refundable '
                      '· ${AppFormatters.currency(unitTotal)} each',
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppCountStepper(
                value: selected,
                min: 0,
                max: item.remainingQty,
                step: item.qty == item.qty.roundToDouble() ? 1 : 0.1,
                onChanged: _saving
                    ? (_) {}
                    : (v) => setState(() => _selectedQty[item.id] = v),
              ),
            ],
          ),
          // Showing this toggle for an untracked item would be a control
          // that silently does nothing — InventoryRepository skips stock
          // movement for it either way, so don't offer the choice at all.
          if (isSelected && item.isStockTracked) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: AppColors.borderSoft),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Add back to inventory',
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                AppSwitch(
                  value: restock,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _restock[item.id] = v),
                ),
              ],
            ),
            if (!restock) ...[
              const SizedBox(height: 4),
              Text(
                'Won’t be restocked — marked as damaged, expired, or otherwise not resellable.',
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: AppColors.warning),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
