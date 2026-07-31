abstract final class FirestorePaths {
  static const centers = 'centers';
  static const branches = 'branches';
  static const users = 'users';
  static const stages = 'stages';
  static const grades = 'grades';
  static const subjects = 'subjects';
  static const classrooms = 'classrooms';
  static const teachers = 'teachers';
  static const students = 'students';
  static const parents = 'parents';
  static const groups = 'groups';
  static const schedules = 'schedules';
  static const enrollments = 'enrollments';
  static const enrollmentSubjects = 'enrollment_subjects';
  static const attendances = 'attendances';
  static const devices = 'devices';
  static const biometricMappings = 'biometric_mappings';
  static const notifications = 'notifications';
}

/// Default branch used until multi-branch UI exists.
abstract final class AppDefaults {
  static const branchId = 'default_branch';
  static const centerId = 'default_center';
}
