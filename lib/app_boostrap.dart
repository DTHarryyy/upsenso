import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
          // On web, enable mouse-drag scrolling (disabled by default in
          // Flutter web until explicitly opted in).
          scrollBehavior: kIsWeb ? const _WebScrollBehavior() : null,
          builder: (context, child) {
            // Clamp textScaler to 1.0 so OS / browser accessibility font
            // size settings do not distort the POS layout. Non-integer
            // scaling factors cause sub-pixel glyph placement which
            // manifests as blurry or misaligned text in CanvasKit.
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: Container(color: AppColors.background, child: child!),
            );
          },
        );
      },
    );
  }
}

/// Enables scrolling with a mouse pointer on Flutter web (CanvasKit renderer
/// only accepts touch events by default). Applies only when [kIsWeb] is true.
class _WebScrollBehavior extends MaterialScrollBehavior {
  const _WebScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}
