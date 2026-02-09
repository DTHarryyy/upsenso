import 'package:flutter/material.dart';
import 'package:pos/app_gate.dart';
import 'package:pos/core/const/app_strings.dart';
import 'package:pos/theme_data.dart';

class AppBoostrap extends StatelessWidget {
  const AppBoostrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: buildAppTheme(),
      home: const AppGate(),
    );
  }
}
