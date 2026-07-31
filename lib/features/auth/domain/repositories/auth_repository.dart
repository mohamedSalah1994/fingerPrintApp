import 'package:dartz/dartz.dart';
import 'package:fingerprint_app/core/error/failures.dart';
import 'package:fingerprint_app/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> watchAuthState();

  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> signOut();

  Future<Either<Failure, AppUser>> getCurrentUser();
}
