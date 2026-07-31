import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/features/admin/data/datasources/firestore_crud_data_source.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl() {
    stages = FirestoreCrudDataSource<Stage>(
      collectionPath: FirestorePaths.stages,
      fromMap: (id, d) => Stage(
        id: id,
        name: d['name'] as String? ?? '',
        order: (d['order'] as num?)?.toInt() ?? 0,
        branchId: d['branchId'] as String? ?? AppDefaults.branchId,
      ),
      toMap: (e) => {
        'name': e.name,
        'order': e.order,
        'branchId': e.branchId,
      },
    );

    grades = FirestoreCrudDataSource<Grade>(
      collectionPath: FirestorePaths.grades,
      fromMap: (id, d) => Grade(
        id: id,
        stageId: d['stageId'] as String? ?? '',
        name: d['name'] as String? ?? '',
        order: (d['order'] as num?)?.toInt() ?? 0,
        branchId: d['branchId'] as String? ?? AppDefaults.branchId,
      ),
      toMap: (e) => {
        'stageId': e.stageId,
        'name': e.name,
        'order': e.order,
        'branchId': e.branchId,
      },
    );

    subjects = FirestoreCrudDataSource<Subject>(
      collectionPath: FirestorePaths.subjects,
      fromMap: (id, d) => Subject(
        id: id,
        name: d['name'] as String? ?? '',
        branchId: d['branchId'] as String? ?? AppDefaults.branchId,
        stageId: d['stageId'] as String?,
        gradeId: d['gradeId'] as String?,
      ),
      toMap: (e) => {
        'name': e.name,
        'branchId': e.branchId,
        'stageId': e.stageId,
        'gradeId': e.gradeId,
      },
    );

    classrooms = FirestoreCrudDataSource<Classroom>(
      collectionPath: FirestorePaths.classrooms,
      fromMap: (id, d) => Classroom(
        id: id,
        name: d['name'] as String? ?? '',
        capacity: (d['capacity'] as num?)?.toInt() ?? 0,
        branchId: d['branchId'] as String? ?? AppDefaults.branchId,
        building: d['building'] as String?,
        floor: d['floor'] as String?,
        status: d['status'] as String? ?? 'active',
      ),
      toMap: (e) => {
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
      fromMap: (id, d) => Teacher(
        id: id,
        name: d['name'] as String? ?? '',
        branchId: d['branchId'] as String? ?? AppDefaults.branchId,
        phone: d['phone'] as String?,
        userId: d['userId'] as String?,
        salaryMethod: SalaryMethodX.fromString(d['salaryMethod'] as String?),
        subjectIds: List<String>.from(d['subjectIds'] ?? const []),
        status: d['status'] as String? ?? 'active',
      ),
      toMap: (e) => {
        'name': e.name,
        'branchId': e.branchId,
        'phone': e.phone,
        'userId': e.userId,
        'salaryMethod': e.salaryMethod.value,
        'subjectIds': e.subjectIds,
        'status': e.status,
      },
    );

    students = FirestoreCrudDataSource<Student>(
      collectionPath: FirestorePaths.students,
      fromMap: (id, d) => Student(
        id: id,
        name: d['name'] as String? ?? '',
        branchId: d['branchId'] as String? ?? AppDefaults.branchId,
        phone: d['phone'] as String?,
        userId: d['userId'] as String?,
        gradeId: d['gradeId'] as String?,
        parentIds: List<String>.from(d['parentIds'] ?? const []),
        status: d['status'] as String? ?? 'active',
      ),
      toMap: (e) => {
        'name': e.name,
        'branchId': e.branchId,
        'phone': e.phone,
        'userId': e.userId,
        'gradeId': e.gradeId,
        'parentIds': e.parentIds,
        'status': e.status,
      },
    );

    parents = FirestoreCrudDataSource<ParentProfile>(
      collectionPath: FirestorePaths.parents,
      fromMap: (id, d) => ParentProfile(
        id: id,
        name: d['name'] as String? ?? '',
        branchId: d['branchId'] as String? ?? AppDefaults.branchId,
        phone: d['phone'] as String?,
        userId: d['userId'] as String?,
        studentIds: List<String>.from(d['studentIds'] ?? const []),
      ),
      toMap: (e) => {
        'name': e.name,
        'branchId': e.branchId,
        'phone': e.phone,
        'userId': e.userId,
        'studentIds': e.studentIds,
      },
    );

    groups = FirestoreCrudDataSource<StudyGroup>(
      collectionPath: FirestorePaths.groups,
      fromMap: (id, d) => StudyGroup(
        id: id,
        name: d['name'] as String? ?? '',
        branchId: d['branchId'] as String? ?? AppDefaults.branchId,
        gradeId: d['gradeId'] as String? ?? '',
        subjectId: d['subjectId'] as String? ?? '',
        teacherId: d['teacherId'] as String?,
        classroomId: d['classroomId'] as String?,
        capacity: (d['capacity'] as num?)?.toInt() ?? 20,
      ),
      toMap: (e) => {
        'name': e.name,
        'branchId': e.branchId,
        'gradeId': e.gradeId,
        'subjectId': e.subjectId,
        'teacherId': e.teacherId,
        'classroomId': e.classroomId,
        'capacity': e.capacity,
      },
    );

    schedules = FirestoreCrudDataSource<ScheduleSlot>(
      collectionPath: FirestorePaths.schedules,
      fromMap: (id, d) => ScheduleSlot(
        id: id,
        groupId: d['groupId'] as String? ?? '',
        weekday: (d['weekday'] as num?)?.toInt() ?? 1,
        startTime: d['startTime'] as String? ?? '00:00',
        endTime: d['endTime'] as String? ?? '00:00',
        branchId: d['branchId'] as String? ?? AppDefaults.branchId,
      ),
      toMap: (e) => {
        'groupId': e.groupId,
        'weekday': e.weekday,
        'startTime': e.startTime,
        'endTime': e.endTime,
        'branchId': e.branchId,
      },
    );

    enrollments = FirestoreCrudDataSource<Enrollment>(
      collectionPath: FirestorePaths.enrollments,
      fromMap: (id, d) => Enrollment(
        id: id,
        studentId: d['studentId'] as String? ?? '',
        gradeId: d['gradeId'] as String? ?? '',
        type: (d['type'] as String?) == 'partial'
            ? EnrollmentType.partial
            : EnrollmentType.full,
        branchId: d['branchId'] as String? ?? AppDefaults.branchId,
        fee: (d['fee'] as num?)?.toDouble() ?? 0,
        note: d['note'] as String?,
        status: d['status'] as String? ?? 'active',
      ),
      toMap: (e) => {
        'studentId': e.studentId,
        'gradeId': e.gradeId,
        'type': e.type.name,
        'branchId': e.branchId,
        'fee': e.fee,
        'note': e.note,
        'status': e.status,
      },
    );
  }

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
      status: student.status,
    );
    await parents.update(parentId, updatedParent);
    await students.update(studentId, updatedStudent);
  }

  @override
  Stream<List<StudyGroup>> watchGroups() => groups.watchAll();

  @override
  Future<void> saveGroup(StudyGroup group) async {
    if (group.id.isEmpty) {
      await groups.create(group);
    } else {
      await groups.update(group.id, group);
    }
  }

  @override
  Future<void> deleteGroup(String id) => groups.softDelete(id);

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
}
