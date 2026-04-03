import 'package:flutter/material.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

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
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.add_box_outlined,
              label: 'Add Product',
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.inventory_2_outlined,
              label: 'Stock Adjust',
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.attach_money,
              label: 'Expense',
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.swap_horiz,
              label: 'Transfer',
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

  const _ActionChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
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
