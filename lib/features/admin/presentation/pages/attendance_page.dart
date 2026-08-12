import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fingerprint_app/app/theme/app_colors.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/features/admin/domain/entities/attendance_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/crud_list_cubit.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/searchable_select.dart';
import 'package:fingerprint_app/features/admin/presentation/utils/session_attendance.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

const _kEmptyCell = '-';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CrudListCubit<AttendanceRecord>(
            watch: repo.watchAttendances,
            save: repo.saveAttendance,
            remove: repo.deleteAttendance,
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
          create: (_) => CrudListCubit<StudyGroup>(
            watch: repo.watchGroups,
            save: repo.saveGroup,
            remove: repo.deleteGroup,
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
        BlocProvider(
          create: (_) => CrudListCubit<Subject>(
            watch: repo.watchSubjects,
            save: repo.saveSubject,
            remove: repo.deleteSubject,
            idOf: (e) => e.id,
          ),
        ),
        BlocProvider(
          create: (_) => CrudListCubit<ParentProfile>(
            watch: repo.watchParents,
            save: repo.saveParent,
            remove: repo.deleteParent,
            idOf: (e) => e.id,
          ),
        ),
      ],
      child: const _AttendanceView(),
    );
  }
}

Map<int, String> _weekdayLabels(AppLocalizations l10n) => {
      1: l10n.monday,
      2: l10n.tuesday,
      3: l10n.wednesday,
      4: l10n.thursday,
      5: l10n.friday,
      6: l10n.saturday,
      7: l10n.sunday,
    };

String _statusLabel(AppLocalizations l10n, AttendanceStatus status) {
  return switch (status) {
    AttendanceStatus.present => l10n.statusPresent,
    AttendanceStatus.late => l10n.statusLate,
    AttendanceStatus.absent => l10n.statusAbsent,
    AttendanceStatus.excused => l10n.statusExcused,
  };
}

String _sourceLabel(AppLocalizations l10n, AttendanceSource source) {
  return switch (source) {
    AttendanceSource.manual => l10n.sourceManual,
    AttendanceSource.fingerprint => l10n.sourceFingerprint,
    AttendanceSource.device => l10n.sourceDevice,
  };
}

Color _statusColor(AttendanceStatus status) {
  return switch (status) {
    AttendanceStatus.present => AppColors.success,
    AttendanceStatus.late => AppColors.warning,
    AttendanceStatus.absent => AppColors.danger,
    AttendanceStatus.excused => AppColors.info,
  };
}

AttendanceStatus _bestStatus(Iterable<AttendanceRecord> records) {
  final set = records.map((r) => r.status).toSet();
  if (set.contains(AttendanceStatus.present)) return AttendanceStatus.present;
  if (set.contains(AttendanceStatus.late)) return AttendanceStatus.late;
  if (set.contains(AttendanceStatus.excused)) return AttendanceStatus.excused;
  return AttendanceStatus.absent;
}

String _scheduleLabel(AppLocalizations l10n, ScheduleSlot slot) {
  final day = _weekdayLabels(l10n)[slot.weekday] ?? '${slot.weekday}';
  return '$day ${slot.startTime} - ${slot.endTime}';
}

/// Subject name + weekday/time.
String _sessionSlotLabel(
  AppLocalizations l10n, {
  required ScheduleSlot slot,
  String? subjectName,
}) {
  final schedule = _scheduleLabel(l10n, slot);
  final name = subjectName?.trim();
  if (name == null || name.isEmpty) return schedule;
  return '$name · $schedule';
}

String _dateKey([DateTime? d]) =>
    DateFormat('yyyy-MM-dd').format(d ?? DateTime.now());

int _hhmmToMinutes(String value) {
  final parts = value.split(':');
  final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return h * 60 + m;
}

bool _slotsAreConsecutive(ScheduleSlot earlier, ScheduleSlot later) {
  if (earlier.weekday != later.weekday) return false;
  if (earlier.groupId != later.groupId) return false;
  final end = _hhmmToMinutes(earlier.endTime);
  final start = _hhmmToMinutes(later.startTime);
  // Back-to-back: next starts at/near previous end (up to 30 min gap).
  return start >= end - 5 && start <= end + 30 && start >= _hhmmToMinutes(earlier.startTime);
}

ScheduleSlot? _previousConsecutiveSlot(
  ScheduleSlot slot,
  List<ScheduleSlot> groupSlots,
) {
  final sameDay = groupSlots
      .where((s) => s.weekday == slot.weekday && s.id != slot.id)
      .toList()
    ..sort(
      (a, b) => _hhmmToMinutes(a.startTime).compareTo(_hhmmToMinutes(b.startTime)),
    );
  ScheduleSlot? prev;
  for (final s in sameDay) {
    if (_hhmmToMinutes(s.startTime) >= _hhmmToMinutes(slot.startTime)) break;
    prev = s;
  }
  if (prev == null) return null;
  return _slotsAreConsecutive(prev, slot) ? prev : null;
}

