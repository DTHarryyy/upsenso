import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/features/inventory/domain/entities/stock_shortage.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';

Future<bool> showStockShortageDialog({
  required BuildContext context,
  required List<CartItem> items,
  required List<StockShortage> shortages,
}) async {
  final itemByVariant = {for (final item in items) item.variantId: item};
  final proceed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Not enough stock'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 360),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The following items do not have enough stock. You can cancel '
                'and adjust the order, or proceed and record negative stock.',
                style: getOutfitStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              ...shortages.map((shortage) {
                final item = itemByVariant[shortage.variantId];
                final variant = item?.variant.trim() ?? '';
                final label = item == null
                    ? 'Item'
                    : variant.isEmpty || variant == 'Default'
                    ? item.name
                    : '${item.name} ($variant)';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: getOutfitStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Requested ${AppFormatters.quantity(shortage.requested)}'
                          ' · Available ${AppFormatters.quantity(shortage.available)}',
                          style: getOutfitStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Proceed Anyway'),
        ),
      ],
    ),
  );
  return proceed == true;
}
