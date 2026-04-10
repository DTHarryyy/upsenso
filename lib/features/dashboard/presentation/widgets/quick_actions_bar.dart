import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/routes/app_routes.dart';

class QuickActionsBar extends StatelessWidget {
  final VoidCallback? onNewSale;

  const QuickActionsBar({super.key, this.onNewSale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ActionChip(
              icon: Icons.shopping_cart_outlined,
              label: 'New Sale',
              onPressed: () => onNewSale?.call(),
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.add_box_outlined,
              label: 'Add Product',
              onPressed: () => context.push(AppRoutes.addProduct),
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.inventory_2_outlined,
              label: 'Stock Adjust',
              onPressed: () => context.push(AppRoutes.inventory),
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.attach_money,
              label: 'Expense',
              onPressed: () {
                // TODO: Navigate to Expense page
              },
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.swap_horiz,
              label: 'Transfer',
              onPressed: () {
                // TODO: Navigate to Transfer page
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}
