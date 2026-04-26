import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/const/app_key.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/features/ai_assistant/pagges/ai_chat_page.dart';
import 'package:pos/features/ai_assistant/bloc/ai_chat_bloc.dart';
import 'package:pos/features/ai_assistant/services/ai_pipeline.dart';
import 'package:pos/features/ai_assistant/services/model_download_service.dart';
import 'package:pos/features/ai_assistant/services/model_manager.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/auth/presentation/sign_in.dart';
import 'package:pos/features/auth/presentation/sign_up.dart';
import 'package:pos/features/auth/presentation/verification_page.dart';
import 'package:pos/features/auth/presentation/forgot_password_page.dart';
import 'package:pos/features/auth/presentation/reset_password_verification_page.dart';
import 'package:pos/features/auth/presentation/reset_password_page.dart';
import 'package:pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:pos/features/business/presentation/business_profile_page.dart';
import 'package:pos/features/business/presentation/business_profile_setup.dart';
import 'package:pos/features/home/presentation/main_navigation_page.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/features/inventory/inventory.dart';
import 'package:pos/features/pos/presentation/pos_terminal_page.dart';
import 'package:pos/features/products/pages/add_products.dart';
import 'package:pos/features/profile/presentation/profile_page.dart';
import 'package:pos/features/expenses/presentation/expenses_page.dart';
import 'package:pos/features/sales/sales_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/features/onboarding/onboarding.dart';


class _AuthRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthRefreshNotifier(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.onboarding,

    // Re-run redirect whenever AuthBloc emits — critical for instant sign-out.
    refreshListenable: _AuthRefreshNotifier(sl<AuthBloc>().stream),

    redirect: (context, state) async {
      final location = state.matchedLocation;

      final goingToOnboarding = location == AppRoutes.onboarding;
      final goingToSignIn = location == AppRoutes.signIn;
      final goingToSignUp = location == AppRoutes.signUp;
      final goingToVerification = location == AppRoutes.verification;
      final goingToForgotPassword = location == AppRoutes.forgotPassword;
      final goingToResetVerification =
          location.startsWith(AppRoutes.resetPasswordVerification);
      final goingToResetPassword =
          location.startsWith(AppRoutes.resetPassword);
      final goingToBusinessProfileSetup =
          location == AppRoutes.businessProfileSetup;
      final isPublicAuthRoute =
          goingToSignIn || goingToSignUp || goingToVerification;
      final isPasswordResetRoute = goingToForgotPassword ||
          goingToResetVerification ||
          goingToResetPassword;
      final isAuthRoute = isPublicAuthRoute || isPasswordResetRoute;

      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(AppKey.seenOnboarding) ?? false;

      if (!seen) {
        if (!goingToOnboarding) return AppRoutes.onboarding;
        return null;
      }

      final authBloc = sl<AuthBloc>();
      final authState = authBloc.state;

      if (authState is AuthUnauthenticated) {
        if (goingToOnboarding || !isAuthRoute) return AppRoutes.signIn;
        return null;
      }

      // For any transient state (loading, OAuthInProgress, etc.) don't
      // redirect — wait for the BLoC to settle into Authenticated or
      // Unauthenticated before making a routing decision.
      if (authState is! AuthAuthenticated) return null;

      // Use the user carried by the BLoC state as the single source of
      // truth. The BLoC already ran getUserBusinessContext and populated
      // businessId before emitting AuthAuthenticated, so we don't need to
      // re-query the repository here.
      final user = authState.user;
      final hasBusiness = (user.businessId?.trim() ?? '').isNotEmpty;

      if (!hasBusiness && !goingToBusinessProfileSetup && !isPasswordResetRoute) {
        return AppRoutes.businessProfileSetup;
      }

      if (hasBusiness && (goingToOnboarding || isPublicAuthRoute)) {
        return AppRoutes.home;
      }

      return null;
    },

    routes: [
      GoRoute(
          path: AppRoutes.saleshistory,
          builder: (context, _) => const SalesHistory()),
      GoRoute(
          path: AppRoutes.expenses,
          builder: (context, _) => const ExpensesPage()),
      GoRoute(
          path: AppRoutes.businessProfile,
          builder: (context, _) => const BusinessProfilePage()),
      GoRoute(
          path: AppRoutes.posTerminal,
          builder: (context, _) => const PosTerminalPage()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, _) => const Onboarding(),
      ),
      GoRoute(
          path: AppRoutes.signIn, builder: (context, _) => const SignIn()),
      GoRoute(
          path: AppRoutes.signUp, builder: (context, _) => const SignUp()),
      GoRoute(
          path: AppRoutes.inventory,
          builder: (context, _) => const Inventory()),
      GoRoute(
        path: AppRoutes.verification,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerificationPage(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPasswordVerification,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordVerificationPage(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordPage(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, _) => const MainNavigationPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, _) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.businessProfileSetup,
        builder: (context, _) => BlocProvider(
          create: (_) => sl<BusinessBloc>(),
          child: const BusinessProfileSetup(),
        ),
      ),
      GoRoute(
        path: AppRoutes.addProduct,
        builder: (context, state) => AddProductsPage(
          initialBarcode: state.extra as String?,
        ),
      ),
      GoRoute(
        path: AppRoutes.editProduct,
        builder: (context, state) => AddProductsPage(
          productToEdit: state.extra as ProductsTableData?,
        ),
      ),
      GoRoute(
        path: AppRoutes.aiChat,
        builder: (context, _) {
          final authRepo = sl<AuthRepository>();
          final currentUser = authRepo.getCurrentUser();
          final branchCubit = context.read<BranchCubit>();
          return BlocProvider(
            create: (_) => AiChatBloc(
              pipeline: sl<AiPipeline>(),
              downloadService: sl<ModelDownloadService>(),
              modelManager: sl<ModelManager>(),
              businessId: currentUser?.businessId ?? '',
              cashierId: currentUser?.id ?? '',
              selectedBranchId: () =>
                  branchCubit.getSelectedBranchIdForFiltering(),
            ),
            child: const AiChatPage(),
          );
        },
      ),
    ],
  );
}
