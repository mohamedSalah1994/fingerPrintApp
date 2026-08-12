import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fingerprint_app/firebase_options.dart';

/// Creates Auth users without replacing the signed-in admin session.
class AuthAccountService {
  AuthAccountService();

  static const _secondaryName = 'SecondaryAuth';
  FirebaseApp? _secondaryApp;

  Future<FirebaseAuth> _secondaryAuth() async {
    _secondaryApp ??= Firebase.apps.any((a) => a.name == _secondaryName)
        ? Firebase.app(_secondaryName)
        : await Firebase.initializeApp(
            name: _secondaryName,
            options: DefaultFirebaseOptions.currentPlatform,
          );
    return FirebaseAuth.instanceFor(app: _secondaryApp!);
  }

  /// Returns the new user's uid.
  Future<String> createEmailPasswordUser({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final auth = await _secondaryAuth();
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'internal-error',
          message: 'User creation returned null',
        );
      }
      if (displayName != null && displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
      }
      return user.uid;
    } finally {
      await auth.signOut();
    }
  }
}

DateTime? parseFirestoreDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
