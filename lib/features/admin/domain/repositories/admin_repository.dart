import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/attendance_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/auth/domain/entities/app_user.dart';

abstract class AdminRepository {
  Stream<List<Stage>> watchStages();
  Future<void> saveStage(Stage stage);
  Future<void> deleteStage(String id);

  Stream<List<Grade>> watchGrades();
  Future<void> saveGrade(Grade grade);
  Future<void> deleteGrade(String id);

  Stream<List<Subject>> watchSubjects();
  Future<void> saveSubject(Subject subject);
  Future<void> deleteSubject(String id);

  Stream<List<Classroom>> watchClassrooms();
  Future<void> saveClassroom(Classroom classroom);
  Future<void> deleteClassroom(String id);

  Stream<List<Teacher>> watchTeachers();
  Future<void> saveTeacher(Teacher teacher);
  Future<void> deleteTeacher(String id);

  Stream<List<Student>> watchStudents();
  Future<void> saveStudent(Student student);
  Future<void> deleteStudent(String id);

  Stream<List<ParentProfile>> watchParents();
  Future<void> saveParent(ParentProfile parent);
  Future<void> deleteParent(String id);

  Future<void> linkParentStudent({
    required String parentId,
    required String studentId,
    required ParentProfile parent,
    required Student student,
  });

  Future<void> unlinkParentStudent({
    required String parentId,
    required String studentId,
    required ParentProfile parent,
    required Student student,
  });

  Stream<List<StudyGroup>> watchGroups();
  Future<void> saveGroup(StudyGroup group);
  Future<void> deleteGroup(String id);

  Stream<List<ScheduleSlot>> watchSchedules();
  Future<void> saveSchedule(ScheduleSlot slot);
  Future<void> deleteSchedule(String id);

  Stream<List<Enrollment>> watchEnrollments();
  Future<void> saveEnrollment(Enrollment enrollment);
  Future<void> deleteEnrollment(String id);

  /// Creates a subject for one grade, or one copy per grade when [stageId] is set
  /// and [gradeId] is null.
  Future<void> saveSubjectScoped({
    required String name,
    required String branchId,
    String? id,
    String? gradeId,
    String? stageId,
  });

  /// Creates student (+ optional new parent link + enrollment sync).
  Future<Student> saveStudentWithDetails({
    required Student student,
    ParentProfile? newParent,
    String? linkExistingParentId,
  });

  Stream<List<AttendanceRecord>> watchAttendances();
  Future<void> saveAttendance(AttendanceRecord record);
  Future<void> deleteAttendance(String id);

  Stream<List<StudentEvaluation>> watchEvaluations();
  Future<void> saveEvaluation(StudentEvaluation evaluation);
  Future<void> deleteEvaluation(String id);

  /// Creates Firebase Auth + `users/{uid}` (admin keeps session).
  Future<StaffUser> createStaffUser({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phone,
    String? branchId,
  });

  Stream<List<StaffUser>> watchStaffUsers();

  /// Creates teacher profile and optionally a login account linked via `userId`.
  Future<Teacher> createTeacherWithLogin({
    required Teacher teacher,
    String? loginEmail,
    String? loginPassword,
  });

  /// Uploads teacher photo to Storage and returns download URL.
  Future<String> uploadTeacherPhoto({
    required String teacherId,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  });

  Stream<List<FingerprintDevice>> watchDevices();
  Future<void> saveDevice(FingerprintDevice device);
  Future<void> deleteDevice(String id);

  Stream<List<BiometricMapping>> watchBiometricMappings();
  Future<void> saveBiometricMapping(BiometricMapping mapping);
  Future<void> deleteBiometricMapping(String id);
}
