import 'package:flutter/material.dart';
import 'package:pos/app_router.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_strings.dart';
import 'package:pos/core/theme/theme_controller.dart';
import 'package:pos/theme_data.dart';

class AppBoostrap extends StatefulWidget {
  const AppBoostrap({super.key});

  @override
  State<AppBoostrap> createState() => _AppBoostrapState();
}

class _AppBoostrapState extends State<AppBoostrap> {
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = sl<ThemeController>();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: AppStrings.appName,
          theme: buildLightAppTheme(),
          darkTheme: buildDarkAppTheme(),
          themeMode: _themeController.themeMode,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            return Container(color: AppColors.background, child: child);
          },
        );
      },
    );
  }
}
