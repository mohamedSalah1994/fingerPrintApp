// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Center Management';

  @override
  String get controlPanel => 'Admin Control Panel';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Sign in';

  @override
  String get logout => 'Sign out';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get passwordTooShort => 'Password is too short';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String get welcomeGuest => 'Welcome';

  @override
  String get dashboardSubtitle => 'Education center overview';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get stages => 'Stages';

  @override
  String get grades => 'Grades';

  @override
  String get subjects => 'Subjects';

  @override
  String get classrooms => 'Classrooms';

  @override
  String get teachers => 'Teachers';

  @override
  String get students => 'Students';

  @override
  String get parents => 'Parents';

  @override
  String get groups => 'Groups';

  @override
  String get schedules => 'Schedule';

  @override
  String get enrollments => 'Enrollments';

  @override
  String get settings => 'Settings';

  @override
  String get quickShortcuts => 'Quick shortcuts';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get link => 'Link';

  @override
  String get unlink => 'Unlink';

  @override
  String get actions => 'Actions';

  @override
  String get confirmDelete => 'Confirm delete';

  @override
  String confirmDeleteMessage(String name) {
    return 'Do you want to delete \"$name\"?';
  }

  @override
  String get noData => 'No data';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get order => 'Order';

  @override
  String get capacity => 'Capacity';

  @override
  String get required => 'Required';

  @override
  String get number => 'Number';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light';

  @override
  String get darkMode => 'Dark';

  @override
  String get systemMode => 'System';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get appearance => 'Appearance';

  @override
  String get preferences => 'Preferences';

  @override
  String get children => 'Children';

  @override
  String get parentGuardian => 'Parent';

  @override
  String get noChildren => 'No children';

  @override
  String get noParent => 'No parent';

  @override
  String manageChildren(String name) {
    return 'Children of $name';
  }

  @override
  String manageParents(String name) {
    return 'Parents of $name';
  }

  @override
  String get linkedSuccessfully => 'Linked successfully';

  @override
  String get unlinkedSuccessfully => 'Unlinked successfully';

  @override
  String get addStudent => 'Add student';

  @override
  String get linkParent => 'Link parent';

  @override
  String get allStudentsLinked => 'All students are linked or none available';

  @override
  String get noParentsAvailable => 'No parents available to link';

  @override
  String get linkedStudents => 'Linked students';

  @override
  String get currentlyLinked => 'Currently linked';

  @override
  String get seedAdminDev => 'Setup admin (dev only)';

  @override
  String get adminSetupDone => 'Admin ready. Signing in...';

  @override
  String get centerManagement => 'Center Admin';

  @override
  String get systemAdmin => 'System admin';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get allStages => 'All stages';

  @override
  String get unspecified => 'Unspecified';

  @override
  String get addStage => 'Add stage';

  @override
  String get editStage => 'Edit stage';

  @override
  String get stageName => 'Stage name';

  @override
  String get addGrade => 'Add grade';

  @override
  String get editGrade => 'Edit grade';

  @override
  String get gradeName => 'Grade name';

  @override
  String get addStageFirst => 'Add an education stage first';

  @override
  String get addSubject => 'Add subject';

  @override
  String get editSubject => 'Edit subject';

  @override
  String get subjectName => 'Subject name';

  @override
  String get stageOptional => 'Stage (optional)';

  @override
  String get allOrUnspecified => 'All / unspecified';

  @override
  String get addClassroom => 'Add classroom';

  @override
  String get editClassroom => 'Edit classroom';

  @override
  String get classroomName => 'Classroom name';

  @override
  String get addTeacher => 'Add teacher';

  @override
  String get editTeacher => 'Edit teacher';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get editStudent => 'Edit student';

  @override
  String get grade => 'Grade';

  @override
  String get addParent => 'Add parent';

  @override
  String get editParent => 'Edit parent';

  @override
  String get phoneWhatsapp => 'Phone / WhatsApp';

  @override
  String get noChildrenYet => 'No children linked yet';

  @override
  String get noParentLinked => 'No parent linked';

  @override
  String get withoutParent => 'No parent';

  @override
  String get noChildrenShort => 'No children';

  @override
  String get parentsEmptyHint => 'No parents yet — add a parent then link students';

  @override
  String get addGroup => 'Add group';

  @override
  String get editGroup => 'Edit group';

  @override
  String get groupName => 'Group name';

  @override
  String get addGradesSubjectsFirst => 'Add grades and subjects first';

  @override
  String get addSchedule => 'Add session';

  @override
  String get editSchedule => 'Edit session';

  @override
  String get weeklySchedule => 'Weekly schedule';

  @override
  String get addGroupFirst => 'Add a group first';

  @override
  String get day => 'Day';

  @override
  String get fromTime => 'From (HH:mm)';

  @override
  String get toTime => 'To (HH:mm)';

  @override
  String get timeRequired => 'Time required';

  @override
  String get group => 'Group';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get addEnrollment => 'Add enrollment';

  @override
  String get editEnrollment => 'Edit enrollment';

  @override
  String get addStudentsGradesFirst => 'Add students and grades first';

  @override
  String get student => 'Student';

  @override
  String get enrollmentType => 'Enrollment type';

  @override
  String get fullAllSubjects => 'Full (all subjects)';

  @override
  String get partialSelected => 'Partial (selected subjects)';

  @override
  String get fee => 'Fee';

  @override
  String get adminNote => 'Admin note';

  @override
  String get full => 'Full';

  @override
  String get partial => 'Partial';

  @override
  String get type => 'Type';

  @override
  String unlinkFailed(String error) {
    return 'Unlink failed: $error';
  }

  @override
  String linkFailed(String error) {
    return 'Link failed: $error';
  }

  @override
  String unlinkedNamed(String name) {
    return 'Unlinked $name';
  }

  @override
  String linkedNamed(String a, String b) {
    return 'Linked $a to $b';
  }

  @override
  String get building => 'Building';

  @override
  String get floor => 'Floor';

  @override
  String get salaryPerSession => 'Per session';

  @override
  String get salaryPerStudent => 'Per student';

  @override
  String get salaryMonthly => 'Monthly fixed';

  @override
  String get salaryHybrid => 'Hybrid';

  @override
  String get subjectsTitle => 'Subjects';

  @override
  String get gradesTitle => 'Grades';

  @override
  String get stagesTitle => 'Stages';
}
