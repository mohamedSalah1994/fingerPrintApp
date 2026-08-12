// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نظام إدارة السنتر';

  @override
  String get controlPanel => 'لوحة التحكم الإدارية';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get enterEmail => 'أدخل البريد الإلكتروني';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get invalidEmail => 'بريد غير صالح';

  @override
  String get passwordTooShort => 'كلمة المرور قصيرة جداً';

  @override
  String welcomeUser(String name) {
    return 'مرحباً، $name';
  }

  @override
  String get welcomeGuest => 'مرحباً';

  @override
  String get dashboardSubtitle => 'لوحة إدارة السنتر التعليمي — نظرة سريعة على النظام';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get stages => 'المراحل';

  @override
  String get grades => 'الصفوف';

  @override
  String get subjects => 'المواد';

  @override
  String get classrooms => 'القاعات';

  @override
  String get teachers => 'المدرسون';

  @override
  String get students => 'الطلاب';

  @override
  String get parents => 'أولياء الأمور';

  @override
  String get groups => 'المجموعات';

  @override
  String get schedules => 'الجدول';

  @override
  String get enrollments => 'الاشتراكات';

  @override
  String get settings => 'الإعدادات';

  @override
  String get quickShortcuts => 'اختصارات سريعة';

  @override
  String get todayOverview => 'نظرة اليوم';

  @override
  String get attendanceAnalysis => 'تحليل الحضور اليوم';

  @override
  String get attendanceRate => 'نسبة الحضور';

  @override
  String get checkedInToday => 'حضروا اليوم';

  @override
  String get fingerprintPunchesToday => 'بصمات اليوم';

  @override
  String get insightsAndAlerts => 'تنبيهات وإجراءات';

  @override
  String get todaySessions => 'حصص اليوم';

  @override
  String get noSessionsToday => 'لا توجد حصص مجدولة اليوم';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get actionAddStudent => 'إضافة طالب';

  @override
  String get actionOpenAttendance => 'سجل الحضور';

  @override
  String get actionManageDevices => 'الأجهزة والمزامنة';

  @override
  String get actionManageGroups => 'إدارة المجموعات';

  @override
  String get actionEnrollments => 'التسجيلات';

  @override
  String get actionSchedules => 'الجدول الأسبوعي';

  @override
  String get alertNoDevices => 'لا يوجد جهاز بصمة مسجّل';

  @override
  String alertStudentsUnmapped(int count) {
    return '$count طالب بدون ربط بصمة';
  }

  @override
  String get alertNoAttendanceToday => 'لا يوجد حضور مسجّل اليوم بعد';

  @override
  String alertHighAbsent(int count) {
    return 'غياب مرتفع اليوم: $count';
  }

  @override
  String alertDevicesReady(int count) {
    return '$count جهاز جاهز للمزامنة';
  }

  @override
  String get fixLinkFingerprints => 'ربط البصمات';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get systemTotals => 'إحصائيات النظام';

  @override
  String get devicesOnlineLabel => 'أجهزة نشطة';

  @override
  String get add => 'إضافة';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get close => 'إغلاق';

  @override
  String get link => 'ربط';

  @override
  String get unlink => 'إلغاء الربط';

  @override
  String get actions => 'إجراءات';

  @override
  String get confirmDelete => 'تأكيد الحذف';

  @override
  String confirmDeleteMessage(String name) {
    return 'هل تريد حذف \"$name\"؟';
  }

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get name => 'الاسم';

  @override
  String get phone => 'الهاتف';

  @override
  String get order => 'الترتيب';

  @override
  String get capacity => 'السعة';

  @override
  String get required => 'مطلوب';

  @override
  String get number => 'رقم';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get collapseSidebar => 'طي الشريط الجانبي';

  @override
  String get expandSidebar => 'توسيع الشريط الجانبي';

  @override
  String get lightMode => 'فاتح';

  @override
  String get darkMode => 'داكن';

  @override
  String get systemMode => 'حسب النظام';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get appearance => 'المظهر';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get children => 'الأبناء';

  @override
  String get parentGuardian => 'ولي الأمر';

  @override
  String get noChildren => 'لا يوجد';

  @override
  String get noParent => 'لا يوجد';

  @override
  String manageChildren(String name) {
    return 'أبناء: $name';
  }

  @override
  String manageParents(String name) {
    return 'أولياء أمور: $name';
  }

  @override
  String get linkedSuccessfully => 'تم الربط بنجاح';

  @override
  String get unlinkedSuccessfully => 'تم إلغاء الربط';

  @override
  String get addStudent => 'إضافة طالب';

  @override
  String get linkParent => 'ربط ولي أمر';

  @override
  String get allStudentsLinked => 'كل الطلاب مرتبطون أو لا يوجد طلاب';

  @override
  String get noParentsAvailable => 'لا يوجد أولياء أمور متاحون للربط';

  @override
  String get linkedStudents => 'الطلاب المرتبطون';

  @override
  String get currentlyLinked => 'المرتبطون حالياً';

  @override
  String get seedAdminDev => 'إعداد مدير (تطوير فقط)';

  @override
  String get adminSetupDone => 'تم إعداد المدير. جارٍ تسجيل الدخول...';

  @override
  String get centerManagement => 'إدارة السنتر';

  @override
  String get systemAdmin => 'مدير النظام';

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get allStages => 'كل المراحل';

  @override
  String get unspecified => 'غير محدد';

  @override
  String get addStage => 'إضافة مرحلة';

  @override
  String get editStage => 'تعديل مرحلة';

  @override
  String get stageName => 'اسم المرحلة';

  @override
  String get addGrade => 'إضافة صف';

  @override
  String get editGrade => 'تعديل صف';

  @override
  String get gradeName => 'اسم الصف';

  @override
  String get addStageFirst => 'أضف مرحلة تعليمية أولاً';

  @override
  String get addSubject => 'إضافة مادة';

  @override
  String get editSubject => 'تعديل مادة';

  @override
  String get subjectName => 'اسم المادة';

  @override
  String get stageOptional => 'المرحلة (اختياري)';

  @override
  String get allOrUnspecified => 'الكل / غير محدد';

  @override
  String get addClassroom => 'إضافة قاعة';

  @override
  String get editClassroom => 'تعديل قاعة';

  @override
  String get classroomName => 'اسم القاعة';

  @override
  String get addTeacher => 'إضافة مدرس';

  @override
  String get editTeacher => 'تعديل مدرس';

  @override
  String get paymentMethod => 'طريقة الحساب';

  @override
  String get editStudent => 'تعديل طالب';

  @override
  String get grade => 'الصف';

  @override
  String get addParent => 'إضافة ولي أمر';

  @override
  String get editParent => 'تعديل ولي أمر';

  @override
  String get phoneWhatsapp => 'الهاتف / واتساب';

  @override
  String get noChildrenYet => 'لا يوجد أبناء مرتبطون بعد';

  @override
  String get noParentLinked => 'لا يوجد ولي أمر مرتبط';

  @override
  String get withoutParent => 'بدون ولي أمر';

  @override
  String get noChildrenShort => 'لا يوجد أبناء';

  @override
  String get parentsEmptyHint => 'لا يوجد أولياء أمور — أضف ولي أمر ثم اربطه بطلاب';

  @override
  String get addGroup => 'إضافة مجموعة';

  @override
  String get editGroup => 'تعديل مجموعة';

  @override
  String get groupName => 'اسم المجموعة';

  @override
  String get addGradesSubjectsFirst => 'أضف صفوف ومواد أولاً';

  @override
  String get addSchedule => 'إضافة حصة';

  @override
  String get editSchedule => 'تعديل حصة';

  @override
  String get weeklySchedule => 'الجدول الأسبوعي';

  @override
  String get addGroupFirst => 'أضف مجموعة أولاً';

  @override
  String get day => 'اليوم';

  @override
  String get fromTime => 'من (HH:mm)';

  @override
  String get toTime => 'إلى (HH:mm)';

  @override
  String get timeRequired => 'وقت';

  @override
  String get group => 'المجموعة';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get monday => 'الاثنين';

  @override
  String get tuesday => 'الثلاثاء';

  @override
  String get wednesday => 'الأربعاء';

  @override
  String get thursday => 'الخميس';

  @override
  String get friday => 'الجمعة';

  @override
  String get saturday => 'السبت';

  @override
  String get sunday => 'الأحد';

  @override
  String get addEnrollment => 'إضافة اشتراك';

  @override
  String get editEnrollment => 'تعديل اشتراك';

  @override
  String get addStudentsGradesFirst => 'أضف طلاب وصفوف أولاً';

  @override
  String get student => 'الطالب';

  @override
  String get enrollmentType => 'نوع الاشتراك';

  @override
  String get fullAllSubjects => 'كامل (كل المواد)';

  @override
  String get partialSelected => 'جزئي (مواد محددة)';

  @override
  String get fee => 'الرسوم';

  @override
  String get adminNote => 'ملاحظة الإدارة';

  @override
  String get full => 'كامل';

  @override
  String get partial => 'جزئي';

  @override
  String get type => 'النوع';

  @override
  String unlinkFailed(String error) {
    return 'فشل الإلغاء: $error';
  }

  @override
  String linkFailed(String error) {
    return 'فشل الربط: $error';
  }

  @override
  String unlinkedNamed(String name) {
    return 'تم إلغاء ربط $name';
  }

  @override
  String linkedNamed(String a, String b) {
    return 'تم ربط $a بـ $b';
  }

  @override
  String get building => 'المبنى';

  @override
  String get floor => 'الدور';

  @override
  String get salaryPerSession => 'بالحصة';

  @override
  String get salaryPerStudent => 'بعدد الطلاب';

  @override
  String get salaryMonthly => 'شهري ثابت';

  @override
  String get salaryHybrid => 'مختلط';

  @override
  String get subjectsTitle => 'المواد الدراسية';

  @override
  String get gradesTitle => 'الصفوف الدراسية';

  @override
  String get stagesTitle => 'المراحل';

  @override
  String get attendance => 'الحضور والغياب';

  @override
  String get users => 'المستخدمون';

  @override
  String get addAttendance => 'إضافة حضور';

  @override
  String get editAttendance => 'تعديل حضور';

  @override
  String get checkIn => 'وقت الحضور';

  @override
  String get source => 'المصدر';

  @override
  String get statusPresent => 'حاضر';

  @override
  String get statusLate => 'متأخر';

  @override
  String get statusAbsent => 'غائب';

  @override
  String get statusExcused => 'بعذر';

  @override
  String get sourceManual => 'يدوي';

  @override
  String get sourceFingerprint => 'بصمة';

  @override
  String get sourceDevice => 'جهاز';

  @override
  String get addUser => 'إضافة مستخدم';

  @override
  String get createAdminUser => 'إنشاء مستخدم مدير';

  @override
  String get createTeacherUser => 'إنشاء مستخدم مدرس';

  @override
  String get loginEmail => 'بريد الدخول';

  @override
  String get loginPassword => 'كلمة مرور الدخول';

  @override
  String get teacherAppLogin => 'دخول تطبيق المدرس';

  @override
  String get accountLinked => 'حساب التطبيق مرتبط';

  @override
  String get accountNotLinked => 'لا يوجد حساب تطبيق';

  @override
  String get roleAdmin => 'مدير';

  @override
  String get roleTeacher => 'مدرس';

  @override
  String get passwordMin6 => 'كلمة المرور ٦ أحرف على الأقل';

  @override
  String get userCreated => 'تم إنشاء المستخدم بنجاح';

  @override
  String get date => 'التاريخ';

  @override
  String get status => 'الحالة';

  @override
  String get role => 'الدور';

  @override
  String get account => 'الحساب';

  @override
  String userCreateFailed(String error) {
    return 'فشل إنشاء المستخدم: $error';
  }

  @override
  String get invalidDate => 'تاريخ غير صالح (yyyy-MM-dd)';

  @override
  String get pickDate => 'اختر التاريخ';

  @override
  String get noStudentsYet => 'أضف طالباً أولاً';

  @override
  String get createLoginHint => 'ينشئ حساب دخول لفتح تطبيق المدرس';

  @override
  String get devices => 'الأجهزة';

  @override
  String get addDevice => 'إضافة جهاز';

  @override
  String get editDevice => 'تعديل جهاز';

  @override
  String get serialNumber => 'الرقم التسلسلي';

  @override
  String get ipAddress => 'عنوان IP';

  @override
  String get port => 'المنفذ';

  @override
  String get commKey => 'مفتاح الاتصال';

  @override
  String get location => 'الموقع';

  @override
  String get forceUdp => 'فرض UDP';

  @override
  String get testConnection => 'اختبار الاتصال';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get syncAll => 'مزامنة الكل';

  @override
  String get sidecarOnline => 'الخدمة المساعدة متصلّة';

  @override
  String get sidecarOffline => 'الخدمة المساعدة غير متصلّة';

  @override
  String get sidecarHint => 'على نفس جهاز السنتر: شغّل zk_sidecar\\install_autostart.bat واترك الخدمة تعمل. من Chrome اسمح بالوصول للشبكة المحلية لهذا الموقع ثم أعد المحاولة';

  @override
  String get sidecarConnecting => 'جاري الاتصال بالخدمة المساعدة…';

  @override
  String get sidecarConnectingHint => 'يتم تشغيل الخدمة تلقائيًا والتحقق من الاتصال';

  @override
  String get sidecarRetry => 'إعادة المحاولة';

  @override
  String get startAutoSync => 'بدء المزامنة التلقائية';

  @override
  String get stopAutoSync => 'إيقاف الحلقة';

  @override
  String get biometricMappings => 'ربط البصمة';

  @override
  String get addMapping => 'إضافة ربط';

  @override
  String get deviceUserId => 'معرّف المستخدم على الجهاز';

  @override
  String get deviceUsers => 'مستخدمو الجهاز';

  @override
  String get linkStudent => 'ربط طالب';

  @override
  String get mappingSaved => 'تم حفظ الربط';

  @override
  String get connectionOk => 'الاتصال ناجح';

  @override
  String get connectionFailed => 'فشل الاتصال';

  @override
  String get syncDone => 'اكتملت المزامنة';

  @override
  String get syncFailed => 'فشلت المزامنة';

  @override
  String get attendanceBySession => 'حسب الحصة';

  @override
  String get sessionSearch => 'بحث بالحصة';

  @override
  String get sessionNumber => 'رقم الحصة';

  @override
  String get sessionStudents => 'طلاب الحصة';

  @override
  String get markPresent => 'تسجيل حضور';

  @override
  String get clearAttendance => 'إلغاء الحضور';

  @override
  String get studentPhone => 'هاتف الطالب';

  @override
  String get allDates => 'كل التواريخ';

  @override
  String get studentsCount => 'عدد الطلاب';

  @override
  String get sessionSearchHint => 'فلتر بالتاريخ أو المجموعة أو الحصة — اضغط حصة لعرض الطلاب';

  @override
  String get selectSession => 'اختر الحصة';

  @override
  String get selectGroup => 'اختر المجموعة';

  @override
  String get noSessionsOnDate => 'لا توجد حصص في هذا التاريخ';

  @override
  String get sessionNotStartedYet => 'لم تبدأ بعد';

  @override
  String get notCheckedInYet => 'لم يسجّل بعد';

  @override
  String get carriedFromPreviousSession => 'من الحصة السابقة';

  @override
  String get studentHistory => 'سجل الطالب';

  @override
  String get allGroups => 'كل المجموعات';

  @override
  String get sessionTime => 'وقت الحصة';

  @override
  String get noSessionsForDay => 'لا توجد حصص أو سجلات لهذا اليوم';

  @override
  String get scheduledNoRecordsYet => 'حصة مجدولة — لا سجلات بعد';

  @override
  String get offScheduleAttendance => 'خارج أيام الجدول';

  @override
  String get noHistoryForStudent => 'لا يوجد سجل حضور لهذا الطالب';

  @override
  String get selectStudent => 'اختر طالبًا';

  @override
  String presentCount(int count) {
    return 'حاضر: $count';
  }

  @override
  String lateCount(int count) {
    return 'متأخر: $count';
  }

  @override
  String absentCount(int count) {
    return 'غائب: $count';
  }

  @override
  String punchesCount(int count) {
    return '$count بصمة';
  }

  @override
  String get ungroupedSession => 'بدون مجموعة';

  @override
  String get punches => 'البصمات';

  @override
  String get scheduleSlot => 'الجدول';

  @override
  String get search => 'بحث';

  @override
  String get searchHint => 'اكتب للبحث…';

  @override
  String get searchDebounceHint => 'يتم البحث بعد ثانية من التوقف عن الكتابة';

  @override
  String get noSearchResults => 'لا توجد نتائج';

  @override
  String get rowsPerPage => 'لكل صفحة';

  @override
  String get previousPage => 'السابق';

  @override
  String get nextPage => 'التالي';

  @override
  String pageOf(int page, int total) {
    return 'صفحة $page من $total';
  }

  @override
  String paginationSummary(int from, int to, int total) {
    return '$from–$to من $total';
  }

  @override
  String get groupPeriod => 'مدة المجموعة';

  @override
  String get periodDaily => 'يومي';

  @override
  String get periodWeekly => 'أسبوعي';

  @override
  String get periodMonthly => 'شهري';

  @override
  String get startDate => 'من تاريخ';

  @override
  String get endDate => 'إلى تاريخ';

  @override
  String get sessions => 'موعد الحصة الأسبوعي';

  @override
  String get addSession => 'إضافة حصة';

  @override
  String get sessionTeacher => 'مدرس الحصة';

  @override
  String get selectWeekdays => 'أيام الأسبوع';

  @override
  String get selectWeekdaysHint => 'أضف حصة: اختر المادة والأيام (يمكن أكثر من يوم) والوقت';

  @override
  String get groupStudents => 'طلاب المجموعة';

  @override
  String get selectStudents => 'اختر الطلاب';

  @override
  String selectedStudentsCount(int count) {
    return 'مختار: $count';
  }

  @override
  String get selectAllVisible => 'تحديد الظاهر';

  @override
  String get clearSelection => 'مسح التحديد';

  @override
  String get done => 'تم';

  @override
  String get noStudentsForGrade => 'لا يوجد طلاب لهذا الصف';

  @override
  String get plannedSessions => 'عدد الحصص';

  @override
  String plannedSessionsCount(int count) {
    return '$count حصة خلال المدة';
  }

  @override
  String sessionPlanSummary(int days, int count) {
    return '$days أيام/أسبوع → $count حصة · الحضور والغياب على طلاب المجموعة';
  }

  @override
  String get pickAtLeastOneWeekday => 'اختر يومًا واحدًا على الأقل للحصص';

  @override
  String get invalidDateRange => 'تاريخ النهاية يجب أن يكون بعد البداية';

  @override
  String get subjectScopeGrade => 'على صف محدد';

  @override
  String get subjectScopeStage => 'على مرحلة (كل صفوفها)';

  @override
  String get teachingGrades => 'الصفوف التي يدرّسها';

  @override
  String get specializedSubjects => 'المواد المتخصص فيها';

  @override
  String get allSubjectsOption => 'كل مواد الصف';

  @override
  String get selectedSubjectsOption => 'مواد محددة فقط';

  @override
  String get addParentInline => 'إضافة ولي أمر مع الطالب';

  @override
  String get parentName => 'اسم ولي الأمر';

  @override
  String get parentPhone => 'هاتف ولي الأمر';

  @override
  String get orLinkExistingParent => 'أو ربط ولي أمر موجود';

  @override
  String get studentDetails => 'تفاصيل الطالب';

  @override
  String get teacherDetails => 'تفاصيل المدرس';

  @override
  String get teacherGroups => 'مجموعات المدرس';

  @override
  String get taughtSessions => 'حصص يدرّسها';

  @override
  String get evaluations => 'التقييمات';

  @override
  String get addEvaluation => 'إضافة تقييم';

  @override
  String get score => 'الدرجة';

  @override
  String get attendedSessions => 'حصص حضرها';

  @override
  String get studentGroups => 'مجموعات الطالب';

  @override
  String get teacherPhoto => 'صورة المدرس';

  @override
  String get teacherPhotoOptional => 'صورة المدرس (اختياري)';

  @override
  String get pickPhoto => 'اختيار صورة';

  @override
  String get changePhoto => 'تغيير الصورة';

  @override
  String get removePhoto => 'إزالة الصورة';
}
