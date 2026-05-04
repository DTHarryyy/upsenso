import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/navigation/sidebar_nav_cubit.dart';
import 'package:pos/features/business/presentation/business_profile_page.dart';
import 'package:pos/features/profile/presentation/profile_page.dart';
import 'package:pos/features/settings/presentation/receipt_settings_page.dart';

/// Shell page rendered for the Settings shell branch (index 7).
///
/// Uses an [IndexedStack] driven by [SidebarNavCubit] so that switching
/// sub-modules is instant (no route push/pop) and every sub-module widget
/// stays alive while on this branch.
class SettingsShellPage extends StatelessWidget {
  const SettingsShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SidebarNavCubit, SettingsSubPage>(
      builder: (context, subPage) {
        return IndexedStack(
          index: subPage.index,
          children: const [
            ReceiptSettingsPage(),
            BusinessProfilePage(),
            ProfilePage(),
          ],
        );
      },
    );
  }
}
