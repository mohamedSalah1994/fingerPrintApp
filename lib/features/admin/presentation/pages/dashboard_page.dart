import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fingerprint_app/app/theme/app_colors.dart';
import 'package:fingerprint_app/core/widgets/app_animations.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/shell/admin_nav.dart';
import 'package:fingerprint_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    final l10n = AppLocalizations.of(context);
    final user = context.select(
      (AuthCubit c) => c.state is AuthAuthenticated
          ? (c.state as AuthAuthenticated).user
          : null,
    );
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final cards = <_StatSpec>[
      _StatSpec(
        l10n.stages,
        Icons.layers_outlined,
        AppColors.primary,
        repo.watchStages().map((e) => e.length),
        '/admin/stages',
      ),
      _StatSpec(
        l10n.students,
        Icons.school_outlined,
        AppColors.info,
        repo.watchStudents().map((e) => e.length),
        '/admin/students',
      ),
      _StatSpec(
        l10n.teachers,
        Icons.badge_outlined,
        AppColors.accent,
        repo.watchTeachers().map((e) => e.length),
        '/admin/teachers',
      ),
      _StatSpec(
        l10n.groups,
        Icons.groups_outlined,
        AppColors.success,
        repo.watchGroups().map((e) => e.length),
        '/admin/groups',
      ),
      _StatSpec(
        l10n.enrollments,
        Icons.assignment_ind_outlined,
        const Color(0xFFC45C26),
        repo.watchEnrollments().map((e) => e.length),
        '/admin/enrollments',
      ),
      _StatSpec(
        l10n.classrooms,
        Icons.meeting_room_outlined,
        const Color(0xFF2F6B8A),
        repo.watchClassrooms().map((e) => e.length),
        '/admin/classrooms',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        FadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user != null
                      ? l10n.welcomeUser(user.displayName)
                      : l10n.welcomeGuest,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.dashboardSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var i = 0; i < cards.length; i++)
              FadeSlideIn(
                delay: Duration(milliseconds: 60 * i),
                child: _StatCard(spec: cards[i]),
              ),
          ],
        ),
        const SizedBox(height: 28),
        FadeSlideIn(
          delay: const Duration(milliseconds: 320),
          child: Text(
            l10n.quickShortcuts,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 380),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in AdminNav.destinations.skip(1).take(6))
                ScaleTap(
                  onTap: () => context.go(d.path),
                  child: AbsorbPointer(
                    child: ActionChip(
                      avatar:
                          Icon(d.icon, size: 18, color: scheme.primary),
                      label: Text(d.labelBuilder(l10n)),
                      onPressed: () {},
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatSpec {
  const _StatSpec(this.label, this.icon, this.color, this.stream, this.path);

  final String label;
  final IconData icon;
  final Color color;
  final Stream<int> stream;
  final String path;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.spec});

  final _StatSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ScaleTap(
      onTap: () => context.go(spec.path),
      child: SizedBox(
        width: 190,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: spec.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(spec.icon, color: spec.color),
              ),
              const SizedBox(height: 14),
              StreamBuilder<int>(
                stream: spec.stream,
                builder: (context, snap) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      '${snap.data ?? '—'}',
                      key: ValueKey(snap.data),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                spec.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
