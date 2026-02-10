import 'package:flutter/material.dart';
import 'package:pos/app_router.dart';
import 'package:pos/core/const/app_strings.dart';
import 'package:pos/theme_data.dart';

class AppBoostrap extends StatelessWidget {
  const AppBoostrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: buildAppTheme(),
      routerConfig: AppRouter.router,
    );
  }
}
