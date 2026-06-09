import 'package:flutter/material.dart';
import 'package:pos/core/const/font_utils.dart';

// Gold=Owner, Orange=Admin, Purple=Manager, Blue=Cashier, Teal=Inventory, Gray=unknown
class EmployeeRoleBadge extends StatelessWidget {
  final String? roleName;

  const EmployeeRoleBadge({super.key, required this.roleName});

  static _RoleStyle _resolve(String? name) {
    final n = name?.toLowerCase().trim() ?? '';

    if (n == 'business owner' || n == 'owner' || n == 'super admin' || n == 'superadmin') {
      return const _RoleStyle(
        bg: Color(0xFFFEF3C7),
        fg: Color(0xFFB45309),
        dot: Color(0xFFF59E0B),
        label: 'Owner',
      );
    }
    if (n.contains('manager')) {
      return const _RoleStyle(
        bg: Color(0xFFF3E8FF),
        fg: Color(0xFF7C3AED),
        dot: Color(0xFF8B5CF6),
        label: 'Manager',
      );
    }
    if (n.contains('cashier')) {
      return const _RoleStyle(
        bg: Color(0xFFDBEAFE),
        fg: Color(0xFF1D4ED8),
        dot: Color(0xFF3B82F6),
        label: 'Cashier',
      );
    }
    if (n.contains('inventory')) {
      return const _RoleStyle(
        bg: Color(0xFFCCFBF1),
        fg: Color(0xFF0F766E),
        dot: Color(0xFF14B8A6),
        label: 'Inventory',
      );
    }

    return _RoleStyle(
      bg: const Color(0xFFF1F5F9),
      fg: const Color(0xFF64748B),
      dot: const Color(0xFF94A3B8),
      label: name ?? 'Staff',
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolve(roleName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        style.label,
        style: getOutfitStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: style.fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _RoleStyle {
  final Color bg;
  final Color fg;
  final Color dot;
  final String label;

  const _RoleStyle({
    required this.bg,
    required this.fg,
    required this.dot,
    required this.label,
  });
}
