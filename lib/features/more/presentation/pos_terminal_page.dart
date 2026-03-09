import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';

class PosTerminalPage extends StatelessWidget {
  const PosTerminalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('POS Terminal'), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.point_of_sale,
                          size: 80,
                          color: AppColors.brand,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'POS Terminal',
                          style: AppTextStyles.headline(
                            context,
                          ).copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start adding items to cart',
                          style: AppTextStyles.body(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Order',
                            style: AppTextStyles.title(
                              context,
                            ).copyWith(color: AppColors.textPrimary),
                          ),
                          Text(
                            '0 items',
                            style: AppTextStyles.body(
                              context,
                            ).copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Cart is empty',
                            style: AppTextStyles.body(
                              context,
                            ).copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: AppTextStyles.title(
                              context,
                            ).copyWith(color: AppColors.textPrimary),
                          ),
                          Text(
                            '\$0.00',
                            style: AppTextStyles.money(
                              context,
                            ).copyWith(color: AppColors.brand),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: null,
                          child: const Text('Checkout'),
                        ),
                      ),
                    ],
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
