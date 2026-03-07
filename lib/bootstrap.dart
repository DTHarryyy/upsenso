import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/app_boostrap.dart'; // keep this ONLY if your file is really named this
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await initDI();

  // Keep auth session across restarts for proper authenticated API calls.
  // final prefs = await SharedPreferences.getInstance();
  // await Supabase.instance.client.auth.signOut();
  // await prefs.setBool('seen_onboarding', false);

  // TODO: DEBUG - Check Drift database on app restart
  await sl<AppDatabase>().debugPrintAllTables();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()..add(AuthStarted())),
      ],
      child: const AppBoostrap(),
    ),
  );
}
