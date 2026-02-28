import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/bootstrap.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sp = await SharedPreferences.getInstance();
  // TODO:remove For testing purposes, we can reset the onboarding status by uncommenting the line below.
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
  await bootstrap();
}
