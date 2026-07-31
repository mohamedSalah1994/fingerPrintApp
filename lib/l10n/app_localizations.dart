import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Center Management'**
  String get appTitle;

  /// No description provided for @controlPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Control Panel'**
  String get controlPanel;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password is too short'**
  String get passwordTooShort;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeUser(String name);

  /// No description provided for @welcomeGuest.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeGuest;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Education center overview'**
  String get dashboardSubtitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @stages.
  ///
  /// In en, this message translates to:
  /// **'Stages'**
  String get stages;

  /// No description provided for @grades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get grades;

  /// No description provided for @subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjects;

  /// No description provided for @classrooms.
  ///
  /// In en, this message translates to:
  /// **'Classrooms'**
  String get classrooms;

  /// No description provided for @teachers.
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get teachers;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @parents.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get parents;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @schedules.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedules;

  /// No description provided for @enrollments.
  ///
  /// In en, this message translates to:
  /// **'Enrollments'**
  String get enrollments;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @quickShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Quick shortcuts'**
  String get quickShortcuts;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlink;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm delete'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete \"{name}\"?'**
  String confirmDeleteMessage(String name);

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @parentGuardian.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parentGuardian;

  /// No description provided for @noChildren.
  ///
  /// In en, this message translates to:
  /// **'No children'**
  String get noChildren;

  /// No description provided for @noParent.
  ///
  /// In en, this message translates to:
  /// **'No parent'**
  String get noParent;

  /// No description provided for @manageChildren.
  ///
  /// In en, this message translates to:
  /// **'Children of {name}'**
  String manageChildren(String name);

  /// No description provided for @manageParents.
  ///
  /// In en, this message translates to:
  /// **'Parents of {name}'**
  String manageParents(String name);

  /// No description provided for @linkedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Linked successfully'**
  String get linkedSuccessfully;

  /// No description provided for @unlinkedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Unlinked successfully'**
  String get unlinkedSuccessfully;

  /// No description provided for @addStudent.
  ///
  /// In en, this message translates to:
  /// **'Add student'**
  String get addStudent;

  /// No description provided for @linkParent.
  ///
  /// In en, this message translates to:
  /// **'Link parent'**
  String get linkParent;

  /// No description provided for @allStudentsLinked.
  ///
  /// In en, this message translates to:
  /// **'All students are linked or none available'**
  String get allStudentsLinked;

  /// No description provided for @noParentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No parents available to link'**
  String get noParentsAvailable;

  /// No description provided for @linkedStudents.
  ///
  /// In en, this message translates to:
  /// **'Linked students'**
  String get linkedStudents;

  /// No description provided for @currentlyLinked.
  ///
  /// In en, this message translates to:
  /// **'Currently linked'**
  String get currentlyLinked;

  /// No description provided for @seedAdminDev.
  ///
  /// In en, this message translates to:
  /// **'Setup admin (dev only)'**
  String get seedAdminDev;

  /// No description provided for @adminSetupDone.
  ///
  /// In en, this message translates to:
  /// **'Admin ready. Signing in...'**
  String get adminSetupDone;

  /// No description provided for @centerManagement.
  ///
  /// In en, this message translates to:
  /// **'Center Admin'**
  String get centerManagement;

  /// No description provided for @systemAdmin.
  ///
  /// In en, this message translates to:
  /// **'System admin'**
  String get systemAdmin;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @allStages.
  ///
  /// In en, this message translates to:
  /// **'All stages'**
  String get allStages;

  /// No description provided for @unspecified.
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get unspecified;

  /// No description provided for @addStage.
  ///
  /// In en, this message translates to:
  /// **'Add stage'**
  String get addStage;

  /// No description provided for @editStage.
  ///
  /// In en, this message translates to:
  /// **'Edit stage'**
  String get editStage;

  /// No description provided for @stageName.
  ///
  /// In en, this message translates to:
  /// **'Stage name'**
  String get stageName;

  /// No description provided for @addGrade.
  ///
  /// In en, this message translates to:
  /// **'Add grade'**
  String get addGrade;

  /// No description provided for @editGrade.
  ///
  /// In en, this message translates to:
  /// **'Edit grade'**
  String get editGrade;

  /// No description provided for @gradeName.
  ///
  /// In en, this message translates to:
  /// **'Grade name'**
  String get gradeName;

  /// No description provided for @addStageFirst.
  ///
  /// In en, this message translates to:
  /// **'Add an education stage first'**
  String get addStageFirst;

  /// No description provided for @addSubject.
  ///
  /// In en, this message translates to:
  /// **'Add subject'**
  String get addSubject;

  /// No description provided for @editSubject.
  ///
  /// In en, this message translates to:
  /// **'Edit subject'**
  String get editSubject;

  /// No description provided for @subjectName.
  ///
  /// In en, this message translates to:
  /// **'Subject name'**
  String get subjectName;

  /// No description provided for @stageOptional.
  ///
  /// In en, this message translates to:
  /// **'Stage (optional)'**
  String get stageOptional;

  /// No description provided for @allOrUnspecified.
  ///
  /// In en, this message translates to:
  /// **'All / unspecified'**
  String get allOrUnspecified;

  /// No description provided for @addClassroom.
  ///
  /// In en, this message translates to:
  /// **'Add classroom'**
  String get addClassroom;

  /// No description provided for @editClassroom.
  ///
  /// In en, this message translates to:
  /// **'Edit classroom'**
  String get editClassroom;

  /// No description provided for @classroomName.
  ///
  /// In en, this message translates to:
  /// **'Classroom name'**
  String get classroomName;

  /// No description provided for @addTeacher.
  ///
  /// In en, this message translates to:
  /// **'Add teacher'**
  String get addTeacher;

  /// No description provided for @editTeacher.
  ///
  /// In en, this message translates to:
  /// **'Edit teacher'**
  String get editTeacher;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @editStudent.
  ///
  /// In en, this message translates to:
  /// **'Edit student'**
  String get editStudent;

  /// No description provided for @grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// No description provided for @addParent.
  ///
  /// In en, this message translates to:
  /// **'Add parent'**
  String get addParent;

  /// No description provided for @editParent.
  ///
  /// In en, this message translates to:
  /// **'Edit parent'**
  String get editParent;

  /// No description provided for @phoneWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Phone / WhatsApp'**
  String get phoneWhatsapp;

  /// No description provided for @noChildrenYet.
  ///
  /// In en, this message translates to:
  /// **'No children linked yet'**
  String get noChildrenYet;

  /// No description provided for @noParentLinked.
  ///
  /// In en, this message translates to:
  /// **'No parent linked'**
  String get noParentLinked;

  /// No description provided for @withoutParent.
  ///
  /// In en, this message translates to:
  /// **'No parent'**
  String get withoutParent;

  /// No description provided for @noChildrenShort.
  ///
  /// In en, this message translates to:
  /// **'No children'**
  String get noChildrenShort;

  /// No description provided for @parentsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No parents yet — add a parent then link students'**
  String get parentsEmptyHint;

  /// No description provided for @addGroup.
  ///
  /// In en, this message translates to:
  /// **'Add group'**
  String get addGroup;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @addGradesSubjectsFirst.
  ///
  /// In en, this message translates to:
  /// **'Add grades and subjects first'**
  String get addGradesSubjectsFirst;

  /// No description provided for @addSchedule.
  ///
  /// In en, this message translates to:
  /// **'Add session'**
  String get addSchedule;

  /// No description provided for @editSchedule.
  ///
  /// In en, this message translates to:
  /// **'Edit session'**
  String get editSchedule;

  /// No description provided for @weeklySchedule.
  ///
  /// In en, this message translates to:
  /// **'Weekly schedule'**
  String get weeklySchedule;

  /// No description provided for @addGroupFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a group first'**
  String get addGroupFirst;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @fromTime.
  ///
  /// In en, this message translates to:
  /// **'From (HH:mm)'**
  String get fromTime;

  /// No description provided for @toTime.
  ///
  /// In en, this message translates to:
  /// **'To (HH:mm)'**
  String get toTime;

  /// No description provided for @timeRequired.
  ///
  /// In en, this message translates to:
  /// **'Time required'**
  String get timeRequired;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @addEnrollment.
  ///
  /// In en, this message translates to:
  /// **'Add enrollment'**
  String get addEnrollment;

  /// No description provided for @editEnrollment.
  ///
  /// In en, this message translates to:
  /// **'Edit enrollment'**
  String get editEnrollment;

  /// No description provided for @addStudentsGradesFirst.
  ///
  /// In en, this message translates to:
  /// **'Add students and grades first'**
  String get addStudentsGradesFirst;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @enrollmentType.
  ///
  /// In en, this message translates to:
  /// **'Enrollment type'**
  String get enrollmentType;

  /// No description provided for @fullAllSubjects.
  ///
  /// In en, this message translates to:
  /// **'Full (all subjects)'**
  String get fullAllSubjects;

  /// No description provided for @partialSelected.
  ///
  /// In en, this message translates to:
  /// **'Partial (selected subjects)'**
  String get partialSelected;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get fee;

  /// No description provided for @adminNote.
  ///
  /// In en, this message translates to:
  /// **'Admin note'**
  String get adminNote;

  /// No description provided for @full.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get full;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @unlinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Unlink failed: {error}'**
  String unlinkFailed(String error);

  /// No description provided for @linkFailed.
  ///
  /// In en, this message translates to:
  /// **'Link failed: {error}'**
  String linkFailed(String error);

  /// No description provided for @unlinkedNamed.
  ///
  /// In en, this message translates to:
  /// **'Unlinked {name}'**
  String unlinkedNamed(String name);

  /// No description provided for @linkedNamed.
  ///
  /// In en, this message translates to:
  /// **'Linked {a} to {b}'**
  String linkedNamed(String a, String b);

  /// No description provided for @building.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get building;

  /// No description provided for @floor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floor;

  /// No description provided for @salaryPerSession.
  ///
  /// In en, this message translates to:
  /// **'Per session'**
  String get salaryPerSession;

  /// No description provided for @salaryPerStudent.
  ///
  /// In en, this message translates to:
  /// **'Per student'**
  String get salaryPerStudent;

  /// No description provided for @salaryMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly fixed'**
  String get salaryMonthly;

  /// No description provided for @salaryHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get salaryHybrid;

  /// No description provided for @subjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjectsTitle;

  /// No description provided for @gradesTitle.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get gradesTitle;

  /// No description provided for @stagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Stages'**
  String get stagesTitle;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