bool _checkInInSlotWindow(
  AttendanceRecord r,
  ScheduleSlot slot, {
  int beforeMinutes = 45,
  int afterMinutes = 20,
}) {
  final t = r.checkInAt;
  if (t == null) {
    // Manual / auto-absent without punch time: keep on the day, not time-bound.
    return true;
  }
  final local = t.toLocal();
  final m = local.hour * 60 + local.minute;
  final start = _hhmmToMinutes(slot.startTime);
  final end = _hhmmToMinutes(slot.endTime);
  return m >= start - beforeMinutes && m <= end + afterMinutes;
}

/// Punches in this slot window, or carried from the previous back-to-back slot.
List<AttendanceRecord> _recordsAttributedToSlot({
  required ScheduleSlot slot,
  required List<ScheduleSlot> groupSlots,
  required List<AttendanceRecord> dayRecords,
}) {
  final sameDay = groupSlots.where((s) => s.weekday == slot.weekday).toList()
    ..sort(
      (a, b) =>
          _hhmmToMinutes(a.startTime).compareTo(_hhmmToMinutes(b.startTime)),
    );
  final prev = _previousConsecutiveSlot(slot, groupSlots);
  final out = <AttendanceRecord>[];

  ScheduleSlot closestSlot(AttendanceRecord r) {
    final t = r.checkInAt!.toLocal();
    final punchM = t.hour * 60 + t.minute;
    return sameDay.reduce((a, b) {
      final da = (_hhmmToMinutes(a.startTime) - punchM).abs();
      final db = (_hhmmToMinutes(b.startTime) - punchM).abs();
      return da <= db ? a : b;
    });
  }

  for (final r in dayRecords) {
    final inThis = _checkInInSlotWindow(r, slot);
    final inPrev =
        prev != null && r.checkInAt != null && _checkInInSlotWindow(r, prev);

    if (inThis) {
      out.add(r);
      continue;
    }
    if (inPrev) {
      // Same fingerprint counts as present for the following session.
      out.add(
        AttendanceRecord(
          id: r.id,
          studentId: r.studentId,
          branchId: r.branchId,
          date: r.date,
          status: AttendanceStatus.present,
          source: r.source,
          groupId: r.groupId,
          checkInAt: r.checkInAt,
          checkOutAt: r.checkOutAt,
          deviceId: r.deviceId,
          deviceUserId: r.deviceUserId,
          note: r.note,
          recordedBy: r.recordedBy,
        ),
      );
      continue;
    }

    // Punch outside every window -> attach to the closest slot only.
    if (r.checkInAt != null && sameDay.isNotEmpty) {
      final covered = sameDay.any((s) => _checkInInSlotWindow(r, s));
      if (!covered && closestSlot(r).id == slot.id) {
        out.add(r);
      }
    }
  }
  return out;
}

ScheduleSlot? _slotForRecord(
  AttendanceRecord r,
  List<ScheduleSlot> schedules,
) {
  final day = DateTime.tryParse(r.date);
  if (day == null || r.groupId == null) return null;
  final groupSlots = schedules.where((s) => s.groupId == r.groupId).toList()
    ..sort(
      (a, b) => _hhmmToMinutes(a.startTime).compareTo(_hhmmToMinutes(b.startTime)),
    );
  final sameDay = groupSlots.where((s) => s.weekday == day.weekday).toList();
  if (sameDay.isEmpty) return null;
  for (final s in sameDay) {
    if (_checkInInSlotWindow(r, s)) return s;
  }
  return sameDay.first;
}

List<ScheduleSlot> _effectiveSlotsForGroup(
  StudyGroup group,
  List<ScheduleSlot> schedules,
) {
  final groupSlots = schedules.where((s) => s.groupId == group.id).toList()
    ..sort((a, b) {
      final w = a.weekday.compareTo(b.weekday);
      return w != 0 ? w : a.startTime.compareTo(b.startTime);
    });
  if (groupSlots.isNotEmpty) return groupSlots;
  final out = <ScheduleSlot>[];
  for (final s in group.sessions) {
    for (final wd in s.weekdays) {
      out.add(
        ScheduleSlot(
          id: '${group.id}_${wd}_${s.startTime}_${s.subjectId}',
          groupId: group.id,
          weekday: wd,
          startTime: s.startTime,
          endTime: s.endTime,
          branchId: group.branchId,
          subjectId: s.subjectId.isNotEmpty ? s.subjectId : group.subjectId,
        ),
      );
    }
  }
  return out;
}

