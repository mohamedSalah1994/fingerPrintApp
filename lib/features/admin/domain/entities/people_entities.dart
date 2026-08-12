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
    this.photoUrl,
    this.salaryMethod = SalaryMethod.perSession,
    this.subjectIds = const [],
    this.gradeIds = const [],
    this.status = 'active',
  });

  final String id;
  final String name;
  final String branchId;
  final String? phone;
  final String? userId;
  final String? photoUrl;
  final SalaryMethod salaryMethod;
  final List<String> subjectIds;
  /// Grades this teacher teaches (can be multiple).
  final List<String> gradeIds;
  final String status;

  @override
  List<Object?> get props => [
        id,
        name,
        branchId,
        phone,
        userId,
        photoUrl,
        salaryMethod,
        subjectIds,
        gradeIds,
        status,
      ];
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
    this.subjectIds = const [],
    this.enrollmentType = EnrollmentType.full,
    this.status = 'active',
  });

  final String id;
  final String name;
  final String branchId;
  final String? phone;
  final String? userId;
  final String? gradeId;
  final List<String> parentIds;
  /// When [enrollmentType] is partial, only these subjects.
  final List<String> subjectIds;
  final EnrollmentType enrollmentType;
  final String status;

  @override
  List<Object?> get props => [
        id,
        name,
        branchId,
        phone,
        userId,
        gradeId,
        parentIds,
        subjectIds,
        enrollmentType,
        status,
      ];
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

/// Weekly session template embedded in a [StudyGroup].
class GroupSession extends Equatable {
  const GroupSession({
    required this.weekdays,
    required this.subjectId,
    required this.startTime,
    required this.endTime,
    this.teacherId,
  });

  /// 1 = Monday ... 7 = Sunday (may be multiple days per session).
  final List<int> weekdays;
  final String subjectId;
  final String startTime;
  final String endTime;
  final String? teacherId;

  /// First weekday (legacy / display helpers).
  int get weekday => weekdays.isNotEmpty ? weekdays.first : 1;

  Map<String, dynamic> toMap() => {
        'weekdays': weekdays,
        'weekday': weekday,
        'subjectId': subjectId,
        'startTime': startTime,
        'endTime': endTime,
        if (teacherId != null) 'teacherId': teacherId,
      };

  factory GroupSession.fromMap(Map<String, dynamic> d) {
    List<int> weekdays;
    final raw = d['weekdays'];
    if (raw is List && raw.isNotEmpty) {
      weekdays = raw.map((e) => (e as num).toInt()).toList();
    } else {
      weekdays = [(d['weekday'] as num?)?.toInt() ?? 1];
    }
    return GroupSession(
      weekdays: weekdays,
      subjectId: d['subjectId'] as String? ?? '',
      startTime: d['startTime'] as String? ?? '16:00',
      endTime: d['endTime'] as String? ?? '18:00',
      teacherId: d['teacherId'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [weekdays, subjectId, startTime, endTime, teacherId];
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
    this.sessions = const [],
    this.studentIds = const [],
    this.startDate,
    this.endDate,
  });

  final String id;
  final String name;
  final String branchId;
  final String gradeId;
  final String subjectId;
  final String? teacherId;
  final String? classroomId;
  final int capacity;
  final List<GroupSession> sessions;
  final List<String> studentIds;
  /// Period start `yyyy-MM-dd` (e.g. month start).
  final String? startDate;
  /// Period end `yyyy-MM-dd`.
  final String? endDate;

  /// Count of planned session days in [startDate]..[endDate].
  int get plannedSessionCount => plannedSessionDates.length;

  /// Concrete session calendar days in the group period (each weekly slot × each matching day).
  List<DateTime> get plannedSessionDates {
    if (startDate == null || endDate == null || sessions.isEmpty) {
      return const [];
    }
    final start = DateTime.tryParse(startDate!);
    final end = DateTime.tryParse(endDate!);
    if (start == null || end == null || end.isBefore(start)) return const [];
    final dates = <DateTime>[];
    for (var d = DateTime(start.year, start.month, start.day);
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      for (final s in sessions) {
        for (final wd in s.weekdays) {
          if (d.weekday == wd) dates.add(d);
        }
      }
    }
    return dates;
  }

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
        sessions,
        studentIds,
        startDate,
        endDate,
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
    this.subjectId,
  });

  final String id;
  final String groupId;
  /// 1 = Monday ... 7 = Sunday
  final int weekday;
  final String startTime;
  final String endTime;
  final String branchId;
  final String? subjectId;

  @override
  List<Object?> get props =>
      [id, groupId, weekday, startTime, endTime, branchId, subjectId];
}

enum EnrollmentType { full, partial }

class Enrollment extends Equatable {
  const Enrollment({
    required this.id,
    required this.studentId,
    required this.gradeId,
    required this.type,
    required this.branchId,
    this.subjectIds = const [],
    this.fee = 0,
    this.note,
    this.status = 'active',
  });

  final String id;
  final String studentId;
  final String gradeId;
  final EnrollmentType type;
  final String branchId;
  final List<String> subjectIds;
  final double fee;
  final String? note;
  final String status;

  @override
  List<Object?> get props =>
      [id, studentId, gradeId, type, branchId, subjectIds, fee, note, status];
}

class StudentEvaluation extends Equatable {
  const StudentEvaluation({
    required this.id,
    required this.studentId,
    required this.branchId,
    required this.date,
    this.subjectId,
    this.groupId,
    this.teacherId,
    this.score,
    this.note,
  });

  final String id;
  final String studentId;
  final String branchId;
  final String date;
  final String? subjectId;
  final String? groupId;
  final String? teacherId;
  final double? score;
  final String? note;

  @override
  List<Object?> get props => [
        id,
        studentId,
        branchId,
        date,
        subjectId,
        groupId,
        teacherId,
        score,
        note,
      ];
}
