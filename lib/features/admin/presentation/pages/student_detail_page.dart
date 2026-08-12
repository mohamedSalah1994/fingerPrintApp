import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fingerprint_app/app/theme/app_colors.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/attendance_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/utils/session_attendance.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class StudentDetailPage extends StatelessWidget {
  const StudentDetailPage({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return StreamBuilder<List<Student>>(
      stream: repo.watchStudents(),
      builder: (context, studentsSnap) {
        final student = studentsSnap.data
            ?.cast<Student?>()
            .firstWhere((s) => s?.id == studentId, orElse: () => null);
        if (student == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/admin/students'),
              ),
              title: Text(AppLocalizations.of(context).studentDetails),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return _StudentDetailBody(student: student);
      },
    );
  }
}

class _StudentDetailBody extends StatelessWidget {
  const _StudentDetailBody({required this.student});

  final Student student;

  Future<void> _addEvaluation(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<AdminRepository>();
    final scoreCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final subjects = await repo.watchSubjects().first;
    if (!context.mounted) return;
    final gradeSubjects = subjects
        .where(
          (s) =>
              student.gradeId == null ||
              s.gradeId == null ||
              s.gradeId == student.gradeId,
        )
        .toList();
    String? subjectId = gradeSubjects.isEmpty ? null : gradeSubjects.first.id;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title: Text(l10n.addEvaluation),
              content: Form(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (gradeSubjects.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: subjectId,
                        decoration: InputDecoration(labelText: l10n.subjects),
                        items: gradeSubjects
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => subjectId = v),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: scoreCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.score),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: noteCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: l10n.adminNote),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    await repo.saveEvaluation(
                      StudentEvaluation(
                        id: '',
                        studentId: student.id,
                        branchId: student.branchId,
                        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        subjectId: subjectId,
                        score: double.tryParse(scoreCtrl.text.trim()),
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                      ),
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<AdminRepository>();
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/students'),
        ),
        title: Text(l10n.studentDetails),
      ),
      body: StreamBuilder(
        stream: repo.watchGrades(),
        builder: (context, gradesSnap) {
          return StreamBuilder(
            stream: repo.watchSubjects(),
            builder: (context, subjectsSnap) {
              return StreamBuilder(
                stream: repo.watchParents(),
                builder: (context, parentsSnap) {
                  return StreamBuilder(
                    stream: repo.watchGroups(),
                    builder: (context, groupsSnap) {
                      return StreamBuilder(
                        stream: repo.watchSchedules(),
                        builder: (context, schedulesSnap) {
                          return StreamBuilder(
                            stream: repo.watchAttendances(),
                            builder: (context, attSnap) {
                              return StreamBuilder(
                                stream: repo.watchEvaluations(),
                                builder: (context, evalSnap) {
                                  final grades =
                                      gradesSnap.data ?? const <Grade>[];
                                  final subjects =
                                      subjectsSnap.data ?? const <Subject>[];
                                  final parents = parentsSnap.data ??
                                      const <ParentProfile>[];
                                  final groups =
                                      groupsSnap.data ?? const <StudyGroup>[];
                                  final schedules = schedulesSnap.data ??
                                      const <ScheduleSlot>[];
                                  final allAttendances = attSnap.data ??
                                      const <AttendanceRecord>[];
                                  final attendances = allAttendances
                                      .where((a) => a.studentId == student.id)
                                      .toList()
                                    ..sort((a, b) => b.date.compareTo(a.date));
                                  final evaluations = (evalSnap.data ??
                                          const <StudentEvaluation>[])
                                      .where((e) => e.studentId == student.id)
                                      .toList()
                                    ..sort((a, b) => b.date.compareTo(a.date));

                                  final gradeName = {
                                    for (final g in grades) g.id: g.name,
                                  };
                                  final subjectName = {
                                    for (final s in subjects) s.id: s.name,
                                  };
                                  final parentById = {
                                    for (final p in parents) p.id: p,
                                  };
                                  final studentGroups = groups
                                      .where(
                                        (g) =>
                                            g.studentIds.contains(student.id),
                                      )
                                      .toList()
                                    ..sort((a, b) => a.name.compareTo(b.name));

                                  final sessionRows = _buildSessionRows(
                                    l10n: l10n,
                                    student: student,
                                    groups: studentGroups,
                                    schedules: schedules,
                                    records: allAttendances,
                                    subjectName: subjectName,
                                  );

                                  final presentN = sessionRows
                                      .where(
                                        (r) =>
                                            r.state == SessionRowState.present,
                                      )
                                      .length;
                                  final lateN = sessionRows
                                      .where(
                                        (r) => r.state == SessionRowState.late,
                                      )
                                      .length;
                                  final absentN = sessionRows
                                      .where(
                                        (r) =>
                                            r.state == SessionRowState.absent ||
                                            r.state ==
                                                SessionRowState.notCheckedIn,
                                      )
                                      .length;

                                  final parentNames = student.parentIds
                                      .map((id) => parentById[id]?.name ?? id)
                                      .where((n) => n.trim().isNotEmpty)
                                      .join('، ');
                                  final parentPhones = student.parentIds
                                      .map((id) => parentById[id]?.phone)
                                      .whereType<String>()
                                      .where((p) => p.trim().isNotEmpty)
                                      .join('، ');

                                  return ListView(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      12,
                                      20,
                                      28,
                                    ),
                                    children: [
                                      _StudentHeroHeader(
                                        student: student,
                                        gradeLabel: student.gradeId == null
                                            ? '-'
                                            : (gradeName[student.gradeId] ??
                                                student.gradeId!),
                                        parentNames: parentNames.isEmpty
                                            ? l10n.noParent
                                            : parentNames,
                                        parentPhones: parentPhones,
                                        subjectsLabel: student.enrollmentType ==
                                                EnrollmentType.full
                                            ? l10n.allSubjectsOption
                                            : (student.subjectIds.isEmpty
                                                ? '-'
                                                : student.subjectIds
                                                    .map(
                                                      (id) =>
                                                          subjectName[id] ?? id,
                                                    )
                                                    .join('، ')),
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
                                                '${l10n.attendedSessions}: ${presentN + lateN}',
                                            color: AppColors.primary,
                                          ),
                                          _StatChip(
                                            label:
                                                '${l10n.studentGroups}: ${studentGroups.length}',
                                            color: theme.colorScheme.tertiary,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      _SectionPanel(
                                        title: l10n.studentGroups,
                                        child: studentGroups.isEmpty
                                            ? Text(
                                                '-',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              )
                                            : Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  for (final g
                                                      in studentGroups)
                                                    _GroupInfoChip(
                                                      name: g.name,
                                                      subtitle: subjectName[
                                                              g.subjectId] ??
                                                          g.subjectId,
                                                      ratio:
                                                          _groupAttendanceRatio(
                                                        group: g,
                                                        attendances:
                                                            attendances,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                      ),
                                      const SizedBox(height: 16),
                                      _SectionPanel(
                                        title: l10n.attendance,
                                        child: sessionRows.isEmpty
                                            ? Text(
                                                l10n.noHistoryForStudent,
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              )
                                            : _StudentAttendancePanel(
                                                rows: sessionRows,
                                                groups: studentGroups,
                                                timeFormat: timeFormat,
                                              ),
                                      ),
                                      const SizedBox(height: 16),
                                      _SectionPanel(
                                        title: l10n.evaluations,
                                        trailing: TextButton.icon(
                                          onPressed: () =>
                                              _addEvaluation(context),
                                          icon: const Icon(Icons.add, size: 18),
                                          label: Text(l10n.addEvaluation),
                                        ),
                                        child: evaluations.isEmpty
                                            ? Text(
                                                '-',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              )
                                            : Column(
                                                children: [
                                                  for (final e in evaluations)
                                                    _EvaluationTile(
                                                      date: e.date,
                                                      score: e.score,
                                                      note: e.note,
                                                      subject: e.subjectId ==
                                                              null
                                                          ? null
                                                          : (subjectName[e
                                                                  .subjectId] ??
                                                              e.subjectId),
                                                      scoreLabel: l10n.score,
                                                    ),
                                                ],
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
          );
        },
      ),
    );
  }

  String _groupAttendanceRatio({
    required StudyGroup group,
    required List<AttendanceRecord> attendances,
  }) {
    final planned = group.plannedSessionCount;
    if (planned <= 0) return '0 / 0';
    final plannedDates = {
      for (final d in group.plannedSessionDates) sessionDateKey(d),
    };
    final attended = attendances
        .where(
          (a) =>
              a.groupId == group.id &&
              plannedDates.contains(a.date) &&
              (a.status == AttendanceStatus.present ||
                  a.status == AttendanceStatus.late),
        )
        .length;
    return '$attended / $planned';
  }
}

class _SessionAttendanceRow {
  const _SessionAttendanceRow({
    required this.date,
    required this.groupId,
    required this.groupName,
    required this.sessionLabel,
    required this.state,
    this.checkInAt,
    this.carried = false,
  });

  final String date;
  final String groupId;
  final String groupName;
  final String sessionLabel;
  final SessionRowState state;
  final DateTime? checkInAt;
  final bool carried;
}

List<_SessionAttendanceRow> _buildSessionRows({
  required AppLocalizations l10n,
  required Student student,
  required List<StudyGroup> groups,
  required List<ScheduleSlot> schedules,
  required List<AttendanceRecord> records,
  required Map<String, String> subjectName,
}) {
  final rows = <_SessionAttendanceRow>[];
  final targets = <SessionAttendanceTarget>[];

  for (final g in groups) {
    targets.addAll(
      groupSessionsAcrossDates(
        group: g,
        schedules: schedules,
        records: records,
      ),
    );
  }

  targets.sort((a, b) {
    final d = b.date.compareTo(a.date);
    if (d != 0) return d;
    return a.group.name.compareTo(b.group.name);
  });

  for (final session in targets) {
    final roster = rosterForSession(
      session: session,
      schedules: schedules,
      students: [student],
      records: records,
    );
    if (roster.isEmpty) continue;
    final row = roster.first;
    final subj = subjectNameForSlot(session.slot, session.group, subjectName);
    rows.add(
      _SessionAttendanceRow(
        date: session.date,
        groupId: session.group.id,
        groupName: session.group.name,
        sessionLabel: session.sessionLabel(l10n, subjectName: subj),
        state: row.state,
        checkInAt: row.checkInAt,
        carried: row.carriedFromPrevious,
      ),
    );
  }

  return rows;
}

class _StudentHeroHeader extends StatelessWidget {
  const _StudentHeroHeader({
    required this.student,
    required this.gradeLabel,
    required this.parentNames,
    required this.parentPhones,
    required this.subjectsLabel,
  });

  final Student student;
  final String gradeLabel;
  final String parentNames;
  final String parentPhones;
  final String subjectsLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final trimmed = student.name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);

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
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withValues(alpha: 0.18),
              child: Text(
                initial,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
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
                        icon: Icons.school_outlined,
                        label: l10n.grade,
                        value: gradeLabel,
                      ),
                      _InfoItem(
                        icon: Icons.phone_outlined,
                        label: l10n.phone,
                        value: student.phone?.trim().isNotEmpty == true
                            ? student.phone!
                            : '-',
                      ),
                      _InfoItem(
                        icon: Icons.family_restroom_outlined,
                        label: l10n.parentGuardian,
                        value: parentNames,
                      ),
                      if (parentPhones.isNotEmpty)
                        _InfoItem(
                          icon: Icons.call_outlined,
                          label: l10n.parentPhone,
                          value: parentPhones,
                        ),
                      _InfoItem(
                        icon: Icons.menu_book_outlined,
                        label: l10n.subjects,
                        value: subjectsLabel,
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
    this.trailing,
  });

  final String title;
  final Widget? trailing;
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
      ),
    );
  }
}

class _StudentAttendancePanel extends StatefulWidget {
  const _StudentAttendancePanel({
    required this.rows,
    required this.groups,
    required this.timeFormat,
  });

  final List<_SessionAttendanceRow> rows;
  final List<StudyGroup> groups;
  final DateFormat timeFormat;

  @override
  State<_StudentAttendancePanel> createState() =>
      _StudentAttendancePanelState();
}

class _StudentAttendancePanelState extends State<_StudentAttendancePanel> {
  static const _pageSizes = [10, 25, 50];

  String? _groupId;
  SessionRowState? _status;
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
  void didUpdateWidget(covariant _StudentAttendancePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows.length != widget.rows.length) {
      final maxPage = _maxPageFor(_filtered.length);
      if (_page > maxPage) _page = maxPage;
    }
  }

  List<_SessionAttendanceRow> get _filtered {
    final q = _search.trim().toLowerCase();
    final dateKey = _date == null ? null : sessionDateKey(_date!);
    return widget.rows.where((r) {
      if (_groupId != null && r.groupId != _groupId) return false;
      if (_status != null && !_statusMatches(r.state, _status!)) return false;
      if (dateKey != null && r.date != dateKey) return false;
      if (q.isNotEmpty) {
        final hay = '${r.sessionLabel} ${r.groupName} ${r.date}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  bool _statusMatches(SessionRowState actual, SessionRowState filter) {
    if (filter == SessionRowState.absent) {
      return actual == SessionRowState.absent ||
          actual == SessionRowState.notCheckedIn;
    }
    return actual == filter;
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
      _status = null;
      _date = null;
      _syncDateField(l10n);
      _searchCtrl.clear();
      _search = '';
      _resetPage();
    });
  }

  String _statusLabel(AppLocalizations l10n, SessionRowState state) {
    return switch (state) {
      SessionRowState.present => l10n.statusPresent,
      SessionRowState.late => l10n.statusLate,
      SessionRowState.absent => l10n.statusAbsent,
      SessionRowState.excused => l10n.statusExcused,
      SessionRowState.notCheckedIn => l10n.notCheckedInYet,
      SessionRowState.pending => l10n.sessionNotStartedYet,
    };
  }

  bool get _hasActiveFilters =>
      _groupId != null ||
      _status != null ||
      _date != null ||
      _search.trim().isNotEmpty;

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
    final pageRows =
        filtered.isEmpty ? const <_SessionAttendanceRow>[] : filtered.sublist(start, end);

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
              child: DropdownButtonFormField<SessionRowState?>(
                value: _status,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.status,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  DropdownMenuItem<SessionRowState?>(
                    value: null,
                    child: Text(l10n.allOrUnspecified),
                  ),
                  for (final s in const [
                    SessionRowState.present,
                    SessionRowState.late,
                    SessionRowState.absent,
                    SessionRowState.excused,
                    SessionRowState.notCheckedIn,
                  ])
                    DropdownMenuItem<SessionRowState?>(
                      value: s,
                      child: Text(_statusLabel(l10n, s)),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _status = v;
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
                      DataColumn(label: Text(l10n.status)),
                      DataColumn(label: Text(l10n.checkIn)),
                    ],
                    rows: [
                      for (var i = 0; i < pageRows.length; i++)
                        DataRow(
                          cells: [
                            DataCell(Text('${start + i + 1}')),
                            DataCell(Text(pageRows[i].date)),
                            DataCell(Text(pageRows[i].sessionLabel)),
                            DataCell(Text(pageRows[i].groupName)),
                            DataCell(
                              SessionStateChip(
                                state: pageRows[i].state,
                                carried: pageRows[i].carried,
                              ),
                            ),
                            DataCell(
                              Text(
                                pageRows[i].checkInAt == null
                                    ? '-'
                                    : widget.timeFormat.format(
                                        pageRows[i].checkInAt!.toLocal(),
                                      ),
                              ),
                            ),
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

class _EvaluationTile extends StatelessWidget {
  const _EvaluationTile({
    required this.date,
    required this.scoreLabel,
    this.score,
    this.note,
    this.subject,
  });

  final String date;
  final String scoreLabel;
  final double? score;
  final String? note;
  final String? subject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.rate_review_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score == null ? (note ?? '-') : '$scoreLabel: $score',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  [
                    date,
                    if (subject != null) subject!,
                    if (note != null && score != null) note!,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
