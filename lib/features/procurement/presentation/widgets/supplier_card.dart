import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_status_badge.dart';
import 'package:pos/features/procurement/presentation/cubit/supplier_state.dart';

/// Rich supplier row for the directory: identity + status on top, a procurement
/// metric strip (last order · orders · open value) below. Tap opens the detail;
/// the trailing menu / long-press opens quick actions.
class SupplierCard extends StatelessWidget {
  final SupplierListItem item;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  const SupplierCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final s = item.supplier;
    final m = item.metrics;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMenu,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(name: s.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: getOutfitStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (s.contactName != null &&
                            s.contactName!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            s.contactName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: getOutfitStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppStatusBadge(
                    label: s.isActive ? 'Active' : 'Inactive',
                    color: s.isActive ? AppColors.success : AppColors.textMuted,
                  ),
                  InkWell(
                    onTap: onMenu,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.more_vert,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderSoft),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Metric(
                    icon: IconlyLight.calendar,
                    label: m.lastOrderAt == null
                        ? 'No orders'
                        : AppFormatters.relativeDate(m.lastOrderAt!),
                  ),
                  const SizedBox(width: 14),
                  _Metric(
                    icon: IconlyLight.bag,
                    label: m.orderCount == 1 ? '1 order' : '${m.orderCount} orders',
                  ),
                  const Spacer(),
                  if (m.openValue > 0)
                    Text(
                      '${AppFormatters.currency(m.openValue)} open',
                      style: getOutfitStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
                      ),
                    )
                  else
                    Text(
                      'No open orders',
                      style: getOutfitStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
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

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.brand.withAlpha(20),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: getOutfitStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.brand,
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Metric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(
          label,
          style: getOutfitStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
