import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/crud_list_cubit.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/responsive_data_table.dart';
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
  }) async {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    String? gradeId = existing?.gradeId;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title:
                  Text(existing == null ? l10n.addStudent : l10n.editStudent),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
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
                      DropdownButtonFormField<String?>(
                        value: gradeId,
                        decoration: InputDecoration(labelText: l10n.grade),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(l10n.unspecified),
                          ),
                          for (final g in grades)
                            DropdownMenuItem(
                              value: g.id,
                              child: Text(g.name),
                            ),
                        ],
                        onChanged: (v) => setState(() => gradeId = v),
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
                    context.read<CrudListCubit<Student>>().save(
                          Student(
                            id: existing?.id ?? '',
                            name: nameCtrl.text.trim(),
                            branchId:
                                existing?.branchId ?? AppDefaults.branchId,
                            phone: phoneCtrl.text.trim().isEmpty
                                ? null
                                : phoneCtrl.text.trim(),
                            gradeId: gradeId,
                            parentIds: existing?.parentIds ?? const [],
                            userId: existing?.userId,
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
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.unlinkedNamed(name)),
                                  ),
                                );
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
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.linkedNamed(
                                        parent.name,
                                        student.name,
                                      ),
                                    ),
                                  ),
                                );
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
    final parents =
        [...?context.watch<CrudListCubit<ParentProfile>>().state.items];
    final gradeName = {for (final g in grades) g.id: g.name};
    final parentName = {for (final p in parents) p.id: p.name};

    return AdminPageFrame(
      title: l10n.students,
      onAdd: () => _openForm(context, grades: grades),
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
            onLink: (r) => _manageParents(
              context,
              student: items[r],
              allParents: parents,
            ),
            onEdit: (r) =>
                _openForm(context, existing: items[r], grades: grades),
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
