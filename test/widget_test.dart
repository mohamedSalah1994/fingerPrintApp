import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fingerprint_app/app/theme/app_theme.dart';
import 'package:fingerprint_app/core/error/failures.dart';
import 'package:fingerprint_app/features/auth/domain/entities/app_user.dart';
import 'package:fingerprint_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:fingerprint_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fingerprint_app/features/auth/presentation/pages/login_page.dart';
import 'package:fingerprint_app/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:fingerprint_app/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> watchAuthState() => Stream.value(null);

  @override
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  }) async =>
      const Left(AuthFailure('test'));

  @override
  Future<Either<Failure, Unit>> signOut() async => const Right(unit);

  @override
  Future<Either<Failure, AppUser>> getCurrentUser() async =>
      const Left(AuthFailure('test'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login page renders', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit(_FakeAuthRepository())),
          BlocProvider(create: (_) => LocaleCubit(prefs)),
          BlocProvider(create: (_) => ThemeCubit(prefs)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ar'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('نظام إدارة السنتر'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
