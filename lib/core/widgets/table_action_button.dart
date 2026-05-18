import 'package:flutter/material.dart';

/// A small icon button used inside table rows for actions such as
/// view, edit, approve, reject, etc.
///
/// Example:
/// ```dart
/// TableActionButton(
///   icon: Icons.visibility_outlined,
///   color: AppColors.brand,
///   background: AppColors.brandSoft,
///   tooltip: 'View',
///   onTap: () => doSomething(),
/// )
/// ```
class TableActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String tooltip;
  final VoidCallback onTap;

  const TableActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}
