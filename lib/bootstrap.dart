import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nobodywho/nobodywho.dart' as nobodywho;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/app_boostrap.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';

Future<Widget> bootstrap() async {

  try {
    await dotenv
        .load(fileName: ".env")
        .timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            return;
          },
        );
  } catch (e) {
    debugPrint('Failed to load .env file: $e - environment variables may be missing');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();

  if (supabaseUrl == null || supabaseUrl.isEmpty ||
      supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    throw Exception(
      'App configuration is missing. Please reinstall the app or contact support.',
    );
  }

  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey)
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception(
        'Connection timed out during startup. Please check your internet and try again.',
      ),
    );
  } catch (e) {
    // Supabase.initialize() is lightweight — it doesn't make network calls.
    // A failure here means the credentials are malformed, not a network issue.
    rethrow;
  }

  try {
    await initDI().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Dependency injection initialization timeout');
      },
    );
  } catch (e) {
    rethrow;
  }

  try {
    await nobodywho.NobodyWho.init();
  } catch (e) {
    debugPrint('NobodyWho init failed: $e — rule-based parser will be used');
  }

  final authBloc = sl<AuthBloc>();
  authBloc.add(AuthStarted());

  await authBloc.stream
      .firstWhere(
        (state) => state is! AuthUnknown,
        orElse: () => authBloc.state,
      )
      .timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          return authBloc.state;
        },
      );

  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: authBloc),
      BlocProvider<BranchCubit>(create: (_) => sl<BranchCubit>()),
    ],
    child: const AppBoostrap(),
  );
}
