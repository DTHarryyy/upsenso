import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:pos/bootstrap.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/errors/app_error_mapper.dart';

Future<void> main() async {
  // Use real URL paths (/home) instead of hash fragments (/#/home).
  // This prevents OAuth redirect URLs from having #/home appended after ?code=
  if (kIsWeb) usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    // In debug, keep default red-screen behaviour. In release, log silently.
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      debugPrint('[Flutter Error] ${details.exception}\n${details.stack}');
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[Unhandled Error] $error\n$stack');
    return true; // mark as handled so the platform doesn't crash the app
  };

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

  runApp(const AppInitializer());
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  Widget? _app;
  String? _error;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
 
  Future<void> _initializeApp() async {
    setState(() {
      _error = null;
      _retrying = true;
    });
    try {
      final app = await bootstrap();
      if (mounted) {
        setState(() {
          _app = app;
          _retrying = false;
        });
      }
    } catch (e, _) {
      if (mounted) {
        setState(() {
          _error = AppErrorMapper.message(e);
          _retrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && !_retrying) {
      return _ErrorScreen(message: _error!, onRetry: _initializeApp);
    }
    if (_app != null) return _app!;
    return const _SplashScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.store_outlined,
                  size: 56,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.brand),
              ),
              const SizedBox(height: 16),
              const Text(
                'Initializing...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Failed to Start',
                  
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
