import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/launch_external_uri.dart';
import 'package:pos/core/widgets/user_avatar.dart';
import 'package:pos/features/crm/domain/entities/customer.dart';

/// Identity header for the customer information page: avatar, name, a muted
/// contact subtitle, and one-tap Call/Email/Edit actions. Each action only
/// renders when its data (or permission) is actually available.
class CustomerProfileHeader extends StatelessWidget {
  final Customer customer;
  final bool canManage;
  final VoidCallback onEdit;

  const CustomerProfileHeader({
    super.key,
    required this.customer,
    required this.canManage,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final hasPhone = c.phone?.isNotEmpty == true;
    final hasEmail = c.email?.isNotEmpty == true;
    final subtitle = hasPhone
        ? c.phone!
        : (hasEmail ? c.email! : 'No contact details');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(name: c.name, radius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: getOutfitStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: getOutfitStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasPhone || hasEmail || canManage) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.borderSoft),
            const SizedBox(height: 12),
            Row(
              children: [
                if (hasPhone)
                  Expanded(
                    child: _QuickAction(
                      icon: IconlyLight.call,
                      label: 'Call',
                      onTap: () => launchExternalUri(
                        context,
                        'tel:${c.phone}',
                        feature: 'CustomerDetail',
                      ),
                    ),
                  ),
                if (hasPhone && (hasEmail || canManage))
                  const SizedBox(width: 8),
                if (hasEmail)
                  Expanded(
                    child: _QuickAction(
                      icon: IconlyLight.message,
                      label: 'Email',
                      onTap: () => launchExternalUri(
                        context,
                        'mailto:${c.email}',
                        feature: 'CustomerDetail',
                      ),
                    ),
                  ),
                if (hasEmail && canManage) const SizedBox(width: 8),
                if (canManage)
                  Expanded(
                    child: _QuickAction(
                      icon: IconlyLight.edit,
                      label: 'Edit',
                      onTap: onEdit,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact pill action used inside the profile header row — follows
/// [AppSoftButton]'s visual language but stretches to share the row evenly.
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
