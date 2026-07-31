import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fingerprint_app/features/admin/presentation/pages/classrooms_page.dart';
import 'package:fingerprint_app/features/admin/presentation/pages/dashboard_page.dart';
import 'package:fingerprint_app/features/admin/presentation/pages/enrollments_page.dart';
import 'package:fingerprint_app/features/admin/presentation/pages/grades_page.dart';
import 'package:fingerprint_app/features/admin/presentation/pages/groups_page.dart';
import 'package:fingerprint_app/features/admin/presentation/pages/parents_page.dart';
import 'package:fingerprint_app/features/admin/presentation/pages/schedules_page.dart';
import 'package:fingerprint_app/features/admin/presentation/pages/stages_page.dart';
import 'package:fingerprint_app/features/admin/presentation/pages/students_page.dart';
import 'package:fingerprint_app/features/admin/presentation/pages/subjects_page.dart';
import 'package:fingerprint_app/features/admin/presentation/pages/teachers_page.dart';
import 'package:fingerprint_app/features/admin/presentation/shell/admin_shell.dart';
import 'package:fingerprint_app/features/auth/domain/entities/app_user.dart';
import 'package:fingerprint_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fingerprint_app/features/auth/presentation/pages/login_page.dart';
import 'package:fingerprint_app/features/settings/presentation/pages/settings_page.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/admin',
    refreshListenable: _AuthRefresh(authCubit),
    redirect: (context, state) {
      final authState = authCubit.state;
      final loggingIn = state.matchedLocation == '/login';

      if (authState is AuthInitial || authState is AuthLoading) {
        return loggingIn ? null : '/login';
      }

      final signedIn = authState is AuthAuthenticated;
      if (!signedIn && !loggingIn) return '/login';
      if (signedIn && loggingIn) {
        final user = (authState).user;
        return user.role == UserRole.admin ? '/admin' : '/login';
      }
      if (signedIn &&
          state.matchedLocation.startsWith('/admin') &&
          (authState).user.role != UserRole.admin) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/admin/stages',
            builder: (context, state) => const StagesPage(),
          ),
          GoRoute(
            path: '/admin/grades',
            builder: (context, state) => const GradesPage(),
          ),
          GoRoute(
            path: '/admin/subjects',
            builder: (context, state) => const SubjectsPage(),
          ),
          GoRoute(
            path: '/admin/classrooms',
            builder: (context, state) => const ClassroomsPage(),
          ),
          GoRoute(
            path: '/admin/teachers',
            builder: (context, state) => const TeachersPage(),
          ),
          GoRoute(
            path: '/admin/students',
            builder: (context, state) => const StudentsPage(),
          ),
          GoRoute(
            path: '/admin/parents',
            builder: (context, state) => const ParentsPage(),
          ),
          GoRoute(
            path: '/admin/groups',
            builder: (context, state) => const GroupsPage(),
          ),
          GoRoute(
            path: '/admin/schedules',
            builder: (context, state) => const SchedulesPage(),
          ),
          GoRoute(
            path: '/admin/enrollments',
            builder: (context, state) => const EnrollmentsPage(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        body: Center(child: Text('${l10n.pageNotFound}: ${state.error}')),
      );
    },
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._cubit) {
    _cubit.stream.listen((_) => notifyListeners());
  }

  final AuthCubit _cubit;
}
