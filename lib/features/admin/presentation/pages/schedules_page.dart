import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/crud_list_cubit.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/responsive_data_table.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/searchable_select.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

Map<int, String> _weekdayLabels(AppLocalizations l10n) => {
      1: l10n.monday,
      2: l10n.tuesday,
      3: l10n.wednesday,
      4: l10n.thursday,
      5: l10n.friday,
      6: l10n.saturday,
      7: l10n.sunday,
    };

class SchedulesPage extends StatelessWidget {
  const SchedulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CrudListCubit<ScheduleSlot>(
            watch: repo.watchSchedules,
            save: repo.saveSchedule,
            remove: repo.deleteSchedule,
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
      ],
      child: const _SchedulesView(),
    );
  }
}

class _SchedulesView extends StatelessWidget {
  const _SchedulesView();

  Future<void> _openForm(
    BuildContext context, {
    ScheduleSlot? existing,
    required List<StudyGroup> groups,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addGroupFirst)),
      );
      return;
    }
    var groupId = existing?.groupId ?? groups.first.id;
    var weekday = existing?.weekday ?? 1;
    final startCtrl =
        TextEditingController(text: existing?.startTime ?? '16:00');
    final endCtrl =
        TextEditingController(text: existing?.endTime ?? '18:00');
    final formKey = GlobalKey<FormState>();
    final weekdays = _weekdayLabels(l10n);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title: Text(
                existing == null ? l10n.addSchedule : l10n.editSchedule,
              ),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SearchableSelectField<StudyGroup>(
                        label: l10n.group,
                        value: groups.cast<StudyGroup?>().firstWhere(
                              (g) => g?.id == groupId,
                              orElse: () => groups.first,
                            ),
                        labelOf: (g) => g.name,
                        onSearch: (q) => searchableLocalFilter(
                          items: groups,
                          query: q,
                          labelOf: (g) => g.name,
                        ),
                        onChanged: (g) =>
                            setState(() => groupId = g?.id ?? groupId),
                      ),
                      const SizedBox(height: 12),
                      SearchableSelectField<int>(
                        label: l10n.day,
                        value: weekday,
                        labelOf: (d) => weekdays[d] ?? '$d',
                        onSearch: (q) => searchableLocalFilter(
                          items: weekdays.keys.toList(),
                          query: q,
                          labelOf: (d) => weekdays[d] ?? '$d',
                        ),
                        onChanged: (v) =>
                            setState(() => weekday = v ?? weekday),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: startCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.fromTime,
                        ),
                        validator: (v) => (v == null || !v.contains(':'))
                            ? l10n.timeRequired
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: endCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.toTime,
                        ),
                        validator: (v) => (v == null || !v.contains(':'))
                            ? l10n.timeRequired
                            : null,
                      ),
                    ],
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
                    context.read<CrudListCubit<ScheduleSlot>>().save(
                          ScheduleSlot(
                            id: existing?.id ?? '',
                            groupId: groupId,
                            weekday: weekday,
                            startTime: startCtrl.text.trim(),
                            endTime: endCtrl.text.trim(),
                            branchId:
                                existing?.branchId ?? AppDefaults.branchId,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final weekdays = _weekdayLabels(l10n);
    final groups =
        [...?context.watch<CrudListCubit<StudyGroup>>().state.items];
    final groupName = {for (final g in groups) g.id: g.name};

    return AdminPageFrame(
      title: l10n.weeklySchedule,
      onAdd: () => _openForm(context, groups: groups),
      child:
          BlocBuilder<CrudListCubit<ScheduleSlot>, CrudListState<ScheduleSlot>>(
        builder: (context, state) {
          if (state.isLoading && state.items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = [...?state.items]
            ..sort((a, b) => a.weekday.compareTo(b.weekday));
          return ResponsiveDataTable(
            columns: [
              DataColumnSpec(l10n.group),
              DataColumnSpec(l10n.day),
              DataColumnSpec(l10n.from),
              DataColumnSpec(l10n.to),
            ],
            rowCount: items.length,
            cellBuilder: (r, c) {
              final s = items[r];
              return switch (c) {
                0 => groupName[s.groupId] ?? s.groupId,
                1 => weekdays[s.weekday] ?? '${s.weekday}',
                2 => s.startTime,
                _ => s.endTime,
              };
            },
            mobileTitleBuilder: (r) =>
                groupName[items[r].groupId] ?? items[r].groupId,
            mobileSubtitleBuilder: (r) =>
                '${weekdays[items[r].weekday]} · ${items[r].startTime}-${items[r].endTime}',
            onEdit: (r) =>
                _openForm(context, existing: items[r], groups: groups),
            onDelete: (r) async {
              final label =
                  '${groupName[items[r].groupId]} ${weekdays[items[r].weekday]}';
              final ok = await confirmDelete(context, label);
              if (!context.mounted || !ok) return;
              context.read<CrudListCubit<ScheduleSlot>>().delete(items[r]);
            },
          );
        },
      ),
    );
  }
}
