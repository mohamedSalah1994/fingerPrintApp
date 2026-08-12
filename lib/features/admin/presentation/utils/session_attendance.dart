import 'package:fingerprint_app/app/theme/app_colors.dart';
import 'package:fingerprint_app/features/admin/domain/entities/attendance_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const kSessionEmptyCell = '-';

Map<int, String> sessionWeekdayLabels(AppLocalizations l10n) => {
      1: l10n.monday,
      2: l10n.tuesday,
      3: l10n.wednesday,
      4: l10n.thursday,
      5: l10n.friday,
      6: l10n.saturday,
      7: l10n.sunday,
    };

String sessionDateKey([DateTime? d]) =>
    DateFormat('yyyy-MM-dd').format(d ?? DateTime.now());

int _hhmmToMinutes(String value) {
  final parts = value.split(':');
  final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return h * 60 + m;
}

AttendanceStatus bestAttendanceStatus(Iterable<AttendanceRecord> records) {
  final set = records.map((r) => r.status).toSet();
  if (set.contains(AttendanceStatus.present)) return AttendanceStatus.present;
  if (set.contains(AttendanceStatus.late)) return AttendanceStatus.late;
  if (set.contains(AttendanceStatus.excused)) return AttendanceStatus.excused;
  return AttendanceStatus.absent;
}

String scheduleSlotLabel(AppLocalizations l10n, ScheduleSlot slot) {
  final day = sessionWeekdayLabels(l10n)[slot.weekday] ?? '${slot.weekday}';
  return '$day ${slot.startTime} - ${slot.endTime}';
}

String sessionSlotLabel(
  AppLocalizations l10n, {
  required ScheduleSlot slot,
  String? subjectName,
}) {
  final schedule = scheduleSlotLabel(l10n, slot);
  final name = subjectName?.trim();
  if (name == null || name.isEmpty) return schedule;
  return '$name · $schedule';
}

