import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fingerprint_app/app/theme/app_colors.dart';
import 'package:fingerprint_app/core/widgets/app_animations.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/dashboard_cubit.dart';
import 'package:fingerprint_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit(context.read<AdminRepository>()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.select(
      (AuthCubit c) => c.state is AuthAuthenticated
          ? (c.state as AuthAuthenticated).user
          : null,
    );
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.loading && state.snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.snapshot == null) {
          return Center(child: Text(state.error!));
        }
        final snap = state.snapshot!;
        final groupName = {for (final g in snap.groups) g.id: g.name};

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FadeSlideIn(child: _HeroBanner(userName: user?.displayName)),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: Text(
                l10n.todayOverview,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 90),
              child: _TodayKpiRow(snap: snap),
            ),
            const SizedBox(height: 22),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: _AttendanceAnalysisCard(snap: snap),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: _InsightsCard(snap: snap),
                    ),
                  ),
                ],
              )
            else ...[
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: _AttendanceAnalysisCard(snap: snap),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 150),
                child: _InsightsCard(snap: snap),
              ),
            ],
            const SizedBox(height: 22),
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: Text(
                l10n.quickActions,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: _QuickActionsGrid(),
            ),
            const SizedBox(height: 22),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 230),
                      child: _TodaySessionsCard(
                        snap: snap,
                        groupName: groupName,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 260),
                      child: _SystemTotalsCard(snap: snap),
                    ),
                  ),
                ],
              )
            else ...[
              FadeSlideIn(
                delay: const Duration(milliseconds: 230),
                child: _TodaySessionsCard(snap: snap, groupName: groupName),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: _SystemTotalsCard(snap: snap),
              ),
            ],
            ],
          );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.userName});

  final String? userName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
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
            userName != null
                ? l10n.welcomeUser(userName!)
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
    );
  }
}

class _TodayKpiRow extends StatelessWidget {
  const _TodayKpiRow({required this.snap});

