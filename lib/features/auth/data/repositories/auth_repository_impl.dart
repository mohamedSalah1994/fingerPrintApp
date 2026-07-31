import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fingerprint_app/core/error/failures.dart';
import 'package:fingerprint_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fingerprint_app/features/auth/domain/entities/app_user.dart';
import 'package:fingerprint_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<AppUser?> watchAuthState() async* {
    await for (final firebaseUser in _remote.authStateChanges()) {
      if (firebaseUser == null) {
        yield null;
        continue;
      }
      try {
        final profile = await _remote.fetchUserProfile(firebaseUser.uid);
        yield profile?.toEntity();
      } catch (_) {
        // Keep session; UI/signIn path handles missing profile.
        yield null;
      }
    }
  }

  @override
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _remote.signIn(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        return const Left(AuthFailure('تعذر تسجيل الدخول'));
      }
      final profile = await _remote.fetchUserProfile(uid);
      if (profile == null) {
        await _remote.signOut();
        return const Left(
          AuthFailure(
            'لا يوجد ملف مستخدم في Firestore. اضغط «إعداد مدير (تطوير فقط)» أولاً.',
          ),
        );
      }
      return Right(profile.toEntity());
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthCode(e.code, e.message)));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const Left(
          AuthFailure(
            'رفض صلاحيات Firestore. تأكد من نشر القواعد ثم أعد إعداد المدير.',
          ),
        );
      }
      return Left(AuthFailure(e.message ?? e.code));
    } catch (e) {
      return Left(AuthFailure(_mapAuthError(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remote.signOut();
      return const Right(unit);
    } catch (_) {
      return const Left(ServerFailure('تعذر تسجيل الخروج'));
    }
  }

  @override
  Future<Either<Failure, AppUser>> getCurrentUser() async {
    try {
      final firebaseUser = _remote.currentFirebaseUser;
      if (firebaseUser == null) {
        return const Left(AuthFailure('غير مسجل الدخول'));
      }
      final profile = await _remote.fetchUserProfile(firebaseUser.uid);
      if (profile == null) {
        return const Left(AuthFailure('ملف المستخدم غير موجود'));
      }
      return Right(profile.toEntity());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  String _mapAuthCode(String code, String? message) {
    return switch (code) {
      'operation-not-allowed' || 'configuration-not-found' =>
        'فعّل Email/Password من Firebase Console → Authentication → Sign-in method',
      'user-not-found' || 'wrong-password' || 'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' =>
        'البريد أو كلمة المرور غير صحيحة — أو الحساب غير موجود. جرّب «إعداد مدير»',
      'invalid-email' => 'البريد الإلكتروني غير صالح',
      'user-disabled' => 'هذا الحساب معطّل',
      'too-many-requests' => 'محاولات كثيرة. حاول لاحقاً',
      'network-request-failed' => 'تحقق من الاتصال بالإنترنت',
      'unauthorized-domain' =>
        'النطاق غير مصرح به في Firebase Authentication → Settings → Authorized domains',
      _ => 'فشل تسجيل الدخول ($code)${message != null ? ': $message' : ''}',
    };
  }

  String _mapAuthError(Object e) {
    final text = e.toString();
    final codeMatch = RegExp(r'auth/([a-z0-9-]+)', caseSensitive: false)
        .firstMatch(text);
    if (codeMatch != null) {
      return _mapAuthCode(codeMatch.group(1)!, null);
    }
    if (text.contains('operation-not-allowed') ||
        text.contains('configuration-not-found')) {
      return _mapAuthCode('operation-not-allowed', null);
    }
    if (text.contains('invalid-credential') ||
        text.contains('wrong-password') ||
        text.contains('user-not-found')) {
      return _mapAuthCode('invalid-credential', null);
    }
    return 'فشل تسجيل الدخول: $text';
  }
}
