import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/app_boostrap.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //TODO: Remove this after testing onboarding multiple times. This is just to reset the onboarding state so it can be tested again and again without having to clear app data or uninstall the app.
  final sp = await SharedPreferences.getInstance();
  sp.setBool('seen_onboarding', false);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarDividerColor: AppColors.surface,
    ),
  );
  runApp(const AppBoostrap());
}
