import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fingerprint_app/app/theme/app_colors.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/attendance_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/crud_list_cubit.dart';
import 'package:fingerprint_app/features/admin/presentation/utils/session_attendance.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/responsive_data_table.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/searchable_select.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

Map<int, String> _weekdayLabels(AppLocalizations l10n) => {
      1: l10n.monday,
      2: l10n.tuesday,
      3: l10n.wednesday,
      4: l10n.thursday,
      5: l10n.friday,
      6: l10n.saturday,
      7: l10n.sunday,
    };

enum _GroupPeriodScope { daily, weekly, monthly }

class _SessionDraft {
  _SessionDraft({
    required this.weekdays,
    required this.subjectId,
    required this.startTime,
    required this.endTime,
    this.teacherId,
  });

  Set<int> weekdays;
  String subjectId;
  String startTime;
  String endTime;
  String? teacherId;

  factory _SessionDraft.fromGroupSession(
    GroupSession s, {
    String? fallbackSubjectId,
  }) =>
      _SessionDraft(
        weekdays: {...s.weekdays},
        subjectId: s.subjectId.isNotEmpty
            ? s.subjectId
            : (fallbackSubjectId ?? ''),
        startTime: s.startTime,
        endTime: s.endTime,
        teacherId: s.teacherId,
      );

  GroupSession toGroupSession() => GroupSession(
        weekdays: weekdays.toList()..sort(),
        subjectId: subjectId,
        startTime: startTime,
        endTime: endTime,
        teacherId: teacherId,
      );
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _addMonths(DateTime date, int months) {
  var y = date.year;
  var m = date.month + months;
  while (m > 12) {
    m -= 12;
    y++;
  }
  while (m < 1) {
    m += 12;
    y--;
  }
  final lastDay = DateTime(y, m + 1, 0).day;
  final day = date.day > lastDay ? lastDay : date.day;
  return DateTime(y, m, day);
}

({DateTime start, DateTime end}) _periodRangeForScope(
  _GroupPeriodScope scope,
  DateTime anchor,
) {
  final today = _dateOnly(anchor);
  return switch (scope) {
    _GroupPeriodScope.daily => (start: today, end: today),
    _GroupPeriodScope.weekly => (
        start: today,
        end: today.add(const Duration(days: 7)),
      ),
    _GroupPeriodScope.monthly => (
        start: today,
        end: _addMonths(today, 1),
      ),
  };
}

_GroupPeriodScope _inferPeriodScope(DateTime start, DateTime end) {
  final s = _dateOnly(start);
  final e = _dateOnly(end);
  if (s == e) return _GroupPeriodScope.daily;
  if (e.difference(s).inDays == 7) return _GroupPeriodScope.weekly;
  return _GroupPeriodScope.monthly;
}

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CrudListCubit<StudyGroup>(
            watch: repo.watchGroups,
            save: repo.saveGroup,
            remove: repo.deleteGroup,
            idOf: (e) => e.id,
          ),
        ),
        BlocProvider(
          create: (_) => CrudListCubit<Grade>(
            watch: repo.watchGrades,
            save: repo.saveGrade,
            remove: repo.deleteGrade,
            idOf: (e) => e.id,
          ),
        ),
        BlocProvider(
          create: (_) => CrudListCubit<Subject>(
            watch: repo.watchSubjects,
            save: repo.saveSubject,
            remove: repo.deleteSubject,
            idOf: (e) => e.id,
          ),
        ),
        BlocProvider(
          create: (_) => CrudListCubit<Teacher>(
            watch: repo.watchTeachers,
            save: repo.saveTeacher,
            remove: repo.deleteTeacher,
            idOf: (e) => e.id,
          ),
        ),
        BlocProvider(
          create: (_) => CrudListCubit<Classroom>(
            watch: repo.watchClassrooms,
            save: repo.saveClassroom,
            remove: repo.deleteClassroom,
            idOf: (e) => e.id,
          ),
        ),
        BlocProvider(
          create: (_) => CrudListCubit<Student>(
            watch: repo.watchStudents,
            save: repo.saveStudent,
            remove: repo.deleteStudent,
            idOf: (e) => e.id,
          ),
        ),
        BlocProvider(
          create: (_) => CrudListCubit<AttendanceRecord>(
            watch: repo.watchAttendances,
            save: repo.saveAttendance,
            remove: repo.deleteAttendance,
            idOf: (e) => e.id,
          ),
        ),
        BlocProvider(
          create: (_) => CrudListCubit<ScheduleSlot>(
            watch: repo.watchSchedules,
            save: repo.saveSchedule,
            remove: repo.deleteSchedule,
            idOf: (e) => e.id,
          ),
        ),
      ],
      child: const _GroupsView(),
    );
  }
}

