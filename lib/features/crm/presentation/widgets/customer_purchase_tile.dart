import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/features/crm/domain/entities/customer_purchase.dart';

/// One purchase row in the customer detail page's history list.
class CustomerPurchaseTile extends StatelessWidget {
  final CustomerPurchase purchase;

  const CustomerPurchaseTile({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    final p = purchase;
    final label = p.invoiceNumber?.isNotEmpty == true
        ? p.invoiceNumber!
        : 'Sale';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(IconlyBold.bag, size: 16, color: AppColors.brand),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: getOutfitStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${AppFormatters.relativeDate(p.createdAt)} · '
                  '${p.itemCount} ${p.itemCount == 1 ? 'item' : 'items'} · '
                  '${p.paymentMethod}',
                  style: getOutfitStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            AppFormatters.currency(p.totalAmount),
            style: getOutfitStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
