import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/attendance_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';

class DashboardSnapshot extends Equatable {
  const DashboardSnapshot({
    required this.students,
    required this.teachers,
    required this.groups,
    required this.enrollments,
    required this.classrooms,
    required this.stages,
    required this.devices,
    required this.mappings,
    required this.schedules,
    required this.attendances,
    required this.todayKey,
  });

  final List<Student> students;
  final List<Teacher> teachers;
  final List<StudyGroup> groups;
  final List<Enrollment> enrollments;
  final List<Classroom> classrooms;
  final List<Stage> stages;
  final List<FingerprintDevice> devices;
  final List<BiometricMapping> mappings;
  final List<ScheduleSlot> schedules;
  final List<AttendanceRecord> attendances;
  final String todayKey;

  int get presentToday => _todayStatus(AttendanceStatus.present);
  int get lateToday => _todayStatus(AttendanceStatus.late);
  int get absentToday => _todayStatus(AttendanceStatus.absent);
  int get excusedToday => _todayStatus(AttendanceStatus.excused);

  int get fingerprintToday => attendances
      .where(
        (a) =>
            a.date == todayKey &&
            (a.source == AttendanceSource.fingerprint ||
                a.source == AttendanceSource.device),
      )
      .length;

  int get attendanceEventsToday =>
      attendances.where((a) => a.date == todayKey).length;

  /// Unique students with a non-absent mark today.
  int get uniqueCheckedInToday {
    final ids = <String>{};
    for (final a in attendances) {
      if (a.date != todayKey) continue;
      if (a.status == AttendanceStatus.absent) continue;
      ids.add(a.studentId);
    }
    return ids.length;
  }

  double get attendanceRate {
    final marked = uniqueStudentsMarkedToday;
    if (marked == 0) return 0;
    final ok = uniqueCheckedInToday;
    return (ok / marked).clamp(0, 1);
  }

  int get uniqueStudentsMarkedToday {
    final ids = <String>{};
    for (final a in attendances) {
      if (a.date == todayKey) ids.add(a.studentId);
    }
    return ids.length;
  }

  int get activeDevices =>
      devices.where((d) => d.status == 'active').length;

  int get devicesWithIp =>
      devices.where((d) => (d.ipAddress ?? '').isNotEmpty).length;

  Set<String> get mappedStudentIds =>
      mappings.map((m) => m.studentId).toSet();

  int get studentsWithoutFingerprint =>
      students.where((s) => !mappedStudentIds.contains(s.id)).length;

  List<ScheduleSlot> get todaySlots {
    final weekday = DateTime.now().weekday;
    final list = schedules.where((s) => s.weekday == weekday).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  int _todayStatus(AttendanceStatus status) {
    final seen = <String>{};
    var n = 0;
    for (final a in attendances) {
      if (a.date != todayKey || a.status != status) continue;
      if (!seen.add('${a.studentId}|${a.groupId ?? ''}')) continue;
      n++;
    }
    return n;
  }

  @override
  List<Object?> get props => [
        students,
        teachers,
        groups,
        enrollments,
        classrooms,
        stages,
        devices,
        mappings,
        schedules,
        attendances,
        todayKey,
      ];
}

class DashboardState extends Equatable {
  const DashboardState({
    this.snapshot,
    this.loading = true,
    this.error,
  });

  final DashboardSnapshot? snapshot;
  final bool loading;
  final String? error;

  @override
  List<Object?> get props => [snapshot, loading, error];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repo) : super(const DashboardState()) {
    _subscribe();
  }

  final AdminRepository _repo;
  final _subs = <StreamSubscription<dynamic>>[];

  List<Student> _students = const [];
  List<Teacher> _teachers = const [];
  List<StudyGroup> _groups = const [];
  List<Enrollment> _enrollments = const [];
  List<Classroom> _classrooms = const [];
  List<Stage> _stages = const [];
  List<FingerprintDevice> _devices = const [];
  List<BiometricMapping> _mappings = const [];
  List<ScheduleSlot> _schedules = const [];
  List<AttendanceRecord> _attendances = const [];

  void _subscribe() {
    void listen<T>(Stream<List<T>> stream, void Function(List<T>) assign) {
      _subs.add(
        stream.listen(
          (items) {
            assign(items);
            _emit();
          },
          onError: (Object e) => emit(DashboardState(error: e.toString())),
        ),
      );
    }

    listen(_repo.watchStudents(), (v) => _students = v);
    listen(_repo.watchTeachers(), (v) => _teachers = v);
    listen(_repo.watchGroups(), (v) => _groups = v);
    listen(_repo.watchEnrollments(), (v) => _enrollments = v);
    listen(_repo.watchClassrooms(), (v) => _classrooms = v);
    listen(_repo.watchStages(), (v) => _stages = v);
    listen(_repo.watchDevices(), (v) => _devices = v);
    listen(_repo.watchBiometricMappings(), (v) => _mappings = v);
    listen(_repo.watchSchedules(), (v) => _schedules = v);
    listen(_repo.watchAttendances(), (v) => _attendances = v);
  }

  void _emit() {
    final now = DateTime.now();
    final key =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    emit(
      DashboardState(
        loading: false,
        snapshot: DashboardSnapshot(
          students: _students,
          teachers: _teachers,
          groups: _groups,
          enrollments: _enrollments,
          classrooms: _classrooms,
          stages: _stages,
          devices: _devices,
          mappings: _mappings,
          schedules: _schedules,
          attendances: _attendances,
          todayKey: key,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
