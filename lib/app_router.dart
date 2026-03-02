import 'package:go_router/go_router.dart';
import 'package:pos/core/const/app_key.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/features/auth/presentation/sign_in.dart';
import 'package:pos/features/auth/presentation/sign_up.dart';
import 'package:pos/features/auth/presentation/verification_page.dart';
import 'package:pos/features/inventory/inventory.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/features/onboarding/onboarding.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.onboarding,

    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(AppKey.seenOnboarding) ?? false;

      final goingToOnboarding = state.matchedLocation == AppRoutes.onboarding;

      if (!seen && !goingToOnboarding) {
        return AppRoutes.onboarding;
      }

      if (seen && goingToOnboarding) {
        return AppRoutes.signUp;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, _) => const Onboarding(),
      ),
      GoRoute(path: AppRoutes.signIn, builder: (context, _) => const SignIn()),
      GoRoute(path: AppRoutes.signUp, builder: (context, _) => const SignUp()),
      GoRoute(
        path: AppRoutes.verification,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerificationPage(email: email);
        },
      ),
      GoRoute(path: AppRoutes.home, builder: (context, _) => const Inventory()),
    ],
  );
}
