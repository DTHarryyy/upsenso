import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/const/app_key.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:pos/features/auth/presentation/sign_in.dart';
import 'package:pos/features/auth/presentation/sign_up.dart';
import 'package:pos/features/auth/presentation/verification_page.dart';
import 'package:pos/features/business/domain/repositories/business_repository.dart';
import 'package:pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:pos/features/business/presentation/business_profile_page.dart';
import 'package:pos/features/inventory/inventory.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/features/onboarding/onboarding.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.onboarding,

    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(AppKey.seenOnboarding) ?? false;

      final location = state.matchedLocation;
      final goingToOnboarding = location == AppRoutes.onboarding;
      final goingToSignIn = location == AppRoutes.signIn;
      final goingToSignUp = location == AppRoutes.signUp;
      final goingToVerification = location == AppRoutes.verification;
      final goingToBusinessProfile = location == AppRoutes.businessProfile;
      final isAuthRoute = goingToSignIn || goingToSignUp || goingToVerification;

      if (!seen) {
        if (!goingToOnboarding) {
          return AppRoutes.onboarding;
        }
        return null;
      }

      final authRepository = sl<AuthRepository>();
      final businessRepository = sl<BusinessRepository>();
      final currentUser = authRepository.getCurrentUser();

      // Require auth for all non-auth routes after onboarding has been seen.
      if (currentUser == null) {
        if (goingToOnboarding) {
          return AppRoutes.signIn;
        }
        if (!isAuthRoute) {
          return AppRoutes.signIn;
        }
        return null;
      }

      // Force business setup until at least one business exists for this owner.
      var hasBusiness = false;
      try {
        hasBusiness =
            await businessRepository.getBusinessByOwner(currentUser.id) != null;
      } catch (_) {
        hasBusiness = false;
      }

      if (!hasBusiness && !goingToBusinessProfile) {
        return AppRoutes.businessProfile;
      }

      if (hasBusiness && (goingToOnboarding || isAuthRoute)) {
        return AppRoutes.home;
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
      GoRoute(
        path: AppRoutes.businessProfile,
        builder: (context, _) => BlocProvider(
          create: (_) => sl<BusinessBloc>(),
          child: const BusinessProfilePage(),
        ),
      ),
    ],
  );
}