  final DashboardSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      _Kpi(
        l10n.checkedInToday,
        '${snap.uniqueCheckedInToday}',
        Icons.how_to_reg_rounded,
        AppColors.success,
        '/admin/attendance',
      ),
      _Kpi(
        l10n.statusLate,
        '${snap.lateToday}',
        Icons.schedule_rounded,
        AppColors.warning,
        '/admin/attendance',
      ),
      _Kpi(
        l10n.statusAbsent,
        '${snap.absentToday}',
        Icons.person_off_outlined,
        AppColors.danger,
        '/admin/attendance',
      ),
      _Kpi(
        l10n.fingerprintPunchesToday,
        '${snap.fingerprintToday}',
        Icons.fingerprint_rounded,
        AppColors.info,
        '/admin/devices',
      ),
      _Kpi(
        l10n.devicesOnlineLabel,
        '${snap.activeDevices}/${snap.devices.length}',
        Icons.devices_rounded,
        AppColors.primary,
        '/admin/devices',
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cardW = w >= 1100
            ? (w - 56) / 5
            : w >= 700
                ? (w - 28) / 3
                : (w - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                width: cardW.clamp(150, 260),
                child: _KpiCard(kpi: items[i], delayMs: 40 * i),
              ),
          ],
        );
      },
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value, this.icon, this.color, this.path);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String path;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi, required this.delayMs});

  final _Kpi kpi;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return FadeSlideIn(
      delay: Duration(milliseconds: delayMs),
      child: ScaleTap(
        onTap: () => context.go(kpi.path),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kpi.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(kpi.icon, color: kpi.color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                kpi.value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                kpi.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
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

class _AttendanceAnalysisCard extends StatelessWidget {
  const _AttendanceAnalysisCard({required this.snap});

  final DashboardSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = snap.presentToday + snap.lateToday + snap.absentToday + snap.excusedToday;
    final rate = snap.attendanceRate;

    return _Panel(
      title: l10n.attendanceAnalysis,
      trailing: TextButton(
        onPressed: () => context.go('/admin/attendance'),
        child: Text(l10n.viewDetails),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: rate),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: value,
                          strokeWidth: 9,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: AppColors.primary,
                        ),
                        Center(
                          child: Text(
                            '${(value * 100).round()}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.attendanceRate,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${snap.uniqueCheckedInToday} / ${snap.uniqueStudentsMarkedToday == 0 ? '—' : snap.uniqueStudentsMarkedToday}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.fingerprintPunchesToday}: ${snap.fingerprintToday}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _StatusBar(
            label: l10n.statusPresent,
            count: snap.presentToday,
            total: total,
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          _StatusBar(
            label: l10n.statusLate,
            count: snap.lateToday,
            total: total,
            color: AppColors.warning,
          ),
          const SizedBox(height: 8),
          _StatusBar(
            label: l10n.statusAbsent,
            count: snap.absentToday,
            total: total,
            color: AppColors.danger,
          ),
          const SizedBox(height: 8),
          _StatusBar(
            label: l10n.statusExcused,
            count: snap.excusedToday,
            total: total,
            color: AppColors.info,
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total == 0 ? 0.0 : count / total;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$count',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.12),
                color: color,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.snap});

  final DashboardSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final alerts = <_AlertItem>[];

    if (snap.devices.isEmpty) {
      alerts.add(
        _AlertItem(
          l10n.alertNoDevices,
          Icons.device_unknown_outlined,
          AppColors.warning,
          l10n.actionManageDevices,
          '/admin/devices',
        ),
      );
    } else if (snap.devicesWithIp > 0) {
      alerts.add(
        _AlertItem(
          l10n.alertDevicesReady(snap.devicesWithIp),
          Icons.sync_rounded,
          AppColors.info,
          l10n.actionManageDevices,
          '/admin/devices',
        ),
      );
    }

    if (snap.studentsWithoutFingerprint > 0) {
      alerts.add(
        _AlertItem(
          l10n.alertStudentsUnmapped(snap.studentsWithoutFingerprint),
          Icons.link_off_rounded,
          AppColors.accent,
          l10n.fixLinkFingerprints,
          '/admin/devices',
        ),
      );
    }

    if (snap.attendanceEventsToday == 0) {
      alerts.add(
        _AlertItem(
          l10n.alertNoAttendanceToday,
          Icons.event_busy_outlined,
          AppColors.danger,
          l10n.actionOpenAttendance,
          '/admin/attendance',
        ),
      );
    } else if (snap.absentToday >= 3 &&
        snap.absentToday >= snap.uniqueCheckedInToday) {
      alerts.add(
        _AlertItem(
          l10n.alertHighAbsent(snap.absentToday),
          Icons.warning_amber_rounded,
          AppColors.danger,
          l10n.viewDetails,
          '/admin/attendance',
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        _AlertItem(
          l10n.dashboardSubtitle,
          Icons.verified_outlined,
          AppColors.success,
          l10n.viewDetails,
          '/admin/attendance',
        ),
      );
    }

    return _Panel(
      title: l10n.insightsAndAlerts,
      child: Column(
        children: [
          for (var i = 0; i < alerts.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _AlertTile(item: alerts[i]),
          ],
        ],
      ),
    );
  }
}

class _AlertItem {
  const _AlertItem(
    this.message,
    this.icon,
    this.color,
    this.actionLabel,
    this.path,
  );

  final String message;
  final IconData icon;
  final Color color;
  final String actionLabel;
  final String path;
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.item});

  final _AlertItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: item.color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go(item.path),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go(item.path),
                child: Text(item.actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = [
      _Action(
        l10n.actionAddStudent,
        Icons.person_add_alt_1_rounded,
        AppColors.primary,
        '/admin/students',
      ),
      _Action(
        l10n.actionOpenAttendance,
        Icons.fact_check_outlined,
        AppColors.success,
        '/admin/attendance',
      ),
      _Action(
        l10n.actionManageDevices,
        Icons.fingerprint_rounded,
        AppColors.info,
        '/admin/devices',
      ),
      _Action(
        l10n.actionManageGroups,
        Icons.groups_rounded,
        AppColors.accent,
        '/admin/groups',
      ),
      _Action(
        l10n.actionEnrollments,
        Icons.assignment_ind_outlined,
        const Color(0xFFC45C26),
        '/admin/enrollments',
      ),
      _Action(
        l10n.actionSchedules,
        Icons.calendar_month_outlined,
        const Color(0xFF2F6B8A),
        '/admin/schedules',
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
        final w = (c.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final a in actions)
              SizedBox(
                width: w,
                child: ScaleTap(
                  onTap: () => context.go(a.path),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: a.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(a.icon, color: a.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            a.label,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Action {
  const _Action(this.label, this.icon, this.color, this.path);
  final String label;
  final IconData icon;
  final Color color;
  final String path;
}

class _TodaySessionsCard extends StatelessWidget {
  const _TodaySessionsCard({
    required this.snap,
    required this.groupName,
  });

  final DashboardSnapshot snap;
  final Map<String, String> groupName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final slots = snap.todaySlots;

    return _Panel(
      title: l10n.todaySessions,
      trailing: TextButton(
        onPressed: () => context.go('/admin/schedules'),
        child: Text(l10n.actionSchedules),
      ),
      child: slots.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                l10n.noSessionsToday,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < slots.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        slots[i].startTime,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      groupName[slots[i].groupId] ?? slots[i].groupId,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${slots[i].startTime} – ${slots[i].endTime}',
                    ),
                    trailing: IconButton(
                      tooltip: l10n.attendance,
                      onPressed: () => context.go('/admin/attendance'),
                      icon: const Icon(Icons.fact_check_outlined),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _SystemTotalsCard extends StatelessWidget {
  const _SystemTotalsCard({required this.snap});

  final DashboardSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = [
      (l10n.students, snap.students.length, '/admin/students'),
      (l10n.teachers, snap.teachers.length, '/admin/teachers'),
      (l10n.groups, snap.groups.length, '/admin/groups'),
      (l10n.enrollments, snap.enrollments.length, '/admin/enrollments'),
      (l10n.classrooms, snap.classrooms.length, '/admin/classrooms'),
      (l10n.stages, snap.stages.length, '/admin/stages'),
      (l10n.devices, snap.devices.length, '/admin/devices'),
    ];

    return _Panel(
      title: l10n.systemTotals,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ScaleTap(
              onTap: () => context.go(rows[i].$3),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        rows[i].$1,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Text(
                      '${rows[i].$2}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
