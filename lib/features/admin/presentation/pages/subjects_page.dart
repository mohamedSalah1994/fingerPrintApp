import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/crud_list_cubit.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/responsive_data_table.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/searchable_select.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CrudListCubit<Subject>(
            watch: repo.watchSubjects,
            save: repo.saveSubject,
            remove: repo.deleteSubject,
            idOf: (e) => e.id,
          ),
        ),
        BlocProvider(
          create: (_) => CrudListCubit<Stage>(
            watch: repo.watchStages,
            save: repo.saveStage,
            remove: repo.deleteStage,
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
      ],
      child: const _SubjectsView(),
    );
  }
}

enum _SubjectScope { grade, stage }

class _SubjectsView extends StatelessWidget {
  const _SubjectsView();

  Future<void> _openForm(
    BuildContext context, {
    Subject? existing,
    required List<Stage> stages,
    required List<Grade> grades,
  }) async {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<AdminRepository>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    var scope = existing?.gradeId != null && existing!.gradeId!.isNotEmpty
        ? _SubjectScope.grade
        : (existing?.stageId != null
            ? _SubjectScope.stage
            : _SubjectScope.grade);
    String? gradeId = existing?.gradeId ??
        (grades.isNotEmpty ? grades.first.id : null);
    String? stageId = existing?.stageId ??
        (stages.isNotEmpty ? stages.first.id : null);
    final formKey = GlobalKey<FormState>();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title:
                  Text(existing == null ? l10n.addSubject : l10n.editSubject),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration:
                            InputDecoration(labelText: l10n.subjectName),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.required
                            : null,
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<_SubjectScope>(
                        segments: [
                          ButtonSegment(
                            value: _SubjectScope.grade,
                            label: Text(l10n.subjectScopeGrade),
                          ),
                          ButtonSegment(
                            value: _SubjectScope.stage,
                            label: Text(l10n.subjectScopeStage),
                          ),
                        ],
                        selected: {scope},
                        onSelectionChanged: existing != null
                            ? null
                            : (s) => setState(() => scope = s.first),
                      ),
                      const SizedBox(height: 12),
                      if (scope == _SubjectScope.grade)
                        SearchableSelectField<Grade>(
                          label: l10n.grade,
                          value: grades.cast<Grade?>().firstWhere(
                                (g) => g?.id == gradeId,
                                orElse: () =>
                                    grades.isEmpty ? null : grades.first,
                              ),
                          labelOf: (g) => g.name,
                          onSearch: (q) => searchableLocalFilter(
                            items: grades,
                            query: q,
                            labelOf: (g) => g.name,
                          ),
                          onChanged: (g) => setState(() => gradeId = g?.id),
                        )
                      else
                        SearchableSelectField<Stage>(
                          label: l10n.stages,
                          value: stages.cast<Stage?>().firstWhere(
                                (s) => s?.id == stageId,
                                orElse: () =>
                                    stages.isEmpty ? null : stages.first,
                              ),
                          labelOf: (s) => s.name,
                          onSearch: (q) => searchableLocalFilter(
                            items: stages,
                            query: q,
                            labelOf: (s) => s.name,
                          ),
                          onChanged: (s) => setState(() => stageId = s?.id),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setState(() => saving = true);
                          try {
                            await repo.saveSubjectScoped(
                              id: existing?.id,
                              name: nameCtrl.text.trim(),
                              branchId:
                                  existing?.branchId ?? AppDefaults.branchId,
                              gradeId: scope == _SubjectScope.grade
                                  ? gradeId
                                  : (existing?.gradeId),
                              stageId: scope == _SubjectScope.stage
                                  ? stageId
                                  : (grades
                                      .cast<Grade?>()
                                      .firstWhere(
                                        (g) => g?.id == gradeId,
                                        orElse: () => null,
                                      )
                                      ?.stageId),
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            setState(() => saving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
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
    final stages = [...?context.watch<CrudListCubit<Stage>>().state.items];
    final grades = [...?context.watch<CrudListCubit<Grade>>().state.items];
    final stageName = {for (final s in stages) s.id: s.name};
    final gradeName = {for (final g in grades) g.id: g.name};

    return AdminPageFrame(
      title: l10n.subjectsTitle,
      onAdd: () => _openForm(context, stages: stages, grades: grades),
      child: BlocBuilder<CrudListCubit<Subject>, CrudListState<Subject>>(
        builder: (context, state) {
          if (state.isLoading && state.items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.items ?? [];
          return ResponsiveDataTable(
            columns: [
              DataColumnSpec(l10n.subjects),
              DataColumnSpec(l10n.grade),
              DataColumnSpec(l10n.stages),
            ],
            rowCount: items.length,
            cellBuilder: (r, c) {
              final s = items[r];
              return switch (c) {
                0 => s.name,
                1 => s.gradeId == null
                    ? '—'
                    : (gradeName[s.gradeId] ?? s.gradeId!),
                _ => s.stageId == null
                    ? '—'
                    : (stageName[s.stageId] ?? s.stageId!),
              };
            },
            mobileTitleBuilder: (r) => items[r].name,
            mobileSubtitleBuilder: (r) {
              final s = items[r];
              final g = s.gradeId == null
                  ? ''
                  : (gradeName[s.gradeId] ?? s.gradeId!);
              final st = s.stageId == null
                  ? ''
                  : (stageName[s.stageId] ?? s.stageId!);
              return [g, st].where((e) => e.isNotEmpty).join(' · ');
            },
            onEdit: (r) => _openForm(
              context,
              existing: items[r],
              stages: stages,
              grades: grades,
            ),
            onDelete: (r) async {
              final ok = await confirmDelete(context, items[r].name);
              if (!context.mounted || !ok) return;
              context.read<CrudListCubit<Subject>>().delete(items[r]);
            },
          );
        },
      ),
    );
  }
}