bool _groupActiveOnDate(StudyGroup g, String dateKey) {
  if (g.startDate != null &&
      g.startDate!.isNotEmpty &&
      dateKey.compareTo(g.startDate!) < 0) {
    return false;
  }
  if (g.endDate != null &&
      g.endDate!.isNotEmpty &&
      dateKey.compareTo(g.endDate!) > 0) {
    return false;
  }
  return true;
}

DateTime? _sessionStartAt(String dateKey, ScheduleSlot slot) {
  final d = DateTime.tryParse(dateKey);
  if (d == null) return null;
  final start = _hhmmToMinutes(slot.startTime);
  return DateTime(d.year, d.month, d.day, start ~/ 60, start % 60);
}

DateTime? _sessionEndAt(String dateKey, ScheduleSlot slot) {
  final d = DateTime.tryParse(dateKey);
  if (d == null) return null;
  final end = _hhmmToMinutes(slot.endTime);
  return DateTime(d.year, d.month, d.day, end ~/ 60, end % 60);
}

bool _sessionHasStarted(String dateKey, ScheduleSlot slot) {
  final start = _sessionStartAt(dateKey, slot);
  if (start == null) return false;
  return !DateTime.now().isBefore(start);
}

bool _sessionHasEnded(String dateKey, ScheduleSlot slot) {
  final end = _sessionEndAt(dateKey, slot);
  if (end == null) return false;
  return DateTime.now().isAfter(end);
}

class _SessionOption {
  const _SessionOption({
    required this.group,
    required this.slot,
    required this.date,
  });

  final StudyGroup group;
  final ScheduleSlot slot;
  final String date;

  String get key => '${group.id}|${slot.id}|$date';

  /// Session label: subject + schedule time.
  String sessionLabel(AppLocalizations l10n, {String? subjectName}) =>
      _sessionSlotLabel(l10n, slot: slot, subjectName: subjectName);

  String label(AppLocalizations l10n, {String? subjectName}) =>
      '${sessionLabel(l10n, subjectName: subjectName)} · ${group.name}';
}

List<StudyGroup> _groupsWithSessionsOnDate({
  required DateTime date,
  required List<StudyGroup> groups,
  required List<ScheduleSlot> schedules,
}) {
  final dateKey = _dateKey(date);
  final weekday = date.weekday;
  return groups
      .where((g) {
        if (!_groupActiveOnDate(g, dateKey)) return false;
        final slots = _effectiveSlotsForGroup(g, schedules);
        return slots.any((s) => s.weekday == weekday);
      })
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

List<ScheduleSlot> _sessionSlotsForGroupOnDate({
  required StudyGroup group,
  required DateTime date,
  required List<ScheduleSlot> schedules,
}) {
  final weekday = date.weekday;
  return _effectiveSlotsForGroup(group, schedules)
      .where((s) => s.weekday == weekday)
      .toList()
    ..sort(
      (a, b) =>
          _hhmmToMinutes(a.startTime).compareTo(_hhmmToMinutes(b.startTime)),
    );
}

String? _subjectNameForGroup(
  StudyGroup? group,
  Map<String, String> subjectName,
) {
  if (group == null) return null;
  return subjectName[group.subjectId];
}

const _kAttendanceFieldHeight = 56.0;

/// Shared section title + optional subtitle.
class _AttendanceSectionHeader extends StatelessWidget {
  const _AttendanceSectionHeader({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Card wrapper for filter fields (date, group, session, etc.).
class _AttendanceFilterCard extends StatelessWidget {
  const _AttendanceFilterCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

/// Date picker styled like other form fields (same height).
class _AttendanceDateField extends StatelessWidget {
  const _AttendanceDateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final display = value ?? l10n.allDates;
    return SizedBox(
      height: _kAttendanceFieldHeight,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null && onClear != null)
                IconButton(
                  tooltip: l10n.clearSelection,
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_rounded, size: 18),
                ),
              const Icon(Icons.calendar_month_outlined, size: 20),
              const SizedBox(width: 4),
            ],
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        child: InkWell(
          onTap: onTap,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              display,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: value == null
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : null,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

/// Summary chips row (present / late / absent â€¦).
class _AttendanceStatsBar extends StatelessWidget {
  const _AttendanceStatsBar({required this.chips});

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: chips,
        ),
      ),
    );
  }
}

/// Bordered container for roster / attendance tables.
class _AttendanceTableCard extends StatelessWidget {
  const _AttendanceTableCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

class _AttendanceEmptyMessage extends StatelessWidget {
  const _AttendanceEmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Responsive row of equal-height filter fields.
class _AttendanceFilterRow extends StatelessWidget {
  const _AttendanceFilterRow({required this.fields});

  final List<Widget> fields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: fields[i]),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              fields[i],
            ],
          ],
        );
      },
    );
  }
}

class _AttendanceView extends StatefulWidget {
  const _AttendanceView();

