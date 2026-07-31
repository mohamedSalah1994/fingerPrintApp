import 'package:equatable/equatable.dart';

enum SalaryMethod { perSession, perStudent, monthlyFixed, hybrid }

extension SalaryMethodX on SalaryMethod {
  String get value => name;

  static SalaryMethod fromString(String? v) {
    return SalaryMethod.values.firstWhere(
      (e) => e.name == v,
      orElse: () => SalaryMethod.perSession,
    );
  }

  String get labelAr => switch (this) {
        SalaryMethod.perSession => 'بالحصة',
        SalaryMethod.perStudent => 'بعدد الطلاب',
        SalaryMethod.monthlyFixed => 'شهري ثابت',
        SalaryMethod.hybrid => 'مختلط',
      };
}

class Teacher extends Equatable {
  const Teacher({
    required this.id,
    required this.name,
    required this.branchId,
    this.phone,
    this.userId,
    this.salaryMethod = SalaryMethod.perSession,
    this.subjectIds = const [],
    this.status = 'active',
  });

  final String id;
  final String name;
  final String branchId;
  final String? phone;
  final String? userId;
  final SalaryMethod salaryMethod;
  final List<String> subjectIds;
  final String status;

  @override
  List<Object?> get props =>
      [id, name, branchId, phone, userId, salaryMethod, subjectIds, status];
}

class Student extends Equatable {
  const Student({
    required this.id,
    required this.name,
    required this.branchId,
    this.phone,
    this.userId,
    this.gradeId,
    this.parentIds = const [],
    this.status = 'active',
  });

  final String id;
  final String name;
  final String branchId;
  final String? phone;
  final String? userId;
  final String? gradeId;
  final List<String> parentIds;
  final String status;

  @override
  List<Object?> get props =>
      [id, name, branchId, phone, userId, gradeId, parentIds, status];
}

class ParentProfile extends Equatable {
  const ParentProfile({
    required this.id,
    required this.name,
    required this.branchId,
    this.phone,
    this.userId,
    this.studentIds = const [],
  });

  final String id;
  final String name;
  final String branchId;
  final String? phone;
  final String? userId;
  final List<String> studentIds;

  @override
  List<Object?> get props => [id, name, branchId, phone, userId, studentIds];
}

class StudyGroup extends Equatable {
  const StudyGroup({
    required this.id,
    required this.name,
    required this.branchId,
    required this.gradeId,
    required this.subjectId,
    this.teacherId,
    this.classroomId,
    this.capacity = 20,
  });

  final String id;
  final String name;
  final String branchId;
  final String gradeId;
  final String subjectId;
  final String? teacherId;
  final String? classroomId;
  final int capacity;

  @override
  List<Object?> get props => [
        id,
        name,
        branchId,
        gradeId,
        subjectId,
        teacherId,
        classroomId,
        capacity,
      ];
}

class ScheduleSlot extends Equatable {
  const ScheduleSlot({
    required this.id,
    required this.groupId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.branchId,
  });

  final String id;
  final String groupId;
  /// 1 = Monday ... 7 = Sunday
  final int weekday;
  final String startTime;
  final String endTime;
  final String branchId;

  @override
  List<Object?> get props =>
      [id, groupId, weekday, startTime, endTime, branchId];
}

enum EnrollmentType { full, partial }

class Enrollment extends Equatable {
  const Enrollment({
    required this.id,
    required this.studentId,
    required this.gradeId,
    required this.type,
    required this.branchId,
    this.fee = 0,
    this.note,
    this.status = 'active',
  });

  final String id;
  final String studentId;
  final String gradeId;
  final EnrollmentType type;
  final String branchId;
  final double fee;
  final String? note;
  final String status;

  @override
  List<Object?> get props =>
      [id, studentId, gradeId, type, branchId, fee, note, status];
}
