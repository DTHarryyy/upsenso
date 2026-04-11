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

  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    ).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw Exception('Supabase initialization timeout');
      },
    );
  } catch (e) {
    debugPrint('Supabase init failed: $e - app will run in offline mode');
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