class _GroupsView extends StatefulWidget {
  const _GroupsView();

  @override
  State<_GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<_GroupsView> {
  StudyGroup? _detailGroup;

  Future<void> _pickTime(
    BuildContext context, {
    required String initial,
    required ValueChanged<String> onPicked,
  }) async {
    final parts = initial.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 16,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null) return;
    onPicked(
      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    StudyGroup? existing,
    required List<Grade> grades,
    required List<Subject> subjects,
    required List<Teacher> teachers,
    required List<Classroom> classrooms,
    required List<Student> students,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (grades.isEmpty || subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addGradesSubjectsFirst)),
      );
      return;
    }
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    var gradeId = existing?.gradeId ?? grades.first.id;
    String? classroomId = existing?.classroomId;
    final now = DateTime.now();
    final today = _dateOnly(now);
    var periodScope = existing == null
        ? _GroupPeriodScope.monthly
        : _inferPeriodScope(
            DateTime.tryParse(existing.startDate ?? '') ?? today,
            DateTime.tryParse(existing.endDate ?? '') ?? today,
          );
    final initialRange = existing != null &&
            existing.startDate != null &&
            existing.endDate != null
        ? (
            start: DateTime.tryParse(existing.startDate!) ?? today,
            end: DateTime.tryParse(existing.endDate!) ?? today,
          )
        : _periodRangeForScope(periodScope, now);
    var startDate = _dateOnly(initialRange.start);
    var endDate = _dateOnly(initialRange.end);

    final existingSessions = existing?.sessions ?? const <GroupSession>[];
    final sessionDrafts = existingSessions.isNotEmpty
        ? existingSessions
            .map(
              (s) => _SessionDraft.fromGroupSession(
                s,
                fallbackSubjectId: existing?.subjectId,
              ),
            )
            .toList()
        : [
            _SessionDraft(
              weekdays: {6},
              subjectId: '',
              startTime: '16:00',
              endTime: '18:00',
            ),
          ];

    final selectedStudents = {...?existing?.studentIds};
    final formKey = GlobalKey<FormState>();
    final weekdays = _weekdayLabels(l10n);
    final dateFmt = DateFormat('yyyy-MM-dd');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            final selectedGrade = grades.cast<Grade?>().firstWhere(
                  (g) => g?.id == gradeId,
                  orElse: () => grades.isEmpty ? null : grades.first,
                );
            List<Subject> subjectsForGrade(String gId, Grade? grade) {
              if (grade == null) {
                return subjects
                    .where((s) => s.gradeId == gId)
                    .toList()
                  ..sort((a, b) => a.name.compareTo(b.name));
              }
              final stageId = grade.stageId;
              final gradeIdsInStage = {
                for (final g in grades)
                  if (g.stageId == stageId) g.id,
              };

              final matching = subjects.where((s) {
                // Exact grade
                if (s.gradeId != null &&
                    s.gradeId!.isNotEmpty &&
                    s.gradeId == gId) {
                  return true;
                }
                // Subject linked to the stage (curriculum for all grades)
                if (s.stageId != null &&
                    s.stageId!.isNotEmpty &&
                    s.stageId == stageId) {
                  return true;
                }
                // Subject linked to any other grade in the same stage
                if (s.gradeId != null &&
                    s.gradeId!.isNotEmpty &&
                    gradeIdsInStage.contains(s.gradeId)) {
                  return true;
                }
                return false;
              }).toList();

              // Same name may exist once per grade (stage-scoped create) —
              // keep one entry, prefer the exact selected grade.
              final byName = <String, Subject>{};
              for (final s in matching) {
                final key = s.name.trim().toLowerCase();
                final prev = byName[key];
                if (prev == null) {
                  byName[key] = s;
                  continue;
                }
                final prevExact = prev.gradeId == gId;
                final sExact = s.gradeId == gId;
                if (sExact && !prevExact) byName[key] = s;
              }
              return byName.values.toList()
                ..sort((a, b) => a.name.compareTo(b.name));
            }

            final subjectsForSelect =
                subjectsForGrade(gradeId, selectedGrade);
            if (sessionDrafts.any((d) => d.subjectId.isEmpty) &&
                subjectsForSelect.isNotEmpty) {
              final defaultSubjectId = subjectsForSelect.first.id;
              for (final d in sessionDrafts) {
                if (d.subjectId.isEmpty) d.subjectId = defaultSubjectId;
              }
            }

            List<Teacher> teachersForSession(_SessionDraft draft) => teachers
                .where(
                  (t) =>
                      t.subjectIds.contains(draft.subjectId) &&
                      t.gradeIds.contains(gradeId),
                )
                .toList();

            final gradeStudents = students
                .where((s) => s.gradeId == null || s.gradeId == gradeId)
                .toList();
            final sessions = [
              for (final d in sessionDrafts) d.toGroupSession(),
            ];
            final primarySubjectId = sessions.isNotEmpty &&
                    sessions.first.subjectId.isNotEmpty
                ? sessions.first.subjectId
                : (existing?.subjectId ??
                    (subjectsForSelect.isNotEmpty
                        ? subjectsForSelect.first.id
                        : ''));
            final draftGroup = StudyGroup(
              id: existing?.id ?? '',
              name: nameCtrl.text,
              branchId: existing?.branchId ?? AppDefaults.branchId,
              gradeId: gradeId,
              subjectId: primarySubjectId,
              sessions: sessions,
              startDate: dateFmt.format(startDate),
              endDate: dateFmt.format(endDate),
            );
            final planned = draftGroup.plannedSessionCount;

            return AlertDialog(
              title: Text(existing == null ? l10n.addGroup : l10n.editGroup),
              content: SizedBox(
                width: 560,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          decoration:
                              InputDecoration(labelText: l10n.groupName),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.required
                              : null,
                        ),
                        const SizedBox(height: 12),
                        SearchableSelectField<Grade>(
                          label: l10n.grade,
                          value: selectedGrade ??
                              (grades.isEmpty ? null : grades.first),
                          labelOf: (g) => g.name,
                          onSearch: (q) => searchableLocalFilter(
                            items: grades,
                            query: q,
                            labelOf: (g) => g.name,
                          ),
                          onChanged: (g) => setState(() {
                            gradeId = g?.id ?? gradeId;
                            final nextGrade = grades.cast<Grade?>().firstWhere(
                                  (x) => x?.id == gradeId,
                                  orElse: () => null,
                                );
                            final nextSubjects =
                                subjectsForGrade(gradeId, nextGrade);
                            for (final d in sessionDrafts) {
                              if (!nextSubjects.any((s) => s.id == d.subjectId) &&
                                  nextSubjects.isNotEmpty) {
                                d.subjectId = nextSubjects.first.id;
                              }
                              d.teacherId = null;
                            }
                          }),
                        ),
                        const SizedBox(height: 12),
                        SearchableSelectField<Classroom>(
                          label: l10n.classrooms,
                          value: classrooms.cast<Classroom?>().firstWhere(
                                (c) => c?.id == classroomId,
                                orElse: () => null,
                              ),
                          labelOf: (c) => '${c.name} (${c.capacity})',
                          onSearch: (q) => searchableLocalFilter(
                            items: classrooms,
                            query: q,
                            labelOf: (c) => '${c.name} (${c.capacity})',
                          ),
                          onChanged: (c) =>
                              setState(() => classroomId = c?.id),
                          allowClear: true,
                          clearLabel: l10n.unspecified,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.sessions,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.selectWeekdaysHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < sessionDrafts.length; i++) ...[
                          Builder(
                            builder: (context) {
                              final draft = sessionDrafts[i];
                              final sessionTeachers =
                                  teachersForSession(draft);
                              return DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${l10n.sessions} ${i + 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: l10n.delete,
                                        onPressed: sessionDrafts.length > 1
                                            ? () => setState(
                                                  () => sessionDrafts
                                                      .removeAt(i),
                                                )
                                            : null,
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SearchableSelectField<Subject>(
                                    label: l10n.subjects,
                                    value: subjectsForSelect
                                        .cast<Subject?>()
                                        .firstWhere(
                                          (s) => s?.id == draft.subjectId,
                                          orElse: () =>
                                              subjectsForSelect.isEmpty
                                                  ? null
                                                  : subjectsForSelect.first,
                                        ),
                                    labelOf: (s) => s.name,
                                    onSearch: (q) => searchableLocalFilter(
                                      items: subjectsForSelect,
                                      query: q,
                                      labelOf: (s) => s.name,
                                    ),
                                    onChanged: (s) => setState(() {
                                      if (s == null) return;
                                      draft.subjectId = s.id;
                                      draft.teacherId = null;
                                    }),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.selectWeekdays,
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: weekdays.entries.map((e) {
                                      final selected =
                                          draft.weekdays.contains(e.key);
                                      return FilterChip(
                                        label: Text(e.value),
                                        selected: selected,
                                        onSelected: (v) => setState(() {
                                          if (v) {
                                            draft.weekdays.add(e.key);
                                          } else {
                                            draft.weekdays.remove(e.key);
                                          }
                                        }),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _pickTime(
                                            dialogContext,
                                            initial: draft.startTime,
                                            onPicked: (v) => setState(
                                              () => draft.startTime = v,
                                            ),
                                          ),
                                          child: Text(
                                            '${l10n.fromTime}: ${draft.startTime}',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _pickTime(
                                            dialogContext,
                                            initial: draft.endTime,
                                            onPicked: (v) => setState(
                                              () => draft.endTime = v,
                                            ),
                                          ),
                                          child: Text(
                                            '${l10n.toTime}: ${draft.endTime}',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SearchableSelectField<Teacher>(
                                    label: l10n.sessionTeacher,
                                    value: sessionTeachers
                                        .cast<Teacher?>()
                                        .firstWhere(
                                          (t) => t?.id == draft.teacherId,
                                          orElse: () => null,
                                        ),
                                    labelOf: (t) => t.name,
                                    onSearch: (q) => searchableLocalFilter(
                                      items: sessionTeachers,
                                      query: q,
                                      labelOf: (t) => t.name,
                                    ),
                                    onChanged: (t) => setState(
                                      () => draft.teacherId = t?.id,
                                    ),
                                    allowClear: true,
                                    clearLabel: l10n.unspecified,
                                  ),
                                ],
                              ),
                            ),
                          );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                        OutlinedButton.icon(
                          onPressed: () => setState(
                            () => sessionDrafts.add(
                              _SessionDraft(
                                weekdays: {6},
                                subjectId: subjectsForSelect.isNotEmpty
                                    ? subjectsForSelect.first.id
                                    : '',
                                startTime: '16:00',
                                endTime: '18:00',
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addSession),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.groupPeriod,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<_GroupPeriodScope>(
                          segments: [
                            ButtonSegment(
                              value: _GroupPeriodScope.daily,
                              label: Text(l10n.periodDaily),
                              icon: const Icon(Icons.today_outlined, size: 18),
                            ),
                            ButtonSegment(
                              value: _GroupPeriodScope.weekly,
                              label: Text(l10n.periodWeekly),
                              icon: const Icon(Icons.date_range_outlined, size: 18),
                            ),
                            ButtonSegment(
                              value: _GroupPeriodScope.monthly,
                              label: Text(l10n.periodMonthly),
                              icon: const Icon(Icons.calendar_month_outlined, size: 18),
                            ),
                          ],
                          selected: {periodScope},
                          onSelectionChanged: (selected) {
                            final scope = selected.first;
                            final range =
                                _periodRangeForScope(scope, DateTime.now());
                            setState(() {
                              periodScope = scope;
                              startDate = range.start;
                              endDate = range.end;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: dialogContext,
                                    initialDate: startDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (d != null) {
                                    setState(() {
                                      startDate = _dateOnly(d);
                                      if (endDate.isBefore(startDate)) {
                                        endDate = startDate;
                                      }
                                    });
                                  }
                                },
                                icon: const Icon(Icons.event),
                                label: Text(
                                  '${l10n.startDate}: ${dateFmt.format(startDate)}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: dialogContext,
                                    initialDate: endDate,
                                    firstDate: startDate,
                                    lastDate: DateTime(2100),
                                  );
                                  if (d != null) {
                                    setState(() => endDate = _dateOnly(d));
                                  }
                                },
                                icon: const Icon(Icons.event),
                                label: Text(
                                  '${l10n.endDate}: ${dateFmt.format(endDate)}',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              l10n.sessionPlanSummary(
                                sessionDrafts.fold<int>(
                                  0,
                                  (n, d) => n + d.weekdays.length,
                                ),
                                planned,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.groupStudents,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (gradeStudents.isEmpty)
                          Text(l10n.noStudentsForGrade)
                        else ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked =
                                        await showSearchableMultiSelectDialog<
                                            Student>(
                                      context: dialogContext,
                                      title: l10n.selectStudents,
                                      initiallySelected: {
                                        for (final st in gradeStudents)
                                          if (selectedStudents.contains(st.id))
                                            st,
                                      },
                                      labelOf: (s) => s.name,
                                      onSearch: (q) => searchableLocalFilter(
                                        items: gradeStudents,
                                        query: q,
                                        labelOf: (s) => s.name,
                                        limit: 120,
                                      ),
                                    );
                                    if (picked == null) return;
                                    setState(() {
                                      selectedStudents
                                        ..clear()
                                        ..addAll(picked.map((s) => s.id));
                                    });
                                  },
                                  icon: const Icon(Icons.person_search_outlined),
                                  label: Text(l10n.selectStudents),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.selectedStudentsCount(
                                  selectedStudents.length,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          if (selectedStudents.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 160),
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: gradeStudents
                                      .where(
                                        (st) =>
                                            selectedStudents.contains(st.id),
                                      )
                                      .map(
                                        (st) => InputChip(
                                          label: Text(st.name),
                                          onDeleted: () => setState(
                                            () => selectedStudents.remove(st.id),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    if (sessionDrafts.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.pickAtLeastOneWeekday)),
                      );
                      return;
                    }
                    if (sessionDrafts.any((d) => d.weekdays.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.pickAtLeastOneWeekday)),
                      );
                      return;
                    }
                    if (sessionDrafts.any((d) => d.subjectId.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.addGradesSubjectsFirst)),
                      );
                      return;
                    }
                    if (endDate.isBefore(startDate)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.invalidDateRange)),
                      );
                      return;
                    }
                    final selectedClassroom = classrooms.cast<Classroom?>().firstWhere(
                          (c) => c?.id == classroomId,
                          orElse: () => null,
                        );
                    final savedSessions = [
                      for (final d in sessionDrafts) d.toGroupSession(),
                    ];
                    final group = StudyGroup(
                      id: existing?.id ?? '',
                      name: nameCtrl.text.trim(),
                      branchId:
                          existing?.branchId ?? AppDefaults.branchId,
                      gradeId: gradeId,
                      subjectId: savedSessions.first.subjectId,
                      classroomId: classroomId,
                      capacity: selectedClassroom?.capacity ??
                          existing?.capacity ??
                          20,
                      sessions: savedSessions,
                      studentIds: selectedStudents.toList(),
                      startDate: dateFmt.format(startDate),
                      endDate: dateFmt.format(endDate),
                    );
                    try {
                      await context.read<AdminRepository>().saveGroup(group);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.sessionPlanSummary(
                                group.sessions.length,
                                group.plannedSessionCount,
                              ),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${l10n.save}: $e'),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    }
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
    final grades = [...?context.watch<CrudListCubit<Grade>>().state.items];
    final subjects =
        [...?context.watch<CrudListCubit<Subject>>().state.items];
    final teachers =
        [...?context.watch<CrudListCubit<Teacher>>().state.items];
    final classrooms =
        [...?context.watch<CrudListCubit<Classroom>>().state.items];
    final students =
        [...?context.watch<CrudListCubit<Student>>().state.items];
    final schedules = List<ScheduleSlot>.from(
      context.watch<CrudListCubit<ScheduleSlot>>().state.items ?? const [],
    );
    final records = List<AttendanceRecord>.from(
      context.watch<CrudListCubit<AttendanceRecord>>().state.items ?? const [],
    );
    final gradeName = {for (final g in grades) g.id: g.name};
    final subjectName = {for (final s in subjects) s.id: s.name};
    final weekdays = _weekdayLabels(l10n);

    if (_detailGroup != null) {
      return AdminPageFrame(
        title: l10n.groups,
        onAdd: () => _openForm(
          context,
          grades: grades,
          subjects: subjects,
          teachers: teachers,
          classrooms: classrooms,
          students: students,
        ),
        child: _GroupSessionsDetail(
          group: _detailGroup!,
          subjectName: subjectName,
          students: students,
          records: records,
          schedules: schedules,
          onBack: () => setState(() => _detailGroup = null),
        ),
      );
    }

    return AdminPageFrame(
      title: l10n.groups,
      onAdd: () => _openForm(
        context,
        grades: grades,
        subjects: subjects,
        teachers: teachers,
        classrooms: classrooms,
        students: students,
      ),
      child: BlocBuilder<CrudListCubit<StudyGroup>, CrudListState<StudyGroup>>(
        builder: (context, state) {
          if (state.isLoading && state.items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && state.items == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final items = state.items ?? [];
          return ResponsiveDataTable(
            columns: [
              DataColumnSpec(l10n.group),
              DataColumnSpec(l10n.grade),
              DataColumnSpec(l10n.selectWeekdays),
              DataColumnSpec(l10n.groupStudents),
              DataColumnSpec(l10n.plannedSessions),
            ],
            rowCount: items.length,
            cellBuilder: (r, c) {
              final g = items[r];
              final sessionLabel = g.sessions.isEmpty
                  ? '-'
                  : g.sessions
                      .map((s) {
                        final subj =
                            subjectName[s.subjectId] ?? s.subjectId;
                        final days = s.weekdays
                            .map((wd) => weekdays[wd] ?? '$wd')
                            .join(', ');
                        return '$subj ($days ${s.startTime}-${s.endTime})';
                      })
                      .join(' · ');
              return switch (c) {
                0 => g.name,
                1 => gradeName[g.gradeId] ?? g.gradeId,
                2 => sessionLabel,
                3 => '${g.studentIds.length}',
                _ => '${g.plannedSessionCount}',
              };
            },
            mobileTitleBuilder: (r) => items[r].name,
            mobileSubtitleBuilder: (r) {
              final g = items[r];
              return '${gradeName[g.gradeId] ?? ''} · ${subjectName[g.subjectId] ?? ''} · ${l10n.sessionPlanSummary(g.sessions.length, g.plannedSessionCount)}';
            },
            onOpen: (r) => setState(() {
              _detailGroup = items[r];
            }),
            onEdit: (r) => _openForm(
              context,
              existing: items[r],
              grades: grades,
              subjects: subjects,
              teachers: teachers,
              classrooms: classrooms,
              students: students,
            ),
            onDelete: (r) async {
              final ok = await confirmDelete(context, items[r].name);
              if (!context.mounted || !ok) return;
              context.read<CrudListCubit<StudyGroup>>().delete(items[r]);
            },
          );
        },
      ),
    );
  }
}

class _GroupAttRow {
  const _GroupAttRow({
    required this.studentId,
    required this.studentName,
    required this.phone,
    required this.date,
    required this.slotId,
    required this.sessionLabel,
    required this.state,
    this.checkInAt,
    this.carried = false,
  });

  final String studentId;
  final String studentName;
  final String phone;
  final String date;
  final String slotId;
  final String sessionLabel;
  final SessionRowState state;
  final DateTime? checkInAt;
  final bool carried;
}

class _GroupSessionsDetail extends StatefulWidget {
  const _GroupSessionsDetail({
    required this.group,
    required this.subjectName,
    required this.students,
    required this.records,
    required this.schedules,
    required this.onBack,
  });

  final StudyGroup group;
  final Map<String, String> subjectName;
  final List<Student> students;
  final List<AttendanceRecord> records;
  final List<ScheduleSlot> schedules;
  final VoidCallback onBack;

  @override
  State<_GroupSessionsDetail> createState() => _GroupSessionsDetailState();
}

class _GroupSessionsDetailState extends State<_GroupSessionsDetail> {
  String? _slotId;
  SessionRowState? _status;
  DateTime? _date;
  final _dateCtrl = TextEditingController();

  @override
  void dispose() {
    _dateCtrl.dispose();
    super.dispose();
  }

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
    });
  }

  void _clearFilters() {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _slotId = null;
      _status = null;
      _date = null;
      _syncDateField(l10n);
    });
  }

  bool _statusMatches(SessionRowState actual, SessionRowState filter) {
    if (filter == SessionRowState.absent) {
      return actual == SessionRowState.absent ||
          actual == SessionRowState.notCheckedIn;
    }
    return actual == filter;
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

  List<_GroupAttRow> _buildRows(AppLocalizations l10n) {
    final rows = <_GroupAttRow>[];
    final sessions = groupSessionsAcrossDates(
      group: widget.group,
      schedules: widget.schedules,
      records: widget.records,
    );

    for (final session in sessions) {
      final subj = subjectNameForSlot(
        session.slot,
        session.group,
        widget.subjectName,
      );
      final roster = rosterForSession(
        session: session,
        schedules: widget.schedules,
        students: widget.students,
        records: widget.records,
      );
      final label = session.sessionLabel(l10n, subjectName: subj);
      final slotKey = session.slot.id.isNotEmpty
          ? session.slot.id
          : '${session.slot.weekday}|${session.slot.startTime}|${session.slot.endTime}';
      for (final r in roster) {
        final student = widget.students.cast<Student?>().firstWhere(
              (s) => s?.id == r.studentId,
              orElse: () => null,
            );
        rows.add(
          _GroupAttRow(
            studentId: r.studentId,
            studentName: r.studentName,
            phone: student?.phone?.trim().isNotEmpty == true
                ? student!.phone!
                : '-',
            date: session.date,
            slotId: slotKey,
            sessionLabel: label,
            state: r.state,
            checkInAt: r.checkInAt,
            carried: r.carriedFromPrevious,
          ),
        );
      }
    }

    return rows;
  }

  List<_GroupAttRow> _applyFilters(List<_GroupAttRow> rows) {
    final dateKey = _date == null ? null : sessionDateKey(_date!);
    return rows.where((r) {
      if (_slotId != null && r.slotId != _slotId) return false;
      if (_status != null && !_statusMatches(r.state, _status!)) return false;
      if (dateKey != null && r.date != dateKey) return false;
      return true;
    }).toList(growable: false);
  }

  bool get _hasActiveFilters =>
      _slotId != null || _status != null || _date != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');
    _syncDateField(l10n);

    final allRows = _buildRows(l10n);
    final rows = _applyFilters(allRows);
    final slots = effectiveSlotsForGroup(widget.group, widget.schedules);

    final presentN =
        rows.where((r) => r.state == SessionRowState.present).length;
    final lateN = rows.where((r) => r.state == SessionRowState.late).length;
    final absentN = rows
        .where(
          (r) =>
              r.state == SessionRowState.absent ||
              r.state == SessionRowState.notCheckedIn,
        )
        .length;

    InputDecoration filterDecoration(String label) => InputDecoration(
          isDense: true,
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
              tooltip: l10n.groups,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${l10n.groupStudents}: ${widget.group.studentIds.length} · ${l10n.sessions}: ${slots.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _GroupCountChip(
              label: l10n.presentCount(presentN),
              color: AppColors.success,
            ),
            _GroupCountChip(
              label: l10n.lateCount(lateN),
              color: AppColors.warning,
            ),
            _GroupCountChip(
              label: l10n.absentCount(absentN),
              color: AppColors.danger,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 48,
              child: DropdownButtonFormField<String?>(
                value: _slotId,
                isExpanded: true,
                decoration: filterDecoration(l10n.sessionTime),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.allOrUnspecified),
                  ),
                  for (final slot in slots)
                    DropdownMenuItem<String?>(
                      value: slot.id.isNotEmpty
                          ? slot.id
                          : '${slot.weekday}|${slot.startTime}|${slot.endTime}',
                      child: Text(
                        sessionSlotLabel(
                          l10n,
                          slot: slot,
                          subjectName: subjectNameForSlot(
                            slot,
                            widget.group,
                            widget.subjectName,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _slotId = v),
              ),
            ),
            SizedBox(
              width: 180,
              height: 48,
              child: DropdownButtonFormField<SessionRowState?>(
                value: _status,
                isExpanded: true,
                decoration: filterDecoration(l10n.status),
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
                onChanged: (v) => setState(() => _status = v),
              ),
            ),
            SizedBox(
              width: 180,
              height: 48,
              child: TextField(
                readOnly: true,
                onTap: _pickDate,
                controller: _dateCtrl,
                decoration: filterDecoration(l10n.date).copyWith(
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
        const SizedBox(height: 12),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: ResponsiveDataTable(
              columns: [
                DataColumnSpec(l10n.student),
                DataColumnSpec(l10n.phone),
                DataColumnSpec(l10n.date),
                DataColumnSpec(l10n.sessionTime),
                DataColumnSpec(l10n.status),
                DataColumnSpec(l10n.checkIn),
              ],
              rowCount: rows.length,
              emptyMessage: l10n.noData,
              cellBuilder: (r, c) {
                final row = rows[r];
                return switch (c) {
                  0 => row.studentName,
                  1 => row.phone,
                  2 => row.date,
                  3 => row.sessionLabel,
                  4 => _statusLabel(l10n, row.state),
                  _ => row.checkInAt == null
                      ? '-'
                      : timeFormat.format(row.checkInAt!.toLocal()),
                };
              },
              cellWidgetBuilder: (r, c) {
                if (c != 4) return null;
                final row = rows[r];
                return SessionStateChip(
                  state: row.state,
                  carried: row.carried,
                );
              },
              mobileTitleBuilder: (r) => rows[r].studentName,
              mobileSubtitleBuilder: (r) {
                final row = rows[r];
                return '${row.date} · ${row.sessionLabel} · ${_statusLabel(l10n, row.state)}';
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupCountChip extends StatelessWidget {
  const _GroupCountChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
