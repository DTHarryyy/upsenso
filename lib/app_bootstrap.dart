import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pos/app_router.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_strings.dart';
import 'package:pos/core/theme/theme_controller.dart';
import 'package:pos/theme_data.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
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
          // Enable mouse-drag scrolling on web (disabled by default in Flutter
          // web until explicitly opted in via dragDevices).
          scrollBehavior: kIsWeb ? const _WebScrollBehavior() : null,
          builder: (context, child) {
            // Clamp textScaler to 1.0 so OS / browser accessibility font-size
            // settings do not distort the POS layout.  Non-integer scale
            // factors produce fractional font sizes which land between physical
            // pixels in CanvasKit/SkWasm → blurry text.
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child: child!,
            );
          },
        );
      },
    );
  }
}

/// Enables scrolling with every pointer device on Flutter web.
///
/// Flutter web defaults to touch-only drag-to-scroll.  Adding mouse and
/// trackpad here lets users scroll lists with a mouse wheel _and_ by clicking
/// and dragging — the latter matches what users expect from desktop dashboards.
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
