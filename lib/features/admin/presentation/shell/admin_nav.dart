import 'package:flutter/material.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class AdminDestination {
  const AdminDestination({
    required this.labelBuilder,
    required this.icon,
    required this.path,
  });

  final String Function(AppLocalizations l10n) labelBuilder;
  final IconData icon;
  final String path;
}

abstract final class AdminNav {
  static const destinations = <AdminDestination>[
    AdminDestination(
      labelBuilder: _dashboard,
      icon: Icons.dashboard_outlined,
      path: '/admin',
    ),
    AdminDestination(
      labelBuilder: _stages,
      icon: Icons.layers_outlined,
      path: '/admin/stages',
    ),
    AdminDestination(
      labelBuilder: _grades,
      icon: Icons.class_outlined,
      path: '/admin/grades',
    ),
    AdminDestination(
      labelBuilder: _subjects,
      icon: Icons.menu_book_outlined,
      path: '/admin/subjects',
    ),
    AdminDestination(
      labelBuilder: _classrooms,
      icon: Icons.meeting_room_outlined,
      path: '/admin/classrooms',
    ),
    AdminDestination(
      labelBuilder: _teachers,
      icon: Icons.badge_outlined,
      path: '/admin/teachers',
    ),
    AdminDestination(
      labelBuilder: _students,
      icon: Icons.school_outlined,
      path: '/admin/students',
    ),
    AdminDestination(
      labelBuilder: _parents,
      icon: Icons.family_restroom_outlined,
      path: '/admin/parents',
    ),
    AdminDestination(
      labelBuilder: _groups,
      icon: Icons.groups_outlined,
      path: '/admin/groups',
    ),
    AdminDestination(
      labelBuilder: _schedules,
      icon: Icons.calendar_month_outlined,
      path: '/admin/schedules',
    ),
    AdminDestination(
      labelBuilder: _enrollments,
      icon: Icons.assignment_ind_outlined,
      path: '/admin/enrollments',
    ),
    AdminDestination(
      labelBuilder: _settings,
      icon: Icons.settings_outlined,
      path: '/admin/settings',
    ),
  ];

  static String _dashboard(AppLocalizations l) => l.dashboard;
  static String _stages(AppLocalizations l) => l.stages;
  static String _grades(AppLocalizations l) => l.grades;
  static String _subjects(AppLocalizations l) => l.subjects;
  static String _classrooms(AppLocalizations l) => l.classrooms;
  static String _teachers(AppLocalizations l) => l.teachers;
  static String _students(AppLocalizations l) => l.students;
  static String _parents(AppLocalizations l) => l.parents;
  static String _groups(AppLocalizations l) => l.groups;
  static String _schedules(AppLocalizations l) => l.schedules;
  static String _enrollments(AppLocalizations l) => l.enrollments;
  static String _settings(AppLocalizations l) => l.settings;

  static int indexForLocation(String location) {
    if (location == '/admin' || location == '/admin/') return 0;
    for (var i = 1; i < destinations.length; i++) {
      if (location.startsWith(destinations[i].path)) return i;
    }
    return 0;
  }
}
