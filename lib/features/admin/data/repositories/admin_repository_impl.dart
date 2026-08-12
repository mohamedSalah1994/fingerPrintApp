import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/core/services/auth_account_service.dart';
import 'package:fingerprint_app/features/admin/data/datasources/firestore_crud_data_source.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/attendance_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/auth/domain/entities/app_user.dart';
import 'package:uuid/uuid.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl({AuthAccountService? authAccounts})
      : _authAccounts = authAccounts ?? AuthAccountService() {
    stages = FirestoreCrudDataSource<Stage>(
      collectionPath: FirestorePaths.stages,
      fromMap:
          (id, d) => Stage(
            id: id,
            name: d['name'] as String? ?? '',
            order: (d['order'] as num?)?.toInt() ?? 0,
            branchId: d['branchId'] as String? ?? AppDefaults.branchId,
          ),
      toMap: (e) => {'name': e.name, 'order': e.order, 'branchId': e.branchId},
    );

    grades = FirestoreCrudDataSource<Grade>(
      collectionPath: FirestorePaths.grades,
      fromMap:
          (id, d) => Grade(
            id: id,
            stageId: d['stageId'] as String? ?? '',
            name: d['name'] as String? ?? '',
            order: (d['order'] as num?)?.toInt() ?? 0,
            branchId: d['branchId'] as String? ?? AppDefaults.branchId,
          ),
      toMap:
          (e) => {
            'stageId': e.stageId,
            'name': e.name,
            'order': e.order,
            'branchId': e.branchId,
          },
    );

    subjects = FirestoreCrudDataSource<Subject>(
      collectionPath: FirestorePaths.subjects,
      fromMap:
          (id, d) => Subject(
            id: id,
            name: d['name'] as String? ?? '',
            branchId: d['branchId'] as String? ?? AppDefaults.branchId,
            stageId: d['stageId'] as String?,
            gradeId: d['gradeId'] as String?,
          ),
      toMap:
          (e) => {
            'name': e.name,
            'branchId': e.branchId,
            'stageId': e.stageId,
            'gradeId': e.gradeId,
          },
    );

    classrooms = FirestoreCrudDataSource<Classroom>(
      collectionPath: FirestorePaths.classrooms,
      fromMap:
          (id, d) => Classroom(
            id: id,
            name: d['name'] as String? ?? '',
            capacity: (d['capacity'] as num?)?.toInt() ?? 0,
            branchId: d['branchId'] as String? ?? AppDefaults.branchId,
            building: d['building'] as String?,
            floor: d['floor'] as String?,
            status: d['status'] as String? ?? 'active',
          ),
      toMap:
          (e) => {
            'name': e.name,
            'capacity': e.capacity,
            'branchId': e.branchId,
            'building': e.building,
            'floor': e.floor,
            'status': e.status,
          },
    );

    teachers = FirestoreCrudDataSource<Teacher>(
      collectionPath: FirestorePaths.teachers,
      fromMap:
          (id, d) => Teacher(
            id: id,
            name: d['name'] as String? ?? '',
            branchId: d['branchId'] as String? ?? AppDefaults.branchId,
            phone: d['phone'] as String?,
            userId: d['userId'] as String?,
            photoUrl: (() {
              final v = d['photoUrl'] as String?;
              if (v == null || v.isEmpty) return null;
              return v;
            })(),
            salaryMethod: SalaryMethodX.fromString(
              d['salaryMethod'] as String?,
            ),
            subjectIds: List<String>.from(d['subjectIds'] ?? const []),
            gradeIds: List<String>.from(d['gradeIds'] ?? const []),
            status: d['status'] as String? ?? 'active',
          ),
      toMap:
          (e) => {
            'name': e.name,
            'branchId': e.branchId,
            'phone': e.phone,
            'userId': e.userId,
            'photoUrl': e.photoUrl,
            'salaryMethod': e.salaryMethod.value,
            'subjectIds': e.subjectIds,
            'gradeIds': e.gradeIds,
            'status': e.status,
          },
    );

    students = FirestoreCrudDataSource<Student>(
      collectionPath: FirestorePaths.students,
      fromMap:
          (id, d) => Student(
            id: id,
            name: d['name'] as String? ?? '',
            branchId: d['branchId'] as String? ?? AppDefaults.branchId,
            phone: d['phone'] as String?,
            userId: d['userId'] as String?,
            gradeId: d['gradeId'] as String?,
            parentIds: List<String>.from(d['parentIds'] ?? const []),
            subjectIds: List<String>.from(d['subjectIds'] ?? const []),
            enrollmentType:
                (d['enrollmentType'] as String?) == 'partial'
                    ? EnrollmentType.partial
                    : EnrollmentType.full,
            status: d['status'] as String? ?? 'active',
          ),
      toMap:
          (e) => {
            'name': e.name,
            'branchId': e.branchId,
            'phone': e.phone,
            'userId': e.userId,
            'gradeId': e.gradeId,
            'parentIds': e.parentIds,
            'subjectIds': e.subjectIds,
            'enrollmentType': e.enrollmentType.name,
            'status': e.status,
          },
    );

    parents = FirestoreCrudDataSource<ParentProfile>(
      collectionPath: FirestorePaths.parents,
      fromMap:
          (id, d) => ParentProfile(
            id: id,
            name: d['name'] as String? ?? '',
            branchId: d['branchId'] as String? ?? AppDefaults.branchId,
            phone: d['phone'] as String?,
            userId: d['userId'] as String?,
            studentIds: List<String>.from(d['studentIds'] ?? const []),
          ),
      toMap:
          (e) => {
            'name': e.name,
            'branchId': e.branchId,
            'phone': e.phone,
            'userId': e.userId,
            'studentIds': e.studentIds,
          },
    );

    groups = FirestoreCrudDataSource<StudyGroup>(
      collectionPath: FirestorePaths.groups,
      fromMap:
          (id, d) => StudyGroup(
            id: id,
            name: d['name'] as String? ?? '',
            branchId: d['branchId'] as String? ?? AppDefaults.branchId,
            gradeId: d['gradeId'] as String? ?? '',
            subjectId: d['subjectId'] as String? ?? '',
            teacherId: d['teacherId'] as String?,
            classroomId: d['classroomId'] as String?,
            capacity: (d['capacity'] as num?)?.toInt() ?? 20,
            sessions: _parseGroupSessions(d['sessions']),
            studentIds: List<String>.from(d['studentIds'] ?? const []),
            startDate: d['startDate'] as String?,
            endDate: d['endDate'] as String?,
          ),
      toMap:
          (e) => {
            'name': e.name,
            'branchId': e.branchId,
            'gradeId': e.gradeId,
            'subjectId': e.subjectId,
            'teacherId': e.teacherId,
            'classroomId': e.classroomId,
            'capacity': e.capacity,
            'sessions': e.sessions.map((s) => s.toMap()).toList(),
            'studentIds': e.studentIds,
            'startDate': e.startDate,
            'endDate': e.endDate,
            'plannedSessionCount': e.plannedSessionCount,
          },
    );

    schedules = FirestoreCrudDataSource<ScheduleSlot>(
      collectionPath: FirestorePaths.schedules,
      fromMap:
          (id, d) => ScheduleSlot(
            id: id,
            groupId: d['groupId'] as String? ?? '',
            weekday: (d['weekday'] as num?)?.toInt() ?? 1,
            startTime: d['startTime'] as String? ?? '00:00',
            endTime: d['endTime'] as String? ?? '00:00',
            branchId: d['branchId'] as String? ?? AppDefaults.branchId,
            subjectId: d['subjectId'] as String?,
          ),
      toMap:
          (e) => {
            'groupId': e.groupId,
            'weekday': e.weekday,
            'startTime': e.startTime,
            'endTime': e.endTime,
            'branchId': e.branchId,
            if (e.subjectId != null && e.subjectId!.isNotEmpty)
              'subjectId': e.subjectId,
          },
    );

    enrollments = FirestoreCrudDataSource<Enrollment>(
      collectionPath: FirestorePaths.enrollments,
      fromMap:
          (id, d) => Enrollment(
            id: id,
            studentId: d['studentId'] as String? ?? '',
            gradeId: d['gradeId'] as String? ?? '',
            type:
                (d['type'] as String?) == 'partial'
                    ? EnrollmentType.partial
                    : EnrollmentType.full,
            branchId: d['branchId'] as String? ?? AppDefaults.branchId,
            subjectIds: List<String>.from(d['subjectIds'] ?? const []),
            fee: (d['fee'] as num?)?.toDouble() ?? 0,
            note: d['note'] as String?,
            status: d['status'] as String? ?? 'active',
          ),
      toMap:
          (e) => {
            'studentId': e.studentId,
            'gradeId': e.gradeId,
            'type': e.type.name,
            'branchId': e.branchId,
            'subjectIds': e.subjectIds,
            'fee': e.fee,
            'note': e.note,
            'status': e.status,
          },
    );

    evaluations = FirestoreCrudDataSource<StudentEvaluation>(
      collectionPath: FirestorePaths.evaluations,
      fromMap: (id, d) => StudentEvaluation(
        id: id,
        studentId: d['studentId'] as String? ?? '',
        branchId: d['branchId'] as String? ?? AppDefaults.branchId,
        date: d['date'] as String? ?? '',
        subjectId: d['subjectId'] as String?,
        groupId: d['groupId'] as String?,
        teacherId: d['teacherId'] as String?,
        score: (d['score'] as num?)?.toDouble(),
        note: d['note'] as String?,
      ),
      toMap: (e) => {
        'studentId': e.studentId,
        'branchId': e.branchId,
        'date': e.date,
        'subjectId': e.subjectId,
        'groupId': e.groupId,
        'teacherId': e.teacherId,
        'score': e.score,
        'note': e.note,
      },
    );

    attendances = FirestoreCrudDataSource<AttendanceRecord>(
      collectionPath: FirestorePaths.attendances,
      fromMap: (id, d) => AttendanceRecord(
        id: id,
        studentId: d['studentId'] as String? ?? '',
        branchId: d['branchId'] as String? ?? AppDefaults.branchId,
        date: d['date'] as String? ?? '',
        status: AttendanceStatusX.fromString(d['status'] as String?),
        source: AttendanceSourceX.fromString(d['source'] as String?),
        groupId: d['groupId'] as String?,
        checkInAt: parseFirestoreDate(d['checkInAt']),
        checkOutAt: parseFirestoreDate(d['checkOutAt']),
        deviceId: d['deviceId'] as String?,
        deviceUserId: d['deviceUserId'] as String?,
        note: d['note'] as String?,
        recordedBy: d['recordedBy'] as String?,
      ),
      toMap: (e) => {
        'studentId': e.studentId,
        'branchId': e.branchId,
        'date': e.date,
        'status': e.status.value,
        'source': e.source.value,
        'groupId': e.groupId,
        'checkInAt': e.checkInAt,
        'checkOutAt': e.checkOutAt,
        'deviceId': e.deviceId,
        'deviceUserId': e.deviceUserId,
        'note': e.note,
        'recordedBy': e.recordedBy,
      },
    );

    devices = FirestoreCrudDataSource<FingerprintDevice>(
      collectionPath: FirestorePaths.devices,
      fromMap: (id, d) => FingerprintDevice(
        id: id,
        name: d['name'] as String? ?? '',
        branchId: d['branchId'] as String? ?? AppDefaults.branchId,
        serialNumber: d['serialNumber'] as String? ?? '',
        vendor: d['vendor'] as String? ?? 'zkteco',
        model: d['model'] as String? ?? 'K50 Pro',
        status: d['status'] as String? ?? 'active',
        location: d['location'] as String?,
        lastSyncAt: parseFirestoreDate(d['lastSyncAt']),
        ipAddress: d['ipAddress'] as String?,
        port: (d['port'] as num?)?.toInt() ?? 4370,
        commKey: (d['commKey'] as num?)?.toInt() ?? 0,
        forceUdp: d['forceUdp'] as bool? ?? false,
      ),
      toMap: (e) => {
        'name': e.name,
        'branchId': e.branchId,
        'serialNumber': e.serialNumber,
        'vendor': e.vendor,
        'model': e.model,
        'status': e.status,
        'location': e.location,
        'lastSyncAt': e.lastSyncAt,
        'ipAddress': e.ipAddress,
        'port': e.port,
        'commKey': e.commKey,
        'forceUdp': e.forceUdp,
      },
    );

    biometricMappings = FirestoreCrudDataSource<BiometricMapping>(
      collectionPath: FirestorePaths.biometricMappings,
      fromMap: (id, d) => BiometricMapping(
        id: id,
        studentId: d['studentId'] as String? ?? '',
        deviceId: d['deviceId'] as String? ?? '',
        deviceUserId: '${d['deviceUserId'] ?? ''}',
        branchId: d['branchId'] as String? ?? AppDefaults.branchId,
        fingerIndex: (d['fingerIndex'] as num?)?.toInt(),
        status: d['status'] as String? ?? 'active',
      ),
      toMap: (e) => {
        'studentId': e.studentId,
        'deviceId': e.deviceId,
        'deviceUserId': e.deviceUserId,
        'branchId': e.branchId,
        'fingerIndex': e.fingerIndex,
        'status': e.status,
      },
    );
  }

  final AuthAccountService _authAccounts;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final FirestoreCrudDataSource<Stage> stages;
  late final FirestoreCrudDataSource<Grade> grades;
  late final FirestoreCrudDataSource<Subject> subjects;
  late final FirestoreCrudDataSource<Classroom> classrooms;
  late final FirestoreCrudDataSource<Teacher> teachers;
  late final FirestoreCrudDataSource<Student> students;
  late final FirestoreCrudDataSource<ParentProfile> parents;
  late final FirestoreCrudDataSource<StudyGroup> groups;
  late final FirestoreCrudDataSource<ScheduleSlot> schedules;
  late final FirestoreCrudDataSource<Enrollment> enrollments;
  late final FirestoreCrudDataSource<AttendanceRecord> attendances;
  late final FirestoreCrudDataSource<StudentEvaluation> evaluations;
  late final FirestoreCrudDataSource<FingerprintDevice> devices;
  late final FirestoreCrudDataSource<BiometricMapping> biometricMappings;

  @override
  Stream<List<Stage>> watchStages() => stages.watchAll();

  @override
  Future<void> saveStage(Stage stage) async {
    if (stage.id.isEmpty) {
      await stages.create(stage);
    } else {
      await stages.update(stage.id, stage);
    }
  }

  @override
  Future<void> deleteStage(String id) => stages.softDelete(id);

  @override
  Stream<List<Grade>> watchGrades() => grades.watchAll();

  @override
  Future<void> saveGrade(Grade grade) async {
    if (grade.id.isEmpty) {
      await grades.create(grade);
    } else {
      await grades.update(grade.id, grade);
    }
  }

  @override
  Future<void> deleteGrade(String id) => grades.softDelete(id);

  @override
  Stream<List<Subject>> watchSubjects() => subjects.watchAll();

  @override
  Future<void> saveSubject(Subject subject) async {
    if (subject.id.isEmpty) {
      await subjects.create(subject);
    } else {
      await subjects.update(subject.id, subject);
    }
  }

  @override
  Future<void> deleteSubject(String id) => subjects.softDelete(id);

  @override
  Stream<List<Classroom>> watchClassrooms() => classrooms.watchAll();

  @override
  Future<void> saveClassroom(Classroom classroom) async {
    if (classroom.id.isEmpty) {
      await classrooms.create(classroom);
    } else {
      await classrooms.update(classroom.id, classroom);
    }
  }

  @override
  Future<void> deleteClassroom(String id) => classrooms.softDelete(id);

  @override
  Stream<List<Teacher>> watchTeachers() => teachers.watchAll();

  @override
  Future<void> saveTeacher(Teacher teacher) async {
    if (teacher.id.isEmpty) {
      await teachers.create(teacher);
    } else {
      await teachers.update(teacher.id, teacher);
    }
  }

  @override
  Future<void> deleteTeacher(String id) => teachers.softDelete(id);

  @override
  Stream<List<Student>> watchStudents() => students.watchAll();

  @override
  Future<void> saveStudent(Student student) async {
    if (student.id.isEmpty) {
      await students.create(student);
    } else {
      await students.update(student.id, student);
    }
  }

  @override
  Future<void> deleteStudent(String id) => students.softDelete(id);

  @override
  Stream<List<ParentProfile>> watchParents() => parents.watchAll();

  @override
  Future<void> saveParent(ParentProfile parent) async {
    if (parent.id.isEmpty) {
      await parents.create(parent);
    } else {
      await parents.update(parent.id, parent);
    }
  }

  @override
  Future<void> deleteParent(String id) => parents.softDelete(id);

  @override
  Future<void> linkParentStudent({
    required String parentId,
    required String studentId,
    required ParentProfile parent,
    required Student student,
  }) async {
    final updatedParent = ParentProfile(
      id: parent.id,
      name: parent.name,
      branchId: parent.branchId,
      phone: parent.phone,
      userId: parent.userId,
      studentIds: {...parent.studentIds, studentId}.toList(),
    );
    final updatedStudent = Student(
      id: student.id,
      name: student.name,
      branchId: student.branchId,
      phone: student.phone,
      userId: student.userId,
      gradeId: student.gradeId,
      parentIds: {...student.parentIds, parentId}.toList(),
      subjectIds: student.subjectIds,
      enrollmentType: student.enrollmentType,
      status: student.status,
    );
    await parents.update(parentId, updatedParent);
    await students.update(studentId, updatedStudent);
  }

  @override
  Future<void> unlinkParentStudent({
    required String parentId,
    required String studentId,
    required ParentProfile parent,
    required Student student,
  }) async {
    final updatedParent = ParentProfile(
      id: parent.id,
      name: parent.name,
      branchId: parent.branchId,
      phone: parent.phone,
      userId: parent.userId,
      studentIds: parent.studentIds.where((id) => id != studentId).toList(),
    );
    final updatedStudent = Student(
      id: student.id,
      name: student.name,
      branchId: student.branchId,
      phone: student.phone,
      userId: student.userId,
      gradeId: student.gradeId,
      parentIds: student.parentIds.where((id) => id != parentId).toList(),
      subjectIds: student.subjectIds,
      enrollmentType: student.enrollmentType,
      status: student.status,
    );
    await parents.update(parentId, updatedParent);
    await students.update(studentId, updatedStudent);
  }

  @override
  Stream<List<StudyGroup>> watchGroups() => groups.watchAll();

  @override
  Future<void> saveGroup(StudyGroup group) async {
    late final String id;
    if (group.id.isEmpty) {
      id = await groups.create(group);
    } else {
      id = group.id;
      await groups.update(id, group);
    }
    final saved = StudyGroup(
      id: id,
      name: group.name,
      branchId: group.branchId,
      gradeId: group.gradeId,
      subjectId: group.subjectId,
      teacherId: group.teacherId,
      classroomId: group.classroomId,
      capacity: group.capacity,
      sessions: group.sessions,
      studentIds: group.studentIds,
      startDate: group.startDate,
      endDate: group.endDate,
    );
    try {
      await _syncSchedulesForGroup(saved);
    } catch (_) {
      // Group is already saved; schedule sync can be retried on next edit.
    }
  }

  Future<void> _syncSchedulesForGroup(StudyGroup group) async {
    final existing = await schedules.fetchAll();
    for (final slot in existing.where((s) => s.groupId == group.id)) {
      await schedules.softDelete(slot.id);
    }
    for (final session in group.sessions) {
      for (final wd in session.weekdays) {
        await schedules.create(
          ScheduleSlot(
            id: '',
            groupId: group.id,
            weekday: wd,
            startTime: session.startTime,
            endTime: session.endTime,
            branchId: group.branchId,
            subjectId: session.subjectId.isNotEmpty
                ? session.subjectId
                : group.subjectId,
          ),
        );
      }
    }
  }

  @override
  Future<void> deleteGroup(String id) async {
    final existing = await schedules.fetchAll();
    for (final slot in existing.where((s) => s.groupId == id)) {
      await schedules.softDelete(slot.id);
    }
    await groups.softDelete(id);
  }

  @override
  Future<void> saveSubjectScoped({
    required String name,
    required String branchId,
    String? id,
    String? gradeId,
    String? stageId,
  }) async {
    if (id != null && id.isNotEmpty) {
      await subjects.update(
        id,
        Subject(
          id: id,
          name: name,
          branchId: branchId,
          gradeId: gradeId,
          stageId: stageId,
        ),
      );
      return;
    }

    // Stage without a specific grade → one subject per grade in that stage.
    if (stageId != null &&
        stageId.isNotEmpty &&
        (gradeId == null || gradeId.isEmpty)) {
      final allGrades = await grades.fetchAll(branchId: branchId);
      final inStage = allGrades.where((g) => g.stageId == stageId).toList();
      if (inStage.isEmpty) {
        await subjects.create(
          Subject(
            id: '',
            name: name,
            branchId: branchId,
            stageId: stageId,
          ),
        );
        return;
      }
      for (final g in inStage) {
        await subjects.create(
          Subject(
            id: '',
            name: name,
            branchId: branchId,
            stageId: stageId,
            gradeId: g.id,
          ),
        );
      }
      return;
    }

    await subjects.create(
      Subject(
        id: '',
        name: name,
        branchId: branchId,
        gradeId: gradeId,
        stageId: stageId,
      ),
    );
  }

  @override
  Future<Student> saveStudentWithDetails({
    required Student student,
    ParentProfile? newParent,
    String? linkExistingParentId,
  }) async {
    var parentIds = [...student.parentIds];
    String? createdParentId;

    if (newParent != null && newParent.name.trim().isNotEmpty) {
      createdParentId = await parents.create(
        ParentProfile(
          id: '',
          name: newParent.name.trim(),
          branchId: student.branchId,
          phone: newParent.phone,
        ),
      );
      parentIds = {...parentIds, createdParentId}.toList();
    } else if (linkExistingParentId != null &&
        linkExistingParentId.isNotEmpty) {
      parentIds = {...parentIds, linkExistingParentId}.toList();
    }

    final toSave = Student(
      id: student.id,
      name: student.name,
      branchId: student.branchId,
      phone: student.phone,
      userId: student.userId,
      gradeId: student.gradeId,
      parentIds: parentIds,
      subjectIds: student.subjectIds,
      enrollmentType: student.enrollmentType,
      status: student.status,
    );

    late final String studentId;
    if (toSave.id.isEmpty) {
      studentId = await students.create(toSave);
    } else {
      studentId = toSave.id;
      await students.update(studentId, toSave);
    }

    final saved = Student(
      id: studentId,
      name: toSave.name,
      branchId: toSave.branchId,
      phone: toSave.phone,
      userId: toSave.userId,
      gradeId: toSave.gradeId,
      parentIds: parentIds,
      subjectIds: toSave.subjectIds,
      enrollmentType: toSave.enrollmentType,
      status: toSave.status,
    );

    // Bidirectional parent link
    final parentIdsToLink = <String>{
      if (createdParentId != null) createdParentId,
      if (linkExistingParentId != null && linkExistingParentId.isNotEmpty)
        linkExistingParentId,
    };
    for (final pid in parentIdsToLink) {
      final allParents = await parents.fetchAll(branchId: student.branchId);
      final parent = allParents.cast<ParentProfile?>().firstWhere(
            (p) => p?.id == pid,
            orElse: () => null,
          );
      if (parent == null) continue;
      await parents.update(
        pid,
        ParentProfile(
          id: parent.id,
          name: parent.name,
          branchId: parent.branchId,
          phone: parent.phone,
          userId: parent.userId,
          studentIds: {...parent.studentIds, studentId}.toList(),
        ),
      );
    }

    // Sync enrollment for grade + subjects
    if (saved.gradeId != null && saved.gradeId!.isNotEmpty) {
      final existing = await enrollments.fetchAll(branchId: saved.branchId);
      final match = existing.cast<Enrollment?>().firstWhere(
            (e) =>
                e?.studentId == studentId &&
                e?.gradeId == saved.gradeId &&
                e?.status == 'active',
            orElse: () => null,
          );
      final enrollment = Enrollment(
        id: match?.id ?? '',
        studentId: studentId,
        gradeId: saved.gradeId!,
        type: saved.enrollmentType,
        branchId: saved.branchId,
        subjectIds: saved.enrollmentType == EnrollmentType.partial
            ? saved.subjectIds
            : const [],
        fee: match?.fee ?? 0,
        note: match?.note,
        status: 'active',
      );
      if (enrollment.id.isEmpty) {
        await enrollments.create(enrollment);
      } else {
        await enrollments.update(enrollment.id, enrollment);
      }
    }

    return saved;
  }

  @override
  Stream<List<StudentEvaluation>> watchEvaluations() => evaluations.watchAll();

  @override
  Future<void> saveEvaluation(StudentEvaluation evaluation) async {
    if (evaluation.id.isEmpty) {
      await evaluations.create(evaluation);
    } else {
      await evaluations.update(evaluation.id, evaluation);
    }
  }

  @override
  Future<void> deleteEvaluation(String id) => evaluations.softDelete(id);

  @override
  Stream<List<ScheduleSlot>> watchSchedules() => schedules.watchAll();

  @override
  Future<void> saveSchedule(ScheduleSlot slot) async {
    if (slot.id.isEmpty) {
      await schedules.create(slot);
    } else {
      await schedules.update(slot.id, slot);
    }
  }

  @override
  Future<void> deleteSchedule(String id) => schedules.softDelete(id);

  @override
  Stream<List<Enrollment>> watchEnrollments() => enrollments.watchAll();

  @override
  Future<void> saveEnrollment(Enrollment enrollment) async {
    if (enrollment.id.isEmpty) {
      await enrollments.create(enrollment);
    } else {
      await enrollments.update(enrollment.id, enrollment);
    }
  }

  @override
  Future<void> deleteEnrollment(String id) => enrollments.softDelete(id);

  @override
  Stream<List<AttendanceRecord>> watchAttendances() => attendances.watchAll();

  @override
  Future<void> saveAttendance(AttendanceRecord record) async {
    if (record.id.isEmpty) {
      await attendances.create(record);
    } else {
      await attendances.update(record.id, record);
    }
  }

  @override
  Future<void> deleteAttendance(String id) => attendances.softDelete(id);

  @override
  Future<StaffUser> createStaffUser({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phone,
    String? branchId,
  }) async {
    final uid = await _authAccounts.createEmailPasswordUser(
      email: email,
      password: password,
      displayName: displayName,
    );
    final resolvedBranch = branchId ?? AppDefaults.branchId;
    final now = FieldValue.serverTimestamp();
    await _firestore.collection(FirestorePaths.users).doc(uid).set({
      'email': email.trim(),
      'displayName': displayName.trim(),
      'role': role.value,
      'phone': phone,
      'branchId': resolvedBranch,
      'linkedStudentIds': <String>[],
      'parentIds': <String>[],
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    return StaffUser(
      id: uid,
      email: email.trim(),
      displayName: displayName.trim(),
      role: role,
      phone: phone,
      branchId: resolvedBranch,
    );
  }

  @override
  Stream<List<StaffUser>> watchStaffUsers() {
    return _firestore.collection(FirestorePaths.users).snapshots().map((snap) {
      return snap.docs
          .map((d) {
            final data = d.data();
            final role = UserRoleX.fromString(data['role'] as String?);
            if (role != UserRole.admin && role != UserRole.teacher) {
              return null;
            }
            return StaffUser(
              id: d.id,
              email: data['email'] as String? ?? '',
              displayName: data['displayName'] as String? ?? '',
              role: role,
              phone: data['phone'] as String?,
              branchId: data['branchId'] as String?,
            );
          })
          .whereType<StaffUser>()
          .toList(growable: false);
    });
  }

  @override
  Future<Teacher> createTeacherWithLogin({
    required Teacher teacher,
    String? loginEmail,
    String? loginPassword,
  }) async {
    var linked = teacher;
    if (loginEmail != null &&
        loginEmail.trim().isNotEmpty &&
        loginPassword != null &&
        loginPassword.length >= 6) {
      final staff = await createStaffUser(
        email: loginEmail,
        password: loginPassword,
        displayName: teacher.name,
        role: UserRole.teacher,
        phone: teacher.phone,
        branchId: teacher.branchId,
      );
      linked = Teacher(
        id: teacher.id,
        name: teacher.name,
        branchId: teacher.branchId,
        phone: teacher.phone,
        userId: staff.id,
        photoUrl: teacher.photoUrl,
        salaryMethod: teacher.salaryMethod,
        subjectIds: teacher.subjectIds,
        gradeIds: teacher.gradeIds,
        status: teacher.status,
      );
    }

    if (linked.id.isEmpty) {
      final id = await teachers.create(linked);
      return Teacher(
        id: id,
        name: linked.name,
        branchId: linked.branchId,
        phone: linked.phone,
        userId: linked.userId,
        photoUrl: linked.photoUrl,
        salaryMethod: linked.salaryMethod,
        subjectIds: linked.subjectIds,
        gradeIds: linked.gradeIds,
        status: linked.status,
      );
    }

    await teachers.update(linked.id, linked);
    return linked;
  }

  @override
  Future<String> uploadTeacherPhoto({
    required String teacherId,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    final id = teacherId.isEmpty ? const Uuid().v4() : teacherId;
    final data = Uint8List.fromList(bytes);
    if (data.isEmpty) {
      throw Exception('Empty image');
    }
    // Prefer Firebase Storage; fall back to Firestore-friendly data URI.
    try {
      final ref = FirebaseStorage.instance.ref('teachers/$id/photo.jpg');
      await ref
          .putData(data, SettableMetadata(contentType: contentType))
          .timeout(const Duration(seconds: 20));
      return await ref.getDownloadURL().timeout(const Duration(seconds: 10));
    } catch (_) {
      // Storage not enabled / rules / CORS — keep photo on the teacher doc.
      if (data.lengthInBytes > 900000) {
        throw Exception(
          'Image too large for fallback storage. Use a smaller photo.',
        );
      }
      final b64 = base64Encode(data);
      return 'data:$contentType;base64,$b64';
    }
  }

  @override
  Stream<List<FingerprintDevice>> watchDevices() => devices.watchAll();

  @override
  Future<void> saveDevice(FingerprintDevice device) async {
    if (device.id.isEmpty) {
      await devices.create(device);
    } else {
      await devices.update(device.id, device);
    }
  }

  @override
  Future<void> deleteDevice(String id) => devices.softDelete(id);

  @override
  Stream<List<BiometricMapping>> watchBiometricMappings() =>
      biometricMappings.watchAll();

  @override
  Future<void> saveBiometricMapping(BiometricMapping mapping) async {
    if (mapping.id.isEmpty) {
      await biometricMappings.create(mapping);
    } else {
      await biometricMappings.update(mapping.id, mapping);
    }
  }

  @override
  Future<void> deleteBiometricMapping(String id) =>
      biometricMappings.softDelete(id);
}

List<GroupSession> _parseGroupSessions(dynamic raw) {
  if (raw == null) return const [];
  if (raw is! Iterable) return const [];
  final out = <GroupSession>[];
  for (final item in raw) {
    try {
      if (item is Map) {
        out.add(
          GroupSession.fromMap(
            item.map((k, v) => MapEntry(k.toString(), v)),
          ),
        );
      }
    } catch (_) {
      // Ignore malformed session rows.
    }
  }
  return out;
}