  @override
  State<_AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<_AttendanceView> {
  String? _historyStudentId;

  Future<void> _openForm(
    BuildContext context, {
    AttendanceRecord? existing,
    required List<Student> students,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noStudentsYet)),
      );
      return;
    }
    var studentId = existing != null &&
            students.any((s) => s.id == existing.studentId)
        ? existing.studentId
        : students.first.id;
    var status = existing?.status ?? AttendanceStatus.present;
    var source = existing?.source ?? AttendanceSource.manual;
    final dateCtrl = TextEditingController(
      text: existing?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? l10n.addAttendance : l10n.editAttendance,
              ),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SearchableSelectField<Student>(
                          label: l10n.student,
                          value: students.cast<Student?>().firstWhere(
                                (s) => s?.id == studentId,
                                orElse: () => students.first,
                              ),
                          labelOf: (s) => s.name,
                          onSearch: (q) => searchableLocalFilter(
                            items: students,
                            query: q,
                            labelOf: (s) => s.name,
                          ),
                          onChanged: (s) => setDialogState(
                            () => studentId = s?.id ?? studentId,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: dateCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.date,
                            suffixIcon: IconButton(
                              tooltip: l10n.pickDate,
                              icon: const Icon(Icons.calendar_month_outlined),
                              onPressed: () async {
                                final parsed =
                                    DateTime.tryParse(dateCtrl.text) ??
                                        DateTime.now();
                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: parsed,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    dateCtrl.text =
                                        DateFormat('yyyy-MM-dd').format(picked);
                                  });
                                }
                              },
                            ),
                          ),
                          validator: (v) => DateTime.tryParse(v ?? '') == null
                              ? l10n.invalidDate
                              : null,
                        ),
                        const SizedBox(height: 12),
                        SearchableSelectField<AttendanceStatus>(
                          label: l10n.status,
                          value: status,
                          labelOf: (s) => _statusLabel(l10n, s),
                          onSearch: (q) => searchableLocalFilter(
                            items: AttendanceStatus.values,
                            query: q,
                            labelOf: (s) => _statusLabel(l10n, s),
                          ),
                          onChanged: (v) =>
                              setDialogState(() => status = v ?? status),
                        ),
                        const SizedBox(height: 12),
                        SearchableSelectField<AttendanceSource>(
                          label: l10n.source,
                          value: source,
                          labelOf: (s) => _sourceLabel(l10n, s),
                          onSearch: (q) => searchableLocalFilter(
                            items: AttendanceSource.values,
                            query: q,
                            labelOf: (s) => _sourceLabel(l10n, s),
                          ),
                          onChanged: (v) =>
                              setDialogState(() => source = v ?? source),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: noteCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: l10n.adminNote,
                          ),
                        ),
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
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    final now = DateTime.now();
                    context.read<CrudListCubit<AttendanceRecord>>().save(
                          AttendanceRecord(
                            id: existing?.id ?? '',
                            studentId: studentId,
                            branchId:
                                existing?.branchId ?? AppDefaults.branchId,
                            date: dateCtrl.text.trim(),
                            status: status,
                            source: source,
                            groupId: existing?.groupId,
                            checkInAt: existing?.checkInAt ??
                                (status == AttendanceStatus.absent
                                    ? null
                                    : now),
                            checkOutAt: existing?.checkOutAt,
                            deviceId: existing?.deviceId,
                            deviceUserId: existing?.deviceUserId,
                            note: noteCtrl.text.trim().isEmpty
                                ? null
                                : noteCtrl.text.trim(),
                            recordedBy: existing?.recordedBy,
                          ),
                        );
                    Navigator.pop(dialogContext);
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

  Future<void> _deleteRecords(
    BuildContext context, {
    required List<AttendanceRecord> records,
    required Map<String, String> studentName,
  }) async {
    if (records.isEmpty) return;
    final label = studentName[records.first.studentId] ?? records.first.studentId;
    final ok = await confirmDelete(context, label);
    if (!context.mounted || !ok) return;
    final cubit = context.read<CrudListCubit<AttendanceRecord>>();
    for (final r in records) {
      cubit.delete(r);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final students =
        List<Student>.from(context.watch<CrudListCubit<Student>>().state.items ?? const []);
    final groups =
        List<StudyGroup>.from(context.watch<CrudListCubit<StudyGroup>>().state.items ?? const []);
    final schedules = List<ScheduleSlot>.from(
      context.watch<CrudListCubit<ScheduleSlot>>().state.items ?? const [],
    );
    final subjects = List<Subject>.from(
      context.watch<CrudListCubit<Subject>>().state.items ?? const [],
    );
    final parents = List<ParentProfile>.from(
      context.watch<CrudListCubit<ParentProfile>>().state.items ?? const [],
    );
    final studentName = {for (final s in students) s.id: s.name};
    final groupName = {for (final g in groups) g.id: g.name};
    final subjectNameMap = {for (final s in subjects) s.id: s.name};
    final timeFormat = DateFormat('HH:mm');

    return AdminPageFrame(
      title: l10n.attendance,
      onAdd: () => _openForm(context, students: students),
      child: BlocBuilder<CrudListCubit<AttendanceRecord>,
          CrudListState<AttendanceRecord>>(
        builder: (context, state) {
          if (state.isLoading && state.items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = List<AttendanceRecord>.from(
            state.items ?? const <AttendanceRecord>[],
          );

          return _SessionSearchPane(
            groups: groups,
            schedules: schedules,
            students: students,
            parents: parents,
            records: records,
            subjectName: subjectNameMap,
            groupName: groupName,
            timeFormat: timeFormat,
            historyStudentId: _historyStudentId,
            onHistoryStudentChanged: (id) =>
                setState(() => _historyStudentId = id),
            onEdit: (r) => _openForm(context, existing: r, students: students),
            onDelete: (list) => _deleteRecords(
              context,
              records: list,
              studentName: studentName,
            ),
          );
        },
      ),
    );
  }
}

/// Sessions table + filters + student roster popup.
class _SessionSearchPane extends StatefulWidget {
  const _SessionSearchPane({
    required this.groups,
    required this.schedules,
    required this.students,
    required this.parents,
    required this.records,
    required this.subjectName,
    required this.groupName,
    required this.timeFormat,
    required this.historyStudentId,
    required this.onHistoryStudentChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final List<StudyGroup> groups;
  final List<ScheduleSlot> schedules;
  final List<Student> students;
  final List<ParentProfile> parents;
  final List<AttendanceRecord> records;
  final Map<String, String> subjectName;
  final Map<String, String> groupName;
  final DateFormat timeFormat;
  final String? historyStudentId;
  final ValueChanged<String?> onHistoryStudentChanged;
  final void Function(AttendanceRecord) onEdit;
  final Future<void> Function(List<AttendanceRecord>) onDelete;

  @override
  State<_SessionSearchPane> createState() => _SessionSearchPaneState();
}

class _SessionSearchPaneState extends State<_SessionSearchPane> {
  DateTime? _filterDate = DateTime.now();
  StudyGroup? _selectedGroup;
  ScheduleSlot? _selectedSlot;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _filterDate = picked;
      _selectedSlot = null;
    });
  }

  Future<void> _openSessionDialog(SessionAttendanceTarget session) async {
    final subj = subjectNameForSlot(
      session.slot,
      session.group,
      widget.subjectName,
    );
    final cubit = context.read<CrudListCubit<AttendanceRecord>>();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BlocProvider<CrudListCubit<AttendanceRecord>>.value(
        value: cubit,
        child: _SessionStudentsDialog(
          session: session,
          subjectLabel: subj,
          students: widget.students,
          parents: widget.parents,
          schedules: widget.schedules,
          records: widget.records,
          timeFormat: widget.timeFormat,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
        ),
      ),
    );
  }

  Student? _historyStudent() {
    final id = widget.historyStudentId;
    if (id == null) return null;
    return widget.students.cast<Student?>().firstWhere(
          (s) => s?.id == id,
          orElse: () => null,
        );
  }

  List<StudyGroup> _groupsForFilter() {
    if (_filterDate == null) {
      return [...widget.groups]..sort((a, b) => a.name.compareTo(b.name));
    }
    return _groupsWithSessionsOnDate(
      date: _filterDate!,
      groups: widget.groups,
      schedules: widget.schedules,
    );
  }

  List<ScheduleSlot> _slotsForFilter(StudyGroup? group) {
    if (group == null) return const [];
    if (_filterDate != null) {
      return _sessionSlotsForGroupOnDate(
        group: group,
        date: _filterDate!,
        schedules: widget.schedules,
      );
    }
    return effectiveSlotsForGroup(group, widget.schedules);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateKey = _filterDate == null ? null : _dateKey(_filterDate!);
    final isToday = dateKey != null && dateKey == _dateKey();

    final groupsForFilter = _groupsForFilter();
    final selectedGroup = _selectedGroup != null &&
            groupsForFilter.any((g) => g.id == _selectedGroup!.id)
        ? _selectedGroup
        : null;

    final slotsForGroup = _slotsForFilter(selectedGroup);
    final selectedSlot = _selectedSlot != null &&
            slotsForGroup.any(
              (s) =>
                  s.weekday == _selectedSlot!.weekday &&
                  s.startTime == _selectedSlot!.startTime &&
                  s.endTime == _selectedSlot!.endTime,
            )
        ? _selectedSlot
        : null;

    String slotLabel(ScheduleSlot slot) {
      final g = selectedGroup ??
          widget.groups.cast<StudyGroup?>().firstWhere(
                (x) => x?.id == slot.groupId,
                orElse: () => null,
              );
      final subj = g == null
          ? null
          : subjectNameForSlot(slot, g, widget.subjectName);
      return sessionSlotLabel(l10n, slot: slot, subjectName: subj);
    }

    final List<SessionAttendanceTarget> visibleSessions;
    if (_filterDate == null && selectedSlot != null) {
      final groupForSlot = selectedGroup ??
          widget.groups.cast<StudyGroup?>().firstWhere(
                (g) => g?.id == selectedSlot.groupId,
                orElse: () => null,
              );
      visibleSessions = groupForSlot == null
          ? const []
          : sessionOccurrencesAcrossDates(
              group: groupForSlot,
              slot: selectedSlot,
              records: widget.records,
            );
    } else if (_filterDate == null && selectedGroup != null) {
      visibleSessions = groupSessionsAcrossDates(
        group: selectedGroup,
        schedules: widget.schedules,
        records: widget.records,
      );
    } else {
      final baseSessions = _filterDate == null
          ? allWeeklySessions(
              groups: widget.groups,
              schedules: widget.schedules,
            )
          : sessionsOnDate(
              date: _filterDate!,
              groups: widget.groups,
              schedules: widget.schedules,
            );
      visibleSessions = filterSessions(
        sessions: baseSessions,
        group: selectedGroup,
        slot: selectedSlot,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AttendanceSectionHeader(
          title: isToday
              ? l10n.todaySessions
              : (_filterDate == null ? l10n.sessions : l10n.sessionSearch),
          subtitle: l10n.sessionSearchHint,
        ),
        const SizedBox(height: 12),
        _AttendanceFilterCard(
          child: _AttendanceFilterRow(
            fields: [
              _AttendanceDateField(
                label: l10n.date,
                value: dateKey,
                onTap: _pickDate,
                onClear: () => setState(() {
                  _filterDate = null;
                  _selectedSlot = null;
                }),
              ),
              SearchableSelectField<StudyGroup>(
                label: l10n.groups,
                fieldHeight: _kAttendanceFieldHeight,
                value: selectedGroup,
                labelOf: (g) => g.name,
                allowClear: true,
                clearLabel: l10n.unspecified,
                onSearch: (q) => searchableLocalFilter(
                  items: groupsForFilter,
                  query: q,
                  labelOf: (g) => g.name,
                ),
                onChanged: (g) => setState(() {
                  _selectedGroup = g;
                  _selectedSlot = null;
                }),
              ),
              SearchableSelectField<ScheduleSlot>(
                label: l10n.selectSession,
                fieldHeight: _kAttendanceFieldHeight,
                value: selectedSlot,
                labelOf: slotLabel,
                allowClear: true,
                clearLabel: l10n.unspecified,
                onSearch: (q) => searchableLocalFilter(
                  items: slotsForGroup,
                  query: q,
                  labelOf: slotLabel,
                ),
                onChanged: (s) => setState(() => _selectedSlot = s),
              ),
              SearchableSelectField<Student>(
                label: l10n.studentHistory,
                fieldHeight: _kAttendanceFieldHeight,
                value: _historyStudent(),
                labelOf: (s) => s.name,
                onSearch: (q) => searchableLocalFilter(
                  items: widget.students,
                  query: q,
                  labelOf: (s) => s.name,
                ),
                onChanged: (s) => widget.onHistoryStudentChanged(s?.id),
                allowClear: true,
                clearLabel: l10n.unspecified,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: widget.historyStudentId != null
              ? StudentHistoryPanel(
                  students: widget.students,
                  selectedId: widget.historyStudentId,
                  records: widget.records,
                  groups: widget.groups,
                  groupName: widget.groupName,
                  subjectName: widget.subjectName,
                  schedules: widget.schedules,
                  timeFormat: widget.timeFormat,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                )
              : SessionsOverviewTable(
                  sessions: visibleSessions,
                  subjectName: widget.subjectName,
                  schedules: widget.schedules,
                  students: widget.students,
                  records: widget.records,
                  showDateColumn: true,
                  onSelect: _openSessionDialog,
                ),
        ),
      ],
    );
  }
}

class _SessionStudentsDialog extends StatelessWidget {
  const _SessionStudentsDialog({
    required this.session,
    required this.subjectLabel,
    required this.students,
    required this.parents,
    required this.schedules,
    required this.records,
    required this.timeFormat,
    required this.onEdit,
    required this.onDelete,
  });

  final SessionAttendanceTarget session;
  final String? subjectLabel;
  final List<Student> students;
  final List<ParentProfile> parents;
  final List<ScheduleSlot> schedules;
  final List<AttendanceRecord> records;
  final DateFormat timeFormat;
  final void Function(AttendanceRecord) onEdit;
  final Future<void> Function(List<AttendanceRecord>) onDelete;

  ParentProfile? _parentOf(Student student) {
    if (student.parentIds.isEmpty) return null;
    final id = student.parentIds.first;
    return parents.cast<ParentProfile?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
  }

  Future<void> _setStatus(
    BuildContext context, {
    required SessionStudentRow row,
    required AttendanceStatus status,
  }) async {
    final cubit = context.read<CrudListCubit<AttendanceRecord>>();
    final now = DateTime.now();
    if (row.records.isNotEmpty) {
      final existing = row.records.first;
      cubit.save(
        AttendanceRecord(
          id: existing.id,
          studentId: existing.studentId,
          branchId: existing.branchId,
          date: session.date,
          status: status,
          source: AttendanceSource.manual,
          groupId: session.group.id,
          checkInAt: status == AttendanceStatus.absent ? null : (existing.checkInAt ?? now),
          checkOutAt: existing.checkOutAt,
          deviceId: existing.deviceId,
          deviceUserId: existing.deviceUserId,
          note: existing.note,
          recordedBy: existing.recordedBy,
        ),
      );
      return;
    }
    cubit.save(
      AttendanceRecord(
        id: '',
        studentId: row.studentId,
        branchId: session.group.branchId,
        date: session.date,
        status: status,
        source: AttendanceSource.manual,
        groupId: session.group.id,
        checkInAt: status == AttendanceStatus.absent ? null : now,
      ),
    );
  }

  Future<void> _clearAttendance(
    BuildContext context,
    SessionStudentRow row,
  ) async {
    if (row.records.isEmpty) return;
    await onDelete(row.records);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SizedBox(
        width: size.width * 0.96,
        height: size.height * 0.92,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<CrudListCubit<AttendanceRecord>,
              CrudListState<AttendanceRecord>>(
            builder: (context, state) {
              final liveRecords = List<AttendanceRecord>.from(
                state.items ?? records,
              );
              final rows = rosterForSession(
                session: session,
                schedules: schedules,
                students: students,
                records: liveRecords,
              );
              final studentById = {for (final s in students) s.id: s};
              final presentN = rows
                  .where((r) => r.state == SessionRowState.present)
                  .length;
              final lateN =
                  rows.where((r) => r.state == SessionRowState.late).length;
              final absentN = rows
                  .where(
                    (r) =>
                        r.state == SessionRowState.absent ||
                        r.state == SessionRowState.notCheckedIn,
                  )
                  .length;

              return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sessionStudents,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${session.sessionLabel(l10n, subjectName: subjectLabel)} · ${session.group.name} · ${session.date}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _CountChip(
                    label: l10n.presentCount(presentN),
                    color: AppColors.success,
                  ),
                  _CountChip(
                    label: l10n.lateCount(lateN),
                    color: AppColors.warning,
                  ),
                  _CountChip(
                    label: l10n.absentCount(absentN),
                    color: AppColors.danger,
                  ),
                  _CountChip(
                    label: '${l10n.studentsCount}: ${rows.length}',
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: rows.isEmpty
                    ? Center(child: Text(l10n.noStudentsForGrade))
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: DataTable(
                                    headingRowHeight: 48,
                                    dataRowMinHeight: 56,
                                    dataRowMaxHeight: 64,
                                    columnSpacing: 24,
                                    headingTextStyle: theme
                                        .textTheme.labelLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                    columns: [
                                      DataColumn(label: Text(l10n.student)),
                                      DataColumn(label: Text(l10n.status)),
                                      DataColumn(label: Text(l10n.studentPhone)),
                                      DataColumn(label: Text(l10n.parentName)),
                                      DataColumn(label: Text(l10n.parentPhone)),
                                      DataColumn(label: Text(l10n.checkIn)),
                                      const DataColumn(label: Text('')),
                                    ],
                                    rows: [
                                      for (final row in rows)
                                        () {
                                          final student =
                                              studentById[row.studentId];
                                          final parent = student == null
                                              ? null
                                              : _parentOf(student);
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(row.studentName)),
                                              DataCell(
                                                SessionStateChip(
                                                  state: row.state,
                                                  carried:
                                                      row.carriedFromPrevious,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  student?.phone?.trim().isNotEmpty ==
                                                          true
                                                      ? student!.phone!
                                                      : _kEmptyCell,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  parent?.name ?? _kEmptyCell,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  parent?.phone?.trim().isNotEmpty ==
                                                          true
                                                      ? parent!.phone!
                                                      : _kEmptyCell,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  row.checkInAt == null
                                                      ? _kEmptyCell
                                                      : timeFormat.format(
                                                          row.checkInAt!
                                                              .toLocal(),
                                                        ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      tooltip: l10n.markPresent,
                                                      icon: const Icon(
                                                        Icons.check_circle_outline,
                                                        color: AppColors.success,
                                                      ),
                                                      onPressed: () =>
                                                          _setStatus(
                                                        context,
                                                        row: row,
                                                        status: AttendanceStatus
                                                            .present,
                                                      ),
                                                    ),
                                                    PopupMenuButton<
                                                        AttendanceStatus>(
                                                      tooltip: l10n.status,
                                                      onSelected: (status) =>
                                                          _setStatus(
                                                        context,
                                                        row: row,
                                                        status: status,
                                                      ),
                                                      itemBuilder: (context) => [
                                                        PopupMenuItem(
                                                          value: AttendanceStatus
                                                              .present,
                                                          child: Text(
                                                            l10n.statusPresent,
                                                          ),
                                                        ),
                                                        PopupMenuItem(
                                                          value: AttendanceStatus
                                                              .late,
                                                          child: Text(
                                                            l10n.statusLate,
                                                          ),
                                                        ),
                                                        PopupMenuItem(
                                                          value: AttendanceStatus
                                                              .absent,
                                                          child: Text(
                                                            l10n.statusAbsent,
                                                          ),
                                                        ),
                                                        PopupMenuItem(
                                                          value: AttendanceStatus
                                                              .excused,
                                                          child: Text(
                                                            l10n.statusExcused,
                                                          ),
                                                        ),
                                                      ],
                                                      icon: const Icon(
                                                        Icons.edit_outlined,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip:
                                                          l10n.clearAttendance,
                                                      icon: Icon(
                                                        Icons.cancel_outlined,
                                                        color: theme
                                                            .colorScheme.error,
                                                      ),
                                                      onPressed: row
                                                              .records.isEmpty
                                                          ? null
                                                          : () =>
                                                              _clearAttendance(
                                                                context,
                                                                row,
                                                              ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }(),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
            },
          ),
        ),
      ),
    );
  }
}
/// Compact student history below the filter bar.
class _StudentHistoryInline extends StatelessWidget {
  const _StudentHistoryInline({
    required this.students,
    required this.selectedId,
    required this.records,
    required this.groupName,
    required this.schedules,
    required this.timeFormat,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Student> students;
  final String? selectedId;
  final List<AttendanceRecord> records;
  final Map<String, String> groupName;
  final List<ScheduleSlot> schedules;
  final DateFormat timeFormat;
  final void Function(AttendanceRecord) onEdit;
  final Future<void> Function(List<AttendanceRecord>) onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final sid = selectedId != null && students.any((s) => s.id == selectedId)
        ? selectedId!
        : null;
    if (sid == null) return const SizedBox.shrink();

    final studentName =
        students.where((s) => s.id == sid).map((s) => s.name).firstOrNull ?? sid;
    final mine = records.where((r) => r.studentId == sid).toList();
    final keyed = <String, List<AttendanceRecord>>{};
    for (final r in mine) {
      keyed.putIfAbsent('${r.date}|${r.groupId ?? ''}', () => []).add(r);
    }

    final sessions = keyed.entries.map((e) {
      final list = List<AttendanceRecord>.from(e.value);
      final primary = list.first;
      final slot = _slotForRecord(primary, schedules);
      final punches = list.where((r) => r.checkInAt != null).length;
      final checkIns = list.map((r) => r.checkInAt).whereType<DateTime>().toList()
        ..sort();
      return (
        date: primary.date,
        groupId: primary.groupId,
        status: bestAttendanceStatus(list),
        punches: punches,
        checkIns: checkIns,
        slot: slot,
        all: list,
        primary: primary,
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          leading: Icon(Icons.history, color: theme.colorScheme.primary, size: 22),
          title: Text(
            '$studentName · ${l10n.studentHistory}',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            sessions.isEmpty
                ? l10n.noHistoryForStudent
                : l10n.punchesCount(
                    sessions.fold<int>(0, (n, s) => n + s.punches),
                  ),
          ),
          children: [
            if (sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l10n.noHistoryForStudent),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final s = sessions[i];
                    final gName = s.groupId == null
                        ? l10n.ungroupedSession
                        : (groupName[s.groupId] ?? s.groupId!);
                    final scheduleText =
                        s.slot == null ? _kEmptyCell : scheduleSlotLabel(l10n, s.slot!);
                    final checkInText = s.checkIns.isEmpty
                        ? _kEmptyCell
                        : s.checkIns
                            .map((t) => timeFormat.format(t.toLocal()))
                            .join(', ');

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text('$gName · ${s.date}'),
                      subtitle: Text(
                        '$scheduleText · ${l10n.checkIn}: $checkInText',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StatusChip(status: s.status),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => onEdit(s.primary),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                            onPressed: () => onDelete(s.all),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(l10n, status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.color});

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
