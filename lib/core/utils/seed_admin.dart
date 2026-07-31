import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';

/// Creates Auth user (if needed) + Firestore admin profile + default center/branch.
Future<void> seedAdminAndBranch({
  required String email,
  required String password,
  required String displayName,
}) async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  UserCredential credential;
  try {
    credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } else if (e.code == 'operation-not-allowed') {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'operation-not-allowed',
        message:
            'فعّل Email/Password من Firebase Console → Authentication → Sign-in method',
      );
    } else {
      rethrow;
    }
  }

  final uid = credential.user!.uid;
  final now = FieldValue.serverTimestamp();

  await firestore.collection(FirestorePaths.centers).doc(AppDefaults.centerId).set({
    'name': 'السنتر التعليمي',
    'phone': '',
    'address': '',
    'createdAt': now,
    'updatedAt': now,
  }, SetOptions(merge: true));

  await firestore.collection(FirestorePaths.branches).doc(AppDefaults.branchId).set({
    'centerId': AppDefaults.centerId,
    'name': 'الفرع الرئيسي',
    'timezone': 'Africa/Cairo',
    'currency': 'EGP',
    'locale': 'ar',
    'createdAt': now,
    'updatedAt': now,
  }, SetOptions(merge: true));

  await firestore.collection(FirestorePaths.users).doc(uid).set({
    'email': email.trim(),
    'displayName': displayName,
    'role': 'admin',
    'branchId': AppDefaults.branchId,
    'linkedStudentIds': <String>[],
    'parentIds': <String>[],
    'createdAt': now,
    'updatedAt': now,
  }, SetOptions(merge: true));
}

String describeFirebaseError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'operation-not-allowed' || 'configuration-not-found' =>
        'فعّل Email/Password من Firebase Console → Authentication → Sign-in method',
      'email-already-in-use' =>
        'البريد مستخدم مسبقاً — اكتب نفس كلمة المرور ثم سجّل الدخول، أو غيّر البريد',
      'weak-password' => 'كلمة المرور ضعيفة (٦ أحرف على الأقل)',
      'invalid-email' => 'بريد إلكتروني غير صالح',
      'wrong-password' || 'invalid-credential' || 'user-not-found' =>
        'البريد أو كلمة المرور غير صحيحة',
      'unauthorized-domain' =>
        'أضف localhost إلى Authorized domains في Authentication Settings',
      _ => '${error.code}: ${error.message ?? ''}',
    };
  }
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'رفض الصلاحيات — انشر قواعد Firestore ثم أعد المحاولة';
    }
    return error.message ?? error.code;
  }
  return error.toString();
}
