import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_status_badge.dart';
import 'package:pos/features/crm/domain/entities/customer.dart';

/// Customer row for the directory: avatar + name + contact subtitle + status,
/// with a contact-metric strip below. Tap opens the detail; the trailing menu /
/// long-press opens quick actions.
class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final subtitle = c.phone?.isNotEmpty == true
        ? c.phone!
        : (c.email?.isNotEmpty == true ? c.email! : null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMenu,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: Color(0x07101828),
                blurRadius: 14,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(name: c.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: getOutfitStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            c.phone?.isNotEmpty == true
                                ? IconlyLight.call
                                : IconlyLight.message,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: getOutfitStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: c.isActive ? 'Active' : 'Inactive',
                color: c.isActive ? AppColors.success : AppColors.textMuted,
              ),
              InkWell(
                onTap: onMenu,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(6, 2, 0, 2),
                  child: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppColors.textMuted,
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

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(12),
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
