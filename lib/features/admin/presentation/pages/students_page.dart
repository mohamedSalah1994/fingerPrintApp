import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/crud_list_cubit.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/responsive_data_table.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/searchable_select.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CrudListCubit<Student>(
            watch: repo.watchStudents,
            save: repo.saveStudent,
            remove: repo.deleteStudent,
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
          create: (_) => CrudListCubit<ParentProfile>(
            watch: repo.watchParents,
            save: repo.saveParent,
            remove: repo.deleteParent,
            idOf: (e) => e.id,
          ),
        ),
      ],
      child: const _StudentsView(),
    );
  }
}

class _StudentsView extends StatelessWidget {
  const _StudentsView();

  Future<void> _openForm(
    BuildContext context, {
    Student? existing,
    required List<Grade> grades,
    required List<Subject> subjects,
    required List<ParentProfile> parents,
  }) async {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<AdminRepository>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final parentNameCtrl = TextEditingController();
    final parentPhoneCtrl = TextEditingController();
    String? gradeId = existing?.gradeId;
    var enrollmentType = existing?.enrollmentType ?? EnrollmentType.full;
    final selectedSubjects = {...existing?.subjectIds ?? const <String>[]};
    String? linkParentId;
    var addNewParent = existing == null;
    final formKey = GlobalKey<FormState>();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            final gradeSubjects = subjects
                .where(
                  (s) =>
                      gradeId == null ||
                      s.gradeId == null ||
                      s.gradeId == gradeId,
                )
                .toList();

            return AlertDialog(
              title:
                  Text(existing == null ? l10n.addStudent : l10n.editStudent),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          decoration: InputDecoration(labelText: l10n.name),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.required
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneCtrl,
                          decoration: InputDecoration(labelText: l10n.phone),
                        ),
                        const SizedBox(height: 12),
                        SearchableSelectField<Grade>(
                          label: l10n.grade,
                          value: grades.cast<Grade?>().firstWhere(
                                (g) => g?.id == gradeId,
                                orElse: () => null,
                              ),
                          labelOf: (g) => g.name,
                          onSearch: (q) => searchableLocalFilter(
                            items: grades,
                            query: q,
                            labelOf: (g) => g.name,
                          ),
                          onChanged: (g) => setState(() {
                            gradeId = g?.id;
                            selectedSubjects.clear();
                          }),
                          allowClear: true,
                          clearLabel: l10n.unspecified,
                        ),
                        if (gradeId != null) ...[
                          const SizedBox(height: 12),
                          SegmentedButton<EnrollmentType>(
                            segments: [
                              ButtonSegment(
                                value: EnrollmentType.full,
                                label: Text(l10n.allSubjectsOption),
                              ),
                              ButtonSegment(
                                value: EnrollmentType.partial,
                                label: Text(l10n.selectedSubjectsOption),
                              ),
                            ],
                            selected: {enrollmentType},
                            onSelectionChanged: (s) => setState(
                              () => enrollmentType = s.first,
                            ),
                          ),
                          if (enrollmentType == EnrollmentType.partial) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: gradeSubjects.map((s) {
                                final selected =
                                    selectedSubjects.contains(s.id);
                                return FilterChip(
                                  label: Text(s.name),
                                  selected: selected,
                                  onSelected: (v) => setState(() {
                                    if (v) {
                                      selectedSubjects.add(s.id);
                                    } else {
                                      selectedSubjects.remove(s.id);
                                    }
                                  }),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                        if (existing == null) ...[
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.addParentInline),
                            value: addNewParent,
                            onChanged: (v) =>
                                setState(() => addNewParent = v),
                          ),
                          if (addNewParent) ...[
                            TextFormField(
                              controller: parentNameCtrl,
                              decoration:
                                  InputDecoration(labelText: l10n.parentName),
                              validator: (v) {
                                if (!addNewParent) return null;
                                if (v == null || v.trim().isEmpty) {
                                  return l10n.required;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: parentPhoneCtrl,
                              decoration:
                                  InputDecoration(labelText: l10n.parentPhone),
                            ),
                          ] else ...[
                            SearchableSelectField<ParentProfile>(
                              label: l10n.orLinkExistingParent,
                              value: parents.cast<ParentProfile?>().firstWhere(
                                    (p) => p?.id == linkParentId,
                                    orElse: () => null,
                                  ),
                              labelOf: (p) =>
                                  '${p.name}${p.phone == null ? '' : ' · ${p.phone}'}',
                              onSearch: (q) => searchableLocalFilter(
                                items: parents,
                                query: q,
                                labelOf: (p) => p.name,
                              ),
                              onChanged: (p) =>
                                  setState(() => linkParentId = p?.id),
                              allowClear: true,
                              clearLabel: l10n.unspecified,
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
                  onPressed:
                      saving ? null : () => Navigator.pop(dialogContext),
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
                            final student = Student(
                              id: existing?.id ?? '',
                              name: nameCtrl.text.trim(),
                              branchId:
                                  existing?.branchId ?? AppDefaults.branchId,
                              phone: phoneCtrl.text.trim().isEmpty
                                  ? null
                                  : phoneCtrl.text.trim(),
                              gradeId: gradeId,
                              parentIds: existing?.parentIds ?? const [],
                              subjectIds:
                                  enrollmentType == EnrollmentType.partial
                                      ? selectedSubjects.toList()
                                      : const [],
                              enrollmentType: enrollmentType,
                              userId: existing?.userId,
                              status: existing?.status ?? 'active',
                            );
                            await repo.saveStudentWithDetails(
                              student: student,
                              newParent: (existing == null && addNewParent)
                                  ? ParentProfile(
                                      id: '',
                                      name: parentNameCtrl.text.trim(),
                                      branchId: AppDefaults.branchId,
                                      phone:
                                          parentPhoneCtrl.text.trim().isEmpty
                                              ? null
                                              : parentPhoneCtrl.text.trim(),
                                    )
                                  : null,
                              linkExistingParentId:
                                  (existing == null && !addNewParent)
                                      ? linkParentId
                                      : null,
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
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _manageParents(
    BuildContext context, {
    required Student student,
    required List<ParentProfile> allParents,
  }) async {
    final l10n = AppLocalizations.of(context);
    final parentMap = {for (final p in allParents) p.id: p};
    final available =
        allParents.where((p) => !student.parentIds.contains(p.id)).toList();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.manageParents(student.name)),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.currentlyLinked,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (student.parentIds.isEmpty)
                    Text(l10n.noParentLinked)
                  else
                    ...student.parentIds.map((id) {
                      final parent = parentMap[id];
                      final name = parent?.name ?? id;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.family_restroom),
                        title: Text(name),
                        subtitle: Text(parent?.phone ?? ''),
                        trailing: IconButton(
                          tooltip: l10n.unlink,
                          icon: Icon(
                            Icons.link_off,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () async {
                            if (parent == null) return;
                            try {
                              await context
                                  .read<AdminRepository>()
                                  .unlinkParentStudent(
                                    parentId: parent.id,
                                    studentId: student.id,
                                    parent: parent,
                                    student: student,
                                  );
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.unlinkFailed('$e')),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      );
                    }),
                  const Divider(height: 24),
                  Text(
                    l10n.linkParent,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (available.isEmpty)
                    Text(l10n.noParentsAvailable)
                  else
                    ...available.map((parent) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_add_alt_1_outlined),
                        title: Text(parent.name),
                        subtitle: Text(parent.phone ?? ''),
                        trailing: FilledButton.tonal(
                          onPressed: () async {
                            try {
                              await context
                                  .read<AdminRepository>()
                                  .linkParentStudent(
                                    parentId: parent.id,
                                    studentId: student.id,
                                    parent: parent,
                                    student: student,
                                  );
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.linkFailed('$e')),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(l10n.link),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.close),
            ),
          ],
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
    final parents =
        [...?context.watch<CrudListCubit<ParentProfile>>().state.items];
    final gradeName = {for (final g in grades) g.id: g.name};
    final parentName = {for (final p in parents) p.id: p.name};

    return AdminPageFrame(
      title: l10n.students,
      onAdd: () => _openForm(
        context,
        grades: grades,
        subjects: subjects,
        parents: parents,
      ),
      child: BlocBuilder<CrudListCubit<Student>, CrudListState<Student>>(
        builder: (context, state) {
          if (state.isLoading && state.items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.items ?? [];
          return ResponsiveDataTable(
            columns: [
              DataColumnSpec(l10n.name),
              DataColumnSpec(l10n.phone),
              DataColumnSpec(l10n.grade),
              DataColumnSpec(l10n.parentGuardian),
            ],
            rowCount: items.length,
            cellBuilder: (r, c) {
              final s = items[r];
              return switch (c) {
                0 => s.name,
                1 => s.phone ?? '—',
                2 => s.gradeId == null
                    ? '—'
                    : (gradeName[s.gradeId] ?? s.gradeId!),
                _ => s.parentIds.isEmpty
                    ? l10n.noParent
                    : s.parentIds
                        .map((id) => parentName[id] ?? id)
                        .join('، '),
              };
            },
            mobileTitleBuilder: (r) => items[r].name,
            mobileSubtitleBuilder: (r) {
              final s = items[r];
              final parentsLabel = s.parentIds.isEmpty
                  ? l10n.withoutParent
                  : s.parentIds.map((id) => parentName[id] ?? id).join('، ');
              return '${s.phone ?? '—'} · $parentsLabel';
            },
            onOpen: (r) => context.go('/admin/students/${items[r].id}'),
            onLink: (r) => _manageParents(
              context,
              student: items[r],
              allParents: parents,
            ),
            onEdit: (r) => _openForm(
              context,
              existing: items[r],
              grades: grades,
              subjects: subjects,
              parents: parents,
            ),
            onDelete: (r) async {
              final ok = await confirmDelete(context, items[r].name);
              if (!context.mounted || !ok) return;
              context.read<CrudListCubit<Student>>().delete(items[r]);
            },
          );
        },
      ),
    );
  }
}