List<ScheduleSlot> effectiveSlotsForGroup(
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

String? subjectNameForSlot(
  ScheduleSlot slot,
  StudyGroup group,
  Map<String, String> subjectName,
) {
  final id = slot.subjectId ?? group.subjectId;
  return subjectName[id];
}

/// Nearest [anchor] date (same day or earlier) that falls on [slot]'s weekday.
String referenceDateForSlot(DateTime anchor, ScheduleSlot slot) {
  for (var i = 0; i < 7; i++) {
    final d = anchor.subtract(Duration(days: i));
    if (d.weekday == slot.weekday) return sessionDateKey(d);
  }
  return sessionDateKey(anchor);
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

bool _slotsAreConsecutive(ScheduleSlot earlier, ScheduleSlot later) {
  if (earlier.weekday != later.weekday) return false;
  if (earlier.groupId != later.groupId) return false;
  final end = _hhmmToMinutes(earlier.endTime);
  final start = _hhmmToMinutes(later.startTime);
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
  if (t == null) return true;
  final local = t.toLocal();
  final m = local.hour * 60 + local.minute;
  final start = _hhmmToMinutes(slot.startTime);
  final end = _hhmmToMinutes(slot.endTime);
  return m >= start - beforeMinutes && m <= end + afterMinutes;
}

List<AttendanceRecord> recordsAttributedToSlot({
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

    if (r.checkInAt != null && sameDay.isNotEmpty) {
      final covered = sameDay.any((s) => _checkInInSlotWindow(r, s));
      if (!covered && closestSlot(r).id == slot.id) {
        out.add(r);
      }
    }
  }
  return out;
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

bool sessionHasStarted(String dateKey, ScheduleSlot slot) {
  final start = _sessionStartAt(dateKey, slot);
  if (start == null) return false;
  return !DateTime.now().isBefore(start);
}

bool sessionHasEnded(String dateKey, ScheduleSlot slot) {
  final end = _sessionEndAt(dateKey, slot);
  if (end == null) return false;
  return DateTime.now().isAfter(end);
}

class SessionAttendanceTarget {
  const SessionAttendanceTarget({
    required this.group,
    required this.slot,
    required this.date,
  });

  final StudyGroup group;
  final ScheduleSlot slot;
  final String date;

  String sessionLabel(AppLocalizations l10n, {String? subjectName}) =>
      sessionSlotLabel(l10n, slot: slot, subjectName: subjectName);
}

enum SessionRowState {
  pending,
  notCheckedIn,
  present,
  late,
  absent,
  excused,
}

class SessionStudentRow {
  const SessionStudentRow({
    required this.studentId,
    required this.studentName,
    required this.state,
    required this.records,
    this.checkInAt,
    this.carriedFromPrevious = false,
  });

  final String studentId;
  final String studentName;
  final SessionRowState state;
  final List<AttendanceRecord> records;
  final DateTime? checkInAt;
  final bool carriedFromPrevious;
}

List<SessionStudentRow> rosterForSession({
  required SessionAttendanceTarget session,
  required List<ScheduleSlot> schedules,
  required List<Student> students,
  required List<AttendanceRecord> records,
}) {
  final group = session.group;
  final slot = session.slot;
  final dateKey = session.date;
  final effectiveSlots = effectiveSlotsForGroup(group, schedules);
  final prev = _previousConsecutiveSlot(slot, effectiveSlots);
  final started = sessionHasStarted(dateKey, slot);
  final ended = sessionHasEnded(dateKey, slot);

  final roster = students
      .where((s) => group.studentIds.contains(s.id))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  final dayRecords = records
      .where(
        (r) =>
            r.groupId == group.id &&
            r.date == dateKey &&
            group.studentIds.contains(r.studentId),
      )
      .toList();

  final attributed = recordsAttributedToSlot(
    slot: slot,
    groupSlots: effectiveSlots,
    dayRecords: dayRecords,
  );

  final byStudent = <String, List<AttendanceRecord>>{};
  for (final r in attributed) {
    byStudent.putIfAbsent(r.studentId, () => []).add(r);
  }

  return roster.map((student) {
    final recs = byStudent[student.id] ?? const <AttendanceRecord>[];
    var carried = false;

    if (recs.isNotEmpty) {
      final primary = recs.first;
      if (primary.checkInAt != null && prev != null) {
        carried = !_checkInInSlotWindow(primary, slot) &&
            _checkInInSlotWindow(primary, prev);
      }
      final status = bestAttendanceStatus(recs);
      final state = switch (status) {
        AttendanceStatus.present => SessionRowState.present,
        AttendanceStatus.late => SessionRowState.late,
        AttendanceStatus.absent => SessionRowState.absent,
        AttendanceStatus.excused => SessionRowState.excused,
      };
      final times = recs.map((r) => r.checkInAt).whereType<DateTime>().toList()
        ..sort();
      return SessionStudentRow(
        studentId: student.id,
        studentName: student.name,
        state: state,
        records: recs,
        checkInAt: times.isEmpty ? null : times.first,
        carriedFromPrevious: carried,
      );
    }

    final state = !started
        ? SessionRowState.pending
        : (!ended ? SessionRowState.notCheckedIn : SessionRowState.absent);

    return SessionStudentRow(
      studentId: student.id,
      studentName: student.name,
      state: state,
      records: const [],
    );
  }).toList();
}

List<ScheduleSlot> sessionSlotsForGroupOnDate({
  required StudyGroup group,
  required DateTime date,
  required List<ScheduleSlot> schedules,
}) {
  final weekday = date.weekday;
  return effectiveSlotsForGroup(group, schedules)
      .where((s) => s.weekday == weekday)
      .toList()
    ..sort(
      (a, b) =>
          _hhmmToMinutes(a.startTime).compareTo(_hhmmToMinutes(b.startTime)),
    );
}

List<SessionAttendanceTarget> sessionsOnDate({
  required DateTime date,
  required List<StudyGroup> groups,
  required List<ScheduleSlot> schedules,
}) {
  final dateKey = sessionDateKey(date);
  final weekday = date.weekday;
  final result = <SessionAttendanceTarget>[];
  for (final g in groups) {
    if (!_groupActiveOnDate(g, dateKey)) continue;
    for (final slot in effectiveSlotsForGroup(g, schedules)) {
      if (slot.weekday != weekday) continue;
      result.add(SessionAttendanceTarget(group: g, slot: slot, date: dateKey));
    }
  }
  result.sort((a, b) {
    final ta = _hhmmToMinutes(a.slot.startTime);
    final tb = _hhmmToMinutes(b.slot.startTime);
    if (ta != tb) return ta.compareTo(tb);
    return a.group.name.compareTo(b.group.name);
  });
  return result;
}

/// All weekly sessions (no date required). Uses nearest past weekday for attendance.
List<SessionAttendanceTarget> allWeeklySessions({
  required List<StudyGroup> groups,
  required List<ScheduleSlot> schedules,
  DateTime? anchor,
}) {
  final now = anchor ?? DateTime.now();
  final result = <SessionAttendanceTarget>[];
  for (final g in groups) {
    for (final slot in effectiveSlotsForGroup(g, schedules)) {
      final dateKey = referenceDateForSlot(now, slot);
      if (!_groupActiveOnDate(g, dateKey)) continue;
      result.add(SessionAttendanceTarget(group: g, slot: slot, date: dateKey));
    }
  }
  result.sort((a, b) {
    final w = a.slot.weekday.compareTo(b.slot.weekday);
    if (w != 0) return w;
    final ta = _hhmmToMinutes(a.slot.startTime);
    final tb = _hhmmToMinutes(b.slot.startTime);
    if (ta != tb) return ta.compareTo(tb);
    return a.group.name.compareTo(b.group.name);
  });
  return result;
}

List<SessionAttendanceTarget> filterSessions({
  required List<SessionAttendanceTarget> sessions,
  StudyGroup? group,
  ScheduleSlot? slot,
}) {
  return sessions.where((s) {
    if (group != null && s.group.id != group.id) return false;
    if (slot != null) {
      final sameGroup = s.slot.groupId == slot.groupId;
      final sameTime = s.slot.startTime == slot.startTime &&
          s.slot.endTime == slot.endTime &&
          s.slot.weekday == slot.weekday;
      if (!sameGroup || !sameTime) return false;
    }
    return true;
  }).toList();
}

/// Every calendar occurrence of a weekly slot within the group period (+ record days).
List<SessionAttendanceTarget> sessionOccurrencesAcrossDates({
  required StudyGroup group,
  required ScheduleSlot slot,
  required List<AttendanceRecord> records,
}) {
  final dates = <String>{};
  final today = DateTime.now();
  final todayKey = sessionDateKey(today);

  final start = DateTime.tryParse(group.startDate ?? '');
  var end = DateTime.tryParse(group.endDate ?? '');
  // Always include up to today so past sessions stay visible even if period ends earlier.
  if (end == null || end.isBefore(DateTime(today.year, today.month, today.day))) {
    end = DateTime(today.year, today.month, today.day);
  }

  if (start != null && !end.isBefore(start)) {
    for (var d = DateTime(start.year, start.month, start.day);
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      if (d.weekday == slot.weekday) dates.add(sessionDateKey(d));
    }
  } else {
    // No period saved: last 12 weeks of this weekday (incl. today if matches).
    for (var i = 0; i < 84; i++) {
      final d = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      if (d.weekday == slot.weekday) dates.add(sessionDateKey(d));
    }
  }

  for (final r in records) {
    if (r.groupId != group.id) continue;
    final day = DateTime.tryParse(r.date);
    if (day == null || day.weekday != slot.weekday) continue;
    dates.add(r.date);
  }

  // Keep only dates up to today for the overview (past + current).
  final pastOrToday = dates.where((d) => d.compareTo(todayKey) <= 0).toSet();
  if (pastOrToday.isEmpty) {
    pastOrToday.add(referenceDateForSlot(today, slot));
  }

  final sorted = pastOrToday.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final date in sorted)
      SessionAttendanceTarget(group: group, slot: slot, date: date),
  ];
}

/// All slots of a group expanded across every past/current session date.
List<SessionAttendanceTarget> groupSessionsAcrossDates({
  required StudyGroup group,
  required List<ScheduleSlot> schedules,
  required List<AttendanceRecord> records,
}) {
  final result = <SessionAttendanceTarget>[];
  for (final slot in effectiveSlotsForGroup(group, schedules)) {
    result.addAll(
      sessionOccurrencesAcrossDates(
        group: group,
        slot: slot,
        records: records,
      ),
    );
  }
  result.sort((a, b) {
    final d = b.date.compareTo(a.date);
    if (d != 0) return d;
    final ta = _hhmmToMinutes(a.slot.startTime);
    final tb = _hhmmToMinutes(b.slot.startTime);
    if (ta != tb) return ta.compareTo(tb);
    return a.group.name.compareTo(b.group.name);
  });
  return result;
}

class SessionStateChip extends StatelessWidget {
  const SessionStateChip({
    super.key,
    required this.state,
    this.carried = false,
  });

  final SessionRowState state;
  final bool carried;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final (label, color) = switch (state) {
      SessionRowState.pending => (
          l10n.sessionNotStartedYet,
          theme.colorScheme.outline,
        ),
      SessionRowState.notCheckedIn => (
          l10n.notCheckedInYet,
          AppColors.info,
        ),
      SessionRowState.present => (
          carried
              ? '${l10n.statusPresent} (${l10n.carriedFromPreviousSession})'
              : l10n.statusPresent,
          AppColors.success,
        ),
      SessionRowState.late => (l10n.statusLate, AppColors.warning),
      SessionRowState.absent => (l10n.statusAbsent, AppColors.danger),
      SessionRowState.excused => (l10n.statusExcused, AppColors.info),
    };

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
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class SessionRosterTable extends StatelessWidget {
  const SessionRosterTable({
    super.key,
    required this.rows,
    required this.timeFormat,
    this.onEdit,
    this.onDelete,
  });

  final List<SessionStudentRow> rows;
  final DateFormat timeFormat;
  final void Function(AttendanceRecord)? onEdit;
  final Future<void> Function(List<AttendanceRecord>)? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 52,
            columnSpacing: 24,
            headingTextStyle:
                theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            columns: [
              DataColumn(label: Text(l10n.student)),
              DataColumn(label: Text(l10n.status)),
              DataColumn(label: Text(l10n.checkIn)),
              DataColumn(label: Text(l10n.punches)),
              if (onEdit != null || onDelete != null)
                const DataColumn(label: Text('')),
            ],
            rows: [
              for (final row in rows)
                DataRow(
                  cells: [
                    DataCell(Text(row.studentName)),
                    DataCell(
                      SessionStateChip(
                        state: row.state,
                        carried: row.carriedFromPrevious,
                      ),
                    ),
                    DataCell(
                      Text(
                        row.checkInAt == null
                            ? kSessionEmptyCell
                            : timeFormat.format(row.checkInAt!.toLocal()),
                      ),
                    ),
                    DataCell(
                      Text(
                        row.records.isEmpty
                            ? kSessionEmptyCell
                            : l10n.punchesCount(
                                row.records
                                    .where((r) => r.checkInAt != null)
                                    .length,
                              ),
                      ),
                    ),
                    if (onEdit != null || onDelete != null)
                      DataCell(
                        row.records.isEmpty
                            ? const SizedBox.shrink()
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (onEdit != null)
                                    IconButton(
                                      tooltip: l10n.editAttendance,
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
                                      onPressed: () => onEdit!(row.records.first),
                                    ),
                                  if (onDelete != null)
                                    IconButton(
                                      tooltip: l10n.delete,
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: theme.colorScheme.error,
                                      ),
                                      onPressed: () => onDelete!(row.records),
                                    ),
                                ],
                              ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SessionsOverviewTable extends StatelessWidget {
  const SessionsOverviewTable({
    super.key,
    required this.sessions,
    required this.subjectName,
    required this.schedules,
    required this.students,
    required this.records,
    required this.onSelect,
    this.showDateColumn = true,
  });

  final List<SessionAttendanceTarget> sessions;
  final Map<String, String> subjectName;
  final List<ScheduleSlot> schedules;
  final List<Student> students;
  final List<AttendanceRecord> records;
  final ValueChanged<SessionAttendanceTarget> onSelect;
  final bool showDateColumn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (sessions.isEmpty) {
      return Center(
        child: Text(
          l10n.noSessionsOnDate,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowHeight: 48,
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 64,
                  columnSpacing: 28,
                  headingTextStyle: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                  columns: [
                    DataColumn(label: Text(l10n.sessionNumber)),
                    if (showDateColumn) DataColumn(label: Text(l10n.date)),
                    DataColumn(label: Text(l10n.sessionTime)),
                    DataColumn(label: Text(l10n.group)),
                    DataColumn(label: Text(l10n.studentsCount)),
                    DataColumn(label: Text(l10n.statusPresent)),
                    DataColumn(label: Text(l10n.statusLate)),
                    DataColumn(label: Text(l10n.statusAbsent)),
                  ],
                  rows: [
                    for (var i = 0; i < sessions.length; i++)
                      () {
                        final session = sessions[i];
                        final subj = subjectNameForSlot(
                          session.slot,
                          session.group,
                          subjectName,
                        );
                        final rows = rosterForSession(
                          session: session,
                          schedules: schedules,
                          students: students,
                          records: records,
                        );
                        final presentN = rows
                            .where((r) => r.state == SessionRowState.present)
                            .length;
                        final lateN = rows
                            .where((r) => r.state == SessionRowState.late)
                            .length;
                        final absentN = rows
                            .where(
                              (r) =>
                                  r.state == SessionRowState.absent ||
                                  r.state == SessionRowState.notCheckedIn,
                            )
                            .length;
                        return DataRow(
                          onSelectChanged: (_) => onSelect(session),
                          cells: [
                            DataCell(Text('${i + 1}')),
                            if (showDateColumn) DataCell(Text(session.date)),
                            DataCell(
                              Text(
                                session.sessionLabel(
                                  l10n,
                                  subjectName: subj,
                                ),
                              ),
                            ),
                            DataCell(Text(session.group.name)),
                            DataCell(Text('${rows.length}')),
                            DataCell(
                              Text(
                                '$presentN',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '$lateN',
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '$absentN',
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                ),
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

ScheduleSlot? slotForRecord(
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

String _statusLabel(AppLocalizations l10n, AttendanceStatus status) {
  return switch (status) {
    AttendanceStatus.present => l10n.statusPresent,
    AttendanceStatus.late => l10n.statusLate,
    AttendanceStatus.absent => l10n.statusAbsent,
    AttendanceStatus.excused => l10n.statusExcused,
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

/// Full student ledger across all groups and sessions (ignores session filters).
class StudentHistoryPanel extends StatelessWidget {
  const StudentHistoryPanel({
    super.key,
    required this.students,
    required this.selectedId,
    required this.records,
    required this.groups,
    required this.groupName,
    required this.subjectName,
    required this.schedules,
    required this.timeFormat,
    this.onEdit,
    this.onDelete,
  });

  final List<Student> students;
  final String? selectedId;
  final List<AttendanceRecord> records;
  final List<StudyGroup> groups;
  final Map<String, String> groupName;
  final Map<String, String> subjectName;
  final List<ScheduleSlot> schedules;
  final DateFormat timeFormat;
  final void Function(AttendanceRecord)? onEdit;
  final Future<void> Function(List<AttendanceRecord>)? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final sid = selectedId != null && students.any((s) => s.id == selectedId)
        ? selectedId!
        : null;
    if (sid == null) {
      return Center(child: Text(l10n.noHistoryForStudent));
    }

    final studentName =
        students.where((s) => s.id == sid).map((s) => s.name).firstOrNull ?? sid;
    final groupById = {for (final g in groups) g.id: g};
    final mine = records.where((r) => r.studentId == sid).toList();
    final keyed = <String, List<AttendanceRecord>>{};
    for (final r in mine) {
      keyed.putIfAbsent('${r.date}|${r.groupId ?? ''}', () => []).add(r);
    }

    final sessions = keyed.entries.map((e) {
      final list = List<AttendanceRecord>.from(e.value);
      final primary = list.first;
      final slot = slotForRecord(primary, schedules);
      final group = primary.groupId == null ? null : groupById[primary.groupId];
      final subj = slot == null || group == null
          ? (group == null ? null : subjectName[group.subjectId])
          : subjectNameForSlot(slot, group, subjectName);
      final punches = list.where((r) => r.checkInAt != null).length;
      final checkIns = list.map((r) => r.checkInAt).whereType<DateTime>().toList()
        ..sort();
      return (
        date: primary.date,
        groupId: primary.groupId,
        subjectName: subj,
        status: bestAttendanceStatus(list),
        punches: punches,
        checkIns: checkIns,
        slot: slot,
        all: list,
        primary: primary,
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (sessions.isEmpty) {
      return Center(child: Text(l10n.noHistoryForStudent));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$studentName · ${l10n.studentHistory}',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = sessions[i];
              final gName = s.groupId == null
                  ? l10n.ungroupedSession
                  : (groupName[s.groupId] ?? s.groupId!);
              final scheduleText = s.slot == null
                  ? kSessionEmptyCell
                  : sessionSlotLabel(
                      l10n,
                      slot: s.slot!,
                      subjectName: s.subjectName,
                    );
              final checkInText = s.checkIns.isEmpty
                  ? kSessionEmptyCell
                  : s.checkIns
                      .map((t) => timeFormat.format(t.toLocal()))
                      .join(', ');
              final color = _statusColor(s.status);

              return DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$gName · ${s.date}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(l10n, s.status),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (onEdit != null)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => onEdit!(s.primary),
                            ),
                          if (onDelete != null)
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: () => onDelete!(s.all),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        scheduleText,
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${l10n.punchesCount(s.punches)} · ${l10n.checkIn}: $checkInText',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
