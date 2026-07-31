import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';

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
}
