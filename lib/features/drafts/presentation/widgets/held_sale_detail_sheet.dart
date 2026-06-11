import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale_item.dart';

/// Bottom sheet showing a held sale's items and totals with Resume / Finish
/// actions. [onResume] and [onFinish] fire after the sheet closes.
Future<void> showHeldSaleDetailSheet(
  BuildContext context, {
  required DraftSale draft,
  required List<DraftSaleItem> items,
  required VoidCallback onResume,
  required VoidCallback onFinish,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _HeldSaleDetail(
      draft: draft,
      items: items,
      onResume: onResume,
      onFinish: onFinish,
    ),
  );
}

class _HeldSaleDetail extends StatelessWidget {
  final DraftSale draft;
  final List<DraftSaleItem> items;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  const _HeldSaleDetail({
    required this.draft,
    required this.items,
    required this.onResume,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final title = draft.label?.trim().isNotEmpty == true
        ? draft.label!
        : (draft.customerName?.trim().isNotEmpty == true
              ? draft.customerName!
              : 'Untitled sale');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.subtitle(
                context,
              ).copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
            Text(
              '${AppFormatters.shortDate(draft.updatedAt)} · '
              '${AppFormatters.time12h(draft.updatedAt)}',
              style: getOutfitStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.borderSoft),
                itemBuilder: (_, i) => _itemRow(items[i]),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderSoft),
            const SizedBox(height: 12),
            _totalRow('Subtotal', draft.subtotal),
            if (draft.discountAmount > 0) ...[
              const SizedBox(height: 4),
              _totalRow('Discount', -draft.discountAmount,
                  color: AppColors.success),
            ],
            if (draft.taxAmount > 0) ...[
              const SizedBox(height: 4),
              _totalRow('Tax', draft.taxAmount),
            ],
            const SizedBox(height: 8),
            _totalRow('Total', draft.totalAmount, isBig: true),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onResume();
                    },
                    icon: const Icon(IconlyLight.edit, size: 18),
                    label: const Text('Resume in POS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brand,
                      side: const BorderSide(color: AppColors.brand),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppFilledButton(
                    label: 'Finish Sale',
                    onPressed: () {
                      Navigator.of(context).pop();
                      onFinish();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(DraftSaleItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: getOutfitStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (item.variantName.isNotEmpty)
                  Text(
                    item.variantName,
                    style: getOutfitStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '×${AppFormatters.quantity(item.qty)}',
            style: getOutfitStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(width: 14),
          Text(
            AppFormatters.currency(item.lineTotal),
            style: getOutfitStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double value,
      {bool isBig = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: getOutfitStyle(
            color: isBig ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isBig ? FontWeight.w700 : FontWeight.w500,
            fontSize: isBig ? 16 : 13,
          ),
        ),
        Text(
          AppFormatters.currency(value),
          style: getOutfitStyle(
            color: color ?? (isBig ? AppColors.brand : AppColors.textSecondary),
            fontWeight: isBig ? FontWeight.w700 : FontWeight.w600,
            fontSize: isBig ? 18 : 13,
          ),
        ),
      ],
    );
  }
}
