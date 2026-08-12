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
  String get todayOverview => 'Today overview';

  @override
  String get attendanceAnalysis => 'Today\'s attendance analysis';

  @override
  String get attendanceRate => 'Attendance rate';

  @override
  String get checkedInToday => 'Checked in today';

  @override
  String get fingerprintPunchesToday => 'Fingerprint punches today';

  @override
  String get insightsAndAlerts => 'Insights & actions';

  @override
  String get todaySessions => 'Today\'s sessions';

  @override
  String get noSessionsToday => 'No sessions scheduled today';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get actionAddStudent => 'Add student';

  @override
  String get actionOpenAttendance => 'Attendance log';

  @override
  String get actionManageDevices => 'Devices & sync';

  @override
  String get actionManageGroups => 'Manage groups';

  @override
  String get actionEnrollments => 'Enrollments';

  @override
  String get actionSchedules => 'Weekly schedule';

  @override
  String get alertNoDevices => 'No fingerprint device registered';

  @override
  String alertStudentsUnmapped(int count) {
    return '$count students without fingerprint link';
  }

  @override
  String get alertNoAttendanceToday => 'No attendance recorded today yet';

  @override
  String alertHighAbsent(int count) {
    return 'High absences today: $count';
  }

  @override
  String alertDevicesReady(int count) {
    return '$count devices ready to sync';
  }

  @override
  String get fixLinkFingerprints => 'Link fingerprints';

  @override
  String get viewDetails => 'View details';

  @override
  String get systemTotals => 'System totals';

  @override
  String get devicesOnlineLabel => 'Active devices';

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
  String get collapseSidebar => 'Collapse sidebar';

  @override
  String get expandSidebar => 'Expand sidebar';

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

  @override
  String get attendance => 'Attendance';

  @override
  String get users => 'Users';

  @override
  String get addAttendance => 'Add attendance';

  @override
  String get editAttendance => 'Edit attendance';

  @override
  String get checkIn => 'Check-in';

  @override
  String get source => 'Source';

  @override
  String get statusPresent => 'Present';

  @override
  String get statusLate => 'Late';

  @override
  String get statusAbsent => 'Absent';

  @override
  String get statusExcused => 'Excused';

  @override
  String get sourceManual => 'Manual';

  @override
  String get sourceFingerprint => 'Fingerprint';

  @override
  String get sourceDevice => 'Device';

  @override
  String get addUser => 'Add user';

  @override
  String get createAdminUser => 'Create admin user';

  @override
  String get createTeacherUser => 'Create teacher user';

  @override
  String get loginEmail => 'Login email';

  @override
  String get loginPassword => 'Login password';

  @override
  String get teacherAppLogin => 'Teacher app login';

  @override
  String get accountLinked => 'App account linked';

  @override
  String get accountNotLinked => 'No app account';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get passwordMin6 => 'Password must be at least 6 characters';

  @override
  String get userCreated => 'User created successfully';

  @override
  String get date => 'Date';

  @override
  String get status => 'Status';

  @override
  String get role => 'Role';

  @override
  String get account => 'Account';

  @override
  String userCreateFailed(String error) {
    return 'Failed to create user: $error';
  }

  @override
  String get invalidDate => 'Invalid date (yyyy-MM-dd)';

  @override
  String get pickDate => 'Pick date';

  @override
  String get noStudentsYet => 'Add a student first';

  @override
  String get createLoginHint => 'Creates a login so this teacher can open the teacher app';

  @override
  String get devices => 'Devices';

  @override
  String get addDevice => 'Add device';

  @override
  String get editDevice => 'Edit device';

  @override
  String get serialNumber => 'Serial number';

  @override
  String get ipAddress => 'IP address';

  @override
  String get port => 'Port';

  @override
  String get commKey => 'Comm key';

  @override
  String get location => 'Location';

  @override
  String get forceUdp => 'Force UDP';

  @override
  String get testConnection => 'Test connection';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncAll => 'Sync all';

  @override
  String get sidecarOnline => 'Sidecar online';

  @override
  String get sidecarOffline => 'Sidecar offline';

  @override
  String get sidecarHint => 'On the center PC: run zk_sidecar\\install_autostart.bat and keep it running. In Chrome, allow Local network access for this site, then retry';

  @override
  String get sidecarConnecting => 'Connecting to helper service…';

  @override
  String get sidecarConnectingHint => 'Starting the helper automatically and checking connection';

  @override
  String get sidecarRetry => 'Retry';

  @override
  String get startAutoSync => 'Start auto-sync loop';

  @override
  String get stopAutoSync => 'Stop loop';

  @override
  String get biometricMappings => 'Biometric mappings';

  @override
  String get addMapping => 'Add mapping';

  @override
  String get deviceUserId => 'Device user ID';

  @override
  String get deviceUsers => 'Device users';

  @override
  String get linkStudent => 'Link student';

  @override
  String get mappingSaved => 'Mapping saved';

  @override
  String get connectionOk => 'Connection OK';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get syncDone => 'Sync completed';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get attendanceBySession => 'By session';

  @override
  String get sessionSearch => 'Session search';

  @override
  String get sessionNumber => 'Session #';

  @override
  String get sessionStudents => 'Session students';

  @override
  String get markPresent => 'Mark present';

  @override
  String get clearAttendance => 'Clear attendance';

  @override
  String get studentPhone => 'Student phone';

  @override
  String get allDates => 'All dates';

  @override
  String get studentsCount => 'Students';

  @override
  String get sessionSearchHint => 'Filter by date, group, or session — tap a session for the roster';

  @override
  String get selectSession => 'Select session';

  @override
  String get selectGroup => 'Select group';

  @override
  String get noSessionsOnDate => 'No sessions on this date';

  @override
  String get sessionNotStartedYet => 'Not started yet';

  @override
  String get notCheckedInYet => 'Not checked in yet';

  @override
  String get carriedFromPreviousSession => 'From previous session';

  @override
  String get studentHistory => 'Student history';

  @override
  String get allGroups => 'All groups';

  @override
  String get sessionTime => 'Session time';

  @override
  String get noSessionsForDay => 'No sessions or records for this day';

  @override
  String get scheduledNoRecordsYet => 'Scheduled — no records yet';

  @override
  String get offScheduleAttendance => 'Outside schedule days';

  @override
  String get noHistoryForStudent => 'No attendance history for this student';

  @override
  String get selectStudent => 'Select a student';

  @override
  String presentCount(int count) {
    return 'Present: $count';
  }

  @override
  String lateCount(int count) {
    return 'Late: $count';
  }

  @override
  String absentCount(int count) {
    return 'Absent: $count';
  }

  @override
  String punchesCount(int count) {
    return '$count punches';
  }

  @override
  String get ungroupedSession => 'Ungrouped';

  @override
  String get punches => 'Punches';

  @override
  String get scheduleSlot => 'Schedule';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Type to search…';

  @override
  String get searchDebounceHint => 'Search runs 1 second after you stop typing';

  @override
  String get noSearchResults => 'No results';

  @override
  String get rowsPerPage => 'Rows';

  @override
  String get previousPage => 'Previous';

  @override
  String get nextPage => 'Next';

  @override
  String pageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String paginationSummary(int from, int to, int total) {
    return '$from–$to of $total';
  }

  @override
  String get groupPeriod => 'Group period';

  @override
  String get periodDaily => 'Daily';

  @override
  String get periodWeekly => 'Weekly';

  @override
  String get periodMonthly => 'Monthly';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get sessions => 'Weekly session time';

  @override
  String get addSession => 'Add session';

  @override
  String get sessionTeacher => 'Session teacher';

  @override
  String get selectWeekdays => 'Weekdays';

  @override
  String get selectWeekdaysHint => 'Add a session: pick subject, weekdays (multiple allowed), and time';

  @override
  String get groupStudents => 'Group students';

  @override
  String get selectStudents => 'Select students';

  @override
  String selectedStudentsCount(int count) {
    return 'Selected: $count';
  }

  @override
  String get selectAllVisible => 'Select visible';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get done => 'Done';

  @override
  String get noStudentsForGrade => 'No students for this grade';

  @override
  String get plannedSessions => 'Sessions count';

  @override
  String plannedSessionsCount(int count) {
    return '$count sessions in period';
  }

  @override
  String sessionPlanSummary(int days, int count) {
    return '$days days/week → $count sessions · attendance for group students';
  }

  @override
  String get pickAtLeastOneWeekday => 'Select at least one weekday';

  @override
  String get invalidDateRange => 'End date must be after start date';

  @override
  String get subjectScopeGrade => 'For a specific grade';

  @override
  String get subjectScopeStage => 'For a stage (all its grades)';

  @override
  String get teachingGrades => 'Grades taught';

  @override
  String get specializedSubjects => 'Specialized subjects';

  @override
  String get allSubjectsOption => 'All grade subjects';

  @override
  String get selectedSubjectsOption => 'Selected subjects only';

  @override
  String get addParentInline => 'Add parent with student';

  @override
  String get parentName => 'Parent name';

  @override
  String get parentPhone => 'Parent phone';

  @override
  String get orLinkExistingParent => 'Or link existing parent';

  @override
  String get studentDetails => 'Student details';

  @override
  String get teacherDetails => 'Teacher details';

  @override
  String get teacherGroups => 'Teacher groups';

  @override
  String get taughtSessions => 'Sessions taught';

  @override
  String get evaluations => 'Evaluations';

  @override
  String get addEvaluation => 'Add evaluation';

  @override
  String get score => 'Score';

  @override
  String get attendedSessions => 'Sessions attended';

  @override
  String get studentGroups => 'Student groups';

  @override
  String get teacherPhoto => 'Teacher photo';

  @override
  String get teacherPhotoOptional => 'Teacher photo (optional)';

  @override
  String get pickPhoto => 'Choose photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get removePhoto => 'Remove photo';
}
