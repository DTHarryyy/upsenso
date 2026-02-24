import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
}
