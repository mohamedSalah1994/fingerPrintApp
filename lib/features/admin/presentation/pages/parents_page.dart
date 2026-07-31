import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/crud_list_cubit.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/responsive_data_table.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class ParentsPage extends StatelessWidget {
  const ParentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CrudListCubit<ParentProfile>(
            watch: repo.watchParents,
            save: repo.saveParent,
            remove: repo.deleteParent,
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
      ],
      child: const _ParentsView(),
    );
  }
}

class _ParentsView extends StatelessWidget {
  const _ParentsView();

  Future<void> _openForm(BuildContext context, {ParentProfile? existing}) async {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final formKey = GlobalKey<FormState>();

    await showEntityFormDialog(
      context: context,
      title: existing == null ? l10n.addParent : l10n.editParent,
      formKey: formKey,
      form: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameCtrl,
            decoration: InputDecoration(labelText: l10n.name),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phoneCtrl,
            decoration: InputDecoration(labelText: l10n.phoneWhatsapp),
          ),
        ],
      ),
      onSave: () {
        context.read<CrudListCubit<ParentProfile>>().save(
              ParentProfile(
                id: existing?.id ?? '',
                name: nameCtrl.text.trim(),
                branchId: existing?.branchId ?? AppDefaults.branchId,
                phone: phoneCtrl.text.trim().isEmpty
                    ? null
                    : phoneCtrl.text.trim(),
                studentIds: existing?.studentIds ?? const [],
                userId: existing?.userId,
              ),
            );
      },
    );
  }

  Future<void> _manageChildren(
    BuildContext context, {
    required ParentProfile parent,
    required List<Student> allStudents,
  }) async {
    final l10n = AppLocalizations.of(context);
    final studentMap = {for (final s in allStudents) s.id: s};
    final available = allStudents
        .where((s) => !parent.studentIds.contains(s.id))
        .toList();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.manageChildren(parent.name)),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.linkedStudents,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (parent.studentIds.isEmpty)
                    Text(l10n.noChildrenYet)
                  else
                    ...parent.studentIds.map((id) {
                      final student = studentMap[id];
                      final name = student?.name ?? id;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.school_outlined),
                        title: Text(name),
                        trailing: IconButton(
                          tooltip: l10n.unlink,
                          icon: Icon(
                            Icons.link_off,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () async {
                            if (student == null) return;
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
                    l10n.addStudent,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (available.isEmpty)
                    Text(l10n.allStudentsLinked)
                  else
                    ...available.map((student) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_add_alt_1_outlined),
                        title: Text(student.name),
                        subtitle: Text(student.phone ?? ''),
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
                                        student.name,
                                        parent.name,
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
    final students =
        [...?context.watch<CrudListCubit<Student>>().state.items];
    final studentName = {for (final s in students) s.id: s.name};

    return AdminPageFrame(
      title: l10n.parents,
      onAdd: () => _openForm(context),
      child: BlocBuilder<CrudListCubit<ParentProfile>,
          CrudListState<ParentProfile>>(
        builder: (context, state) {
          if (state.isLoading && state.items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.items ?? [];
          return ResponsiveDataTable(
            columns: [
              DataColumnSpec(l10n.name),
              DataColumnSpec(l10n.phone),
              DataColumnSpec(l10n.children),
            ],
            rowCount: items.length,
            cellBuilder: (r, c) {
              final p = items[r];
              return switch (c) {
                0 => p.name,
                1 => p.phone ?? '—',
                _ => p.studentIds.isEmpty
                    ? l10n.noChildren
                    : p.studentIds
                        .map((id) => studentName[id] ?? id)
                        .join('، '),
              };
            },
            mobileTitleBuilder: (r) => items[r].name,
            mobileSubtitleBuilder: (r) {
              final p = items[r];
              final kids = p.studentIds.isEmpty
                  ? l10n.noChildrenShort
                  : p.studentIds.map((id) => studentName[id] ?? id).join('، ');
              return '${p.phone ?? '—'} · $kids';
            },
            onLink: (r) => _manageChildren(
              context,
              parent: items[r],
              allStudents: students,
            ),
            onEdit: (r) => _openForm(context, existing: items[r]),
            onDelete: (r) async {
              final ok = await confirmDelete(context, items[r].name);
              if (!context.mounted || !ok) return;
              context.read<CrudListCubit<ParentProfile>>().delete(items[r]);
            },
            emptyMessage: l10n.parentsEmptyHint,
          );
        },
      ),
    );
  }
}
