import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fingerprint_app/app/theme/app_colors.dart';
import 'package:fingerprint_app/core/utils/teacher_photo.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/attendance_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/utils/session_attendance.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class TeacherDetailPage extends StatelessWidget {
  const TeacherDetailPage({super.key, required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return StreamBuilder<List<Teacher>>(
      stream: repo.watchTeachers(),
      builder: (context, snap) {
        final teacher = snap.data
            ?.cast<Teacher?>()
            .firstWhere((t) => t?.id == teacherId, orElse: () => null);
        if (teacher == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/admin/teachers'),
              ),
              title: Text(AppLocalizations.of(context).teacherDetails),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return _TeacherDetailBody(teacher: teacher);
      },
    );
  }
}

class _TeacherDetailBody extends StatelessWidget {
  const _TeacherDetailBody({required this.teacher});

  final Teacher teacher;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<AdminRepository>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/teachers'),
        ),
        title: Text(l10n.teacherDetails),
      ),
      body: StreamBuilder(
        stream: repo.watchGrades(),
        builder: (context, gradesSnap) {
          return StreamBuilder(
            stream: repo.watchSubjects(),
            builder: (context, subjectsSnap) {
              return StreamBuilder(
                stream: repo.watchGroups(),
                builder: (context, groupsSnap) {
                  return StreamBuilder(
                    stream: repo.watchSchedules(),
                    builder: (context, schedulesSnap) {
                      return StreamBuilder(
                        stream: repo.watchStudents(),
                        builder: (context, studentsSnap) {
                          return StreamBuilder(
                            stream: repo.watchAttendances(),
                            builder: (context, attSnap) {
                              final grades =
                                  gradesSnap.data ?? const <Grade>[];
                              final subjects =
                                  subjectsSnap.data ?? const <Subject>[];
                              final groups =
                                  groupsSnap.data ?? const <StudyGroup>[];
                              final schedules = schedulesSnap.data ??
                                  const <ScheduleSlot>[];
                              final students =
                                  studentsSnap.data ?? const <Student>[];
                              final records = attSnap.data ??
                                  const <AttendanceRecord>[];

                              final gradeName = {
                                for (final g in grades) g.id: g.name,
                              };
                              final subjectName = {
                                for (final s in subjects) s.id: s.name,
                              };

                              final teacherGroups = groups
                                  .where(
                                    (g) => _groupHasTeacher(g, teacher.id),
                                  )
                                  .toList()
                                ..sort((a, b) => a.name.compareTo(b.name));

                              final sessionRows = _buildTeacherSessionRows(
                                l10n: l10n,
                                teacherId: teacher.id,
                                groups: teacherGroups,
                                schedules: schedules,
                                students: students,
                                records: records,
                                subjectName: subjectName,
                              );

                              final presentN = sessionRows.fold<int>(
                                0,
                                (s, r) => s + r.present,
                              );
                              final lateN = sessionRows.fold<int>(
                                0,
                                (s, r) => s + r.late,
                              );
                              final absentN = sessionRows.fold<int>(
                                0,
                                (s, r) => s + r.absent,
                              );

                              return ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  28,
                                ),
                                children: [
                                  _TeacherHeroHeader(
                                    teacher: teacher,
                                    subjectsLabel: teacher.subjectIds.isEmpty
                                        ? '-'
                                        : teacher.subjectIds
                                            .map(
                                              (id) => subjectName[id] ?? id,
                                            )
                                            .join('، '),
                                    gradesLabel: teacher.gradeIds.isEmpty
                                        ? '-'
                                        : teacher.gradeIds
                                            .map((id) => gradeName[id] ?? id)
                                            .join('، '),
                                    salaryLabel: _salaryLabel(
                                      l10n,
                                      teacher.salaryMethod,
                                    ),
                                    accountLabel: teacher.userId == null
                                        ? l10n.accountNotLinked
                                        : l10n.accountLinked,
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _StatChip(
                                        label: l10n.presentCount(presentN),
                                        color: AppColors.success,
                                      ),
                                      _StatChip(
                                        label: l10n.lateCount(lateN),
                                        color: AppColors.warning,
                                      ),
                                      _StatChip(
                                        label: l10n.absentCount(absentN),
                                        color: AppColors.danger,
                                      ),
                                      _StatChip(
                                        label:
                                            '${l10n.taughtSessions}: ${sessionRows.length}',
                                        color: AppColors.primary,
                                      ),
                                      _StatChip(
                                        label:
                                            '${l10n.teacherGroups}: ${teacherGroups.length}',
                                        color: theme.colorScheme.tertiary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _SectionPanel(
                                    title: l10n.teacherGroups,
                                    child: teacherGroups.isEmpty
                                        ? Text(
                                            '-',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          )
                                        : Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              for (final g in teacherGroups)
                                                _GroupInfoChip(
                                                  name: g.name,
                                                  subtitle: subjectName[
                                                          g.subjectId] ??
                                                      g.subjectId,
                                                  ratio:
                                                      '${g.studentIds.length} ${l10n.groupStudents}',
                                                ),
                                            ],
                                          ),
                                  ),
                                  const SizedBox(height: 16),
                                  _SectionPanel(
                                    title: l10n.attendance,
                                    child: sessionRows.isEmpty
                                        ? Text(
                                            l10n.noData,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          )
                                        : _TeacherSessionsPanel(
                                            rows: sessionRows,
                                            groups: teacherGroups,
                                          ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

bool _groupHasTeacher(StudyGroup group, String teacherId) {
  if (group.teacherId == teacherId) return true;
  return group.sessions.any((s) => s.teacherId == teacherId);
}

bool _slotTaughtByTeacher({
  required StudyGroup group,
  required ScheduleSlot slot,
  required String teacherId,
}) {
  if (group.sessions.isNotEmpty) {
    for (final s in group.sessions) {
      if (s.teacherId != teacherId) continue;
      if (!s.weekdays.contains(slot.weekday)) continue;
      if (s.startTime != slot.startTime || s.endTime != slot.endTime) {
        continue;
      }
      return true;
    }
    return false;
  }
  return group.teacherId == teacherId;
}

class _TeacherSessionRow {
  const _TeacherSessionRow({
    required this.date,
    required this.groupId,
    required this.groupName,
    required this.sessionLabel,
    required this.present,
    required this.late,
    required this.absent,
    required this.total,
  });

  final String date;
  final String groupId;
  final String groupName;
  final String sessionLabel;
  final int present;
  final int late;
  final int absent;
  final int total;
}

List<_TeacherSessionRow> _buildTeacherSessionRows({
  required AppLocalizations l10n,
  required String teacherId,
  required List<StudyGroup> groups,
  required List<ScheduleSlot> schedules,
  required List<Student> students,
  required List<AttendanceRecord> records,
  required Map<String, String> subjectName,
}) {
  final rows = <_TeacherSessionRow>[];
  final targets = <SessionAttendanceTarget>[];

  for (final g in groups) {
    final all = groupSessionsAcrossDates(
      group: g,
      schedules: schedules,
      records: records,
    );
    for (final t in all) {
      if (_slotTaughtByTeacher(
        group: g,
        slot: t.slot,
        teacherId: teacherId,
      )) {
        targets.add(t);
      }
    }
  }

  targets.sort((a, b) {
    final d = b.date.compareTo(a.date);
    if (d != 0) return d;
    return a.group.name.compareTo(b.group.name);
  });

  for (final session in targets) {
    final subj = subjectNameForSlot(session.slot, session.group, subjectName);
    final roster = rosterForSession(
      session: session,
      schedules: schedules,
      students: students,
      records: records,
    );
    final present =
        roster.where((r) => r.state == SessionRowState.present).length;
    final late = roster.where((r) => r.state == SessionRowState.late).length;
    final absent = roster
        .where(
          (r) =>
              r.state == SessionRowState.absent ||
              r.state == SessionRowState.notCheckedIn,
        )
        .length;
    rows.add(
      _TeacherSessionRow(
        date: session.date,
        groupId: session.group.id,
        groupName: session.group.name,
        sessionLabel: session.sessionLabel(l10n, subjectName: subj),
        present: present,
        late: late,
        absent: absent,
        total: roster.length,
      ),
    );
  }

  return rows;
}

String _salaryLabel(AppLocalizations l10n, SalaryMethod method) {
  return switch (method) {
    SalaryMethod.perSession => l10n.salaryPerSession,
    SalaryMethod.perStudent => l10n.salaryPerStudent,
    SalaryMethod.monthlyFixed => l10n.salaryMonthly,
    SalaryMethod.hybrid => l10n.salaryHybrid,
  };
}

class _TeacherHeroHeader extends StatelessWidget {
  const _TeacherHeroHeader({
    required this.teacher,
    required this.subjectsLabel,
    required this.gradesLabel,
    required this.salaryLabel,
    required this.accountLabel,
  });

  final Teacher teacher;
  final String subjectsLabel;
  final String gradesLabel;
  final String salaryLabel;
  final String accountLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PersonAvatar(
              name: teacher.name,
              photoUrl: teacher.photoUrl,
              radius: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _InfoItem(
                        icon: Icons.phone_outlined,
                        label: l10n.phone,
                        value: teacher.phone?.trim().isNotEmpty == true
                            ? teacher.phone!
                            : '-',
                      ),
                      _InfoItem(
                        icon: Icons.menu_book_outlined,
                        label: l10n.specializedSubjects,
                        value: subjectsLabel,
                      ),
                      _InfoItem(
                        icon: Icons.school_outlined,
                        label: l10n.teachingGrades,
                        value: gradesLabel,
                      ),
                      _InfoItem(
                        icon: Icons.payments_outlined,
                        label: l10n.paymentMethod,
                        value: salaryLabel,
                      ),
                      _InfoItem(
                        icon: Icons.badge_outlined,
                        label: l10n.account,
                        value: accountLabel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 280),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _GroupInfoChip extends StatelessWidget {
  const _GroupInfoChip({
    required this.name,
    required this.subtitle,
    required this.ratio,
  });

  final String name;
  final String subtitle;
  final String ratio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ratio,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _TeacherSessionsPanel extends StatefulWidget {
  const _TeacherSessionsPanel({
    required this.rows,
    required this.groups,
  });

  final List<_TeacherSessionRow> rows;
  final List<StudyGroup> groups;

  @override
  State<_TeacherSessionsPanel> createState() => _TeacherSessionsPanelState();
}

class _TeacherSessionsPanelState extends State<_TeacherSessionsPanel> {
  static const _pageSizes = [10, 25, 50];

  String? _groupId;
  DateTime? _date;
  final _searchCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  var _search = '';
  var _page = 0;
  var _rowsPerPage = 10;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TeacherSessionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows.length != widget.rows.length) {
      final maxPage = _maxPageFor(_filtered.length);
      if (_page > maxPage) _page = maxPage;
    }
  }

  List<_TeacherSessionRow> get _filtered {
    final q = _search.trim().toLowerCase();
    final dateKey = _date == null ? null : sessionDateKey(_date!);
    return widget.rows.where((r) {
      if (_groupId != null && r.groupId != _groupId) return false;
      if (dateKey != null && r.date != dateKey) return false;
      if (q.isNotEmpty) {
        final hay = '${r.sessionLabel} ${r.groupName} ${r.date}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  int _maxPageFor(int total) {
    if (total <= 0) return 0;
    return ((total - 1) / _rowsPerPage).floor();
  }

  void _resetPage() => _page = 0;

  void _syncDateField(AppLocalizations l10n) {
    final next = _date == null ? l10n.allDates : sessionDateKey(_date!);
    if (_dateCtrl.text != next) _dateCtrl.text = next;
  }

  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _syncDateField(l10n);
      _resetPage();
    });
  }

  void _clearFilters() {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _groupId = null;
      _date = null;
      _syncDateField(l10n);
      _searchCtrl.clear();
      _search = '';
      _resetPage();
    });
  }

  bool get _hasActiveFilters =>
      _groupId != null || _date != null || _search.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    _syncDateField(l10n);

    final filtered = _filtered;
    final maxPage = _maxPageFor(filtered.length);
    final page = _page.clamp(0, maxPage);
    final start = filtered.isEmpty ? 0 : page * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    final pageRows = filtered.isEmpty
        ? const <_TeacherSessionRow>[]
        : filtered.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 48,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.search,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () => setState(() {
                            _searchCtrl.clear();
                            _search = '';
                            _resetPage();
                          }),
                          icon: const Icon(Icons.clear_rounded, size: 18),
                        ),
                ),
                onChanged: (v) => setState(() {
                  _search = v;
                  _resetPage();
                }),
              ),
            ),
            SizedBox(
              width: 200,
              height: 48,
              child: DropdownButtonFormField<String?>(
                value: _groupId,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.group,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.allGroups),
                  ),
                  for (final g in widget.groups)
                    DropdownMenuItem<String?>(
                      value: g.id,
                      child: Text(g.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _groupId = v;
                  _resetPage();
                }),
              ),
            ),
            SizedBox(
              width: 180,
              height: 48,
              child: TextField(
                readOnly: true,
                onTap: _pickDate,
                controller: _dateCtrl,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.date,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: _date == null
                      ? IconButton(
                          onPressed: _pickDate,
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                          ),
                        )
                      : IconButton(
                          tooltip: l10n.clearSelection,
                          onPressed: () => setState(() {
                            _date = null;
                            _syncDateField(l10n);
                            _resetPage();
                          }),
                          icon: const Icon(Icons.clear_rounded, size: 18),
                        ),
                ),
              ),
            ),
            if (_hasActiveFilters)
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: Text(l10n.clearSelection),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          l10n.paginationSummary(
            filtered.isEmpty ? 0 : start + 1,
            end,
            filtered.length,
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (pageRows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.noSearchResults,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowHeight: 44,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 56,
                    columnSpacing: 24,
                    headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    columns: [
                      DataColumn(label: Text(l10n.sessionNumber)),
                      DataColumn(label: Text(l10n.date)),
                      DataColumn(label: Text(l10n.sessionTime)),
                      DataColumn(label: Text(l10n.group)),
                      DataColumn(label: Text(l10n.statusPresent)),
                      DataColumn(label: Text(l10n.statusLate)),
                      DataColumn(label: Text(l10n.statusAbsent)),
                      DataColumn(label: Text(l10n.groupStudents)),
                    ],
                    rows: [
                      for (var i = 0; i < pageRows.length; i++)
                        DataRow(
                          cells: [
                            DataCell(Text('${start + i + 1}')),
                            DataCell(Text(pageRows[i].date)),
                            DataCell(Text(pageRows[i].sessionLabel)),
                            DataCell(Text(pageRows[i].groupName)),
                            DataCell(Text('${pageRows[i].present}')),
                            DataCell(Text('${pageRows[i].late}')),
                            DataCell(Text('${pageRows[i].absent}')),
                            DataCell(Text('${pageRows[i].total}')),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text(l10n.rowsPerPage, style: theme.textTheme.bodySmall),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _rowsPerPage,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final n in _pageSizes)
                      DropdownMenuItem(value: n, child: Text('$n')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _rowsPerPage = v;
                      _resetPage();
                    });
                  },
                ),
                const Spacer(),
                Text(
                  l10n.pageOf(page + 1, maxPage + 1),
                  style: theme.textTheme.bodySmall,
                ),
                IconButton(
                  onPressed: page <= 0
                      ? null
                      : () => setState(() => _page = page - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: page >= maxPage
                      ? null
                      : () => setState(() => _page = page + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
