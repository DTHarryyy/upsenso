import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

class TotalBanner extends StatelessWidget {
  final double total;
  final int itemCount;
  final double tax;
  final String Function(double) fmt;

  const TotalBanner({
    super.key,
    required this.total,
    required this.itemCount,
    required this.tax,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 10,
            children: [
              Text(
                'Order Total',
                style: getOutfitStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Text(
                      '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                      style: getOutfitStyle(
                        color: AppColors.brand,
                        fontSize: 12,
                      ),
                    ),
                    if (tax > 0) ...[
                      Text(
                        '  ·  Tax ${fmt(tax)}',
                        style: getOutfitStyle(
                          color: AppColors.brand,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            fmt(total),
            style: getOutfitStyle(
              color: AppColors.brand,
              fontWeight: FontWeight.w800,
              fontSize: 30,
            ),
          ),
          
        ],
      ),
    );
  }
}