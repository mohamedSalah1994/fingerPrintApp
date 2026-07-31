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
}
