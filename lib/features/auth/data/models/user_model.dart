import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/features/auth/domain/entities/app_user.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.phone,
    this.branchId,
    this.linkedStudentIds = const [],
    this.parentIds = const [],
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final String? phone;
  final String? branchId;
  final List<String> linkedStudentIds;
  final List<String> parentIds;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: data['role'] as String? ?? 'student',
      phone: data['phone'] as String?,
      branchId: data['branchId'] as String?,
      linkedStudentIds: List<String>.from(data['linkedStudentIds'] ?? const []),
      parentIds: List<String>.from(data['parentIds'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'role': role,
        'phone': phone,
        'branchId': branchId ?? AppDefaults.branchId,
        'linkedStudentIds': linkedStudentIds,
        'parentIds': parentIds,
      };

  AppUser toEntity() => AppUser(
        id: id,
        email: email,
        displayName: displayName,
        role: UserRoleX.fromString(role),
        phone: phone,
        branchId: branchId,
        linkedStudentIds: linkedStudentIds,
        parentIds: parentIds,
      );
}
