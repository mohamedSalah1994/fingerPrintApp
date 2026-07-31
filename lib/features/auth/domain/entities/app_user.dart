import 'package:equatable/equatable.dart';

enum UserRole { admin, teacher, student, parent }

extension UserRoleX on UserRole {
  String get value => name;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.student,
    );
  }

  String get labelAr => switch (this) {
        UserRole.admin => 'مدير',
        UserRole.teacher => 'مدرس',
        UserRole.student => 'طالب',
        UserRole.parent => 'ولي أمر',
      };
}

class AppUser extends Equatable {
  const AppUser({
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
  final UserRole role;
  final String? phone;
  final String? branchId;
  final List<String> linkedStudentIds;
  final List<String> parentIds;

  bool get isAdmin => role == UserRole.admin;

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        role,
        phone,
        branchId,
        linkedStudentIds,
        parentIds,
      ];
}
