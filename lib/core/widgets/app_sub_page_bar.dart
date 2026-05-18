import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';

/// A standardised [AppBar] for all sub-pages pushed from the main navigation
/// (e.g. Audit Logs, Expenses, Sales History, Stock Level).
///
/// Shows a back button automatically when the route can be popped.
///
/// ```dart
/// appBar: AppSubPageBar(title: 'Audit Logs'),
/// appBar: AppSubPageBar(title: 'Expenses', actions: [_someAction]),
/// ```
class AppSubPageBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AppSubPageBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(title, style: AppTextStyles.title(context)),
      leading: canPop
          ? IconButton(
              icon: const Icon(IconlyLight.arrow_left, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      automaticallyImplyLeading: false,
      actions: actions,
    );
  }
}
