import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fingerprint_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fingerprint_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fingerprint_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:fingerprint_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fingerprint_app/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:fingerprint_app/features/settings/presentation/cubit/theme_cubit.dart';

final sl = GetIt.instance;

Future<SharedPreferences> _loadPreferences() async {
  try {
    return await SharedPreferences.getInstance();
  } catch (e) {
    // Hot restart after adding a plugin does not register channels on web.
    final missingPlugin = e is MissingPluginException ||
        e.toString().contains('MissingPluginException');
    if (!missingPlugin) rethrow;
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }
}

Future<void> configureDependencies() async {
  if (sl.isRegistered<AuthRepository>()) return;

  final prefs = await _loadPreferences();
  sl.registerSingleton<SharedPreferences>(prefs);

  sl.registerLazySingleton<AuthRemoteDataSource>(AuthRemoteDataSource.new);
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerFactory(() => AuthCubit(sl()));

  sl.registerLazySingleton<AdminRepository>(AdminRepositoryImpl.new);

  sl.registerLazySingleton(() => LocaleCubit(sl()));
  sl.registerLazySingleton(() => ThemeCubit(sl()));
}
