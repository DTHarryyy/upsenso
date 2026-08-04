import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/launch_external_uri.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/features/crm/domain/entities/customer.dart';

/// Contact details for the customer information page. Phone and email rows
/// are tappable (launch the dialer/mail app); address is display-only.
class CustomerContactCard extends StatelessWidget {
  final Customer customer;

  const CustomerContactCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final rows = <Widget>[
      if (c.phone?.isNotEmpty == true)
        _ContactRow(
          icon: IconlyLight.call,
          value: c.phone!,
          onTap: () => launchExternalUri(
            context,
            'tel:${c.phone}',
            feature: 'CustomerDetail',
          ),
        ),
      if (c.email?.isNotEmpty == true)
        _ContactRow(
          icon: IconlyLight.message,
          value: c.email!,
          onTap: () => launchExternalUri(
            context,
            'mailto:${c.email}',
            feature: 'CustomerDetail',
          ),
        ),
      if (c.address?.isNotEmpty == true)
        _ContactRow(icon: IconlyLight.location, value: c.address!),
    ];

    return AppSectionCard(
      title: 'Contact',
      icon: IconlyBold.profile,
      children: rows.isEmpty
          ? [
              Text(
                'No contact details yet',
                style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ]
          : rows,
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  const _ContactRow({required this.icon, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: onTap == null ? AppColors.textMuted : AppColors.brand,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: getOutfitStyle(
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: onTap == null
          ? row
          : InkWell(borderRadius: BorderRadius.circular(6), onTap: onTap, child: row),
    );
  }
}
