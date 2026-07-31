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
      ],
      child: const _GroupsView(),
    );
  }
}

class _GroupsView extends StatelessWidget {
  const _GroupsView();

  Future<void> _openForm(
    BuildContext context, {
    StudyGroup? existing,
    required List<Grade> grades,
    required List<Subject> subjects,
    required List<Teacher> teachers,
    required List<Classroom> classrooms,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (grades.isEmpty || subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addGradesSubjectsFirst)),
      );
      return;
    }
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final capacityCtrl =
        TextEditingController(text: '${existing?.capacity ?? 20}');
    var gradeId = existing?.gradeId ?? grades.first.id;
    var subjectId = existing?.subjectId ?? subjects.first.id;
    String? teacherId = existing?.teacherId;
    String? classroomId = existing?.classroomId;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title: Text(existing == null ? l10n.addGroup : l10n.editGroup),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
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
                        DropdownButtonFormField<String>(
                          value: grades.any((g) => g.id == gradeId)
                              ? gradeId
                              : grades.first.id,
                          decoration: InputDecoration(labelText: l10n.grade),
                          items: [
                            for (final g in grades)
                              DropdownMenuItem(
                                value: g.id,
                                child: Text(g.name),
                              ),
                          ],
                          onChanged: (v) => setState(() => gradeId = v!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: subjects.any((s) => s.id == subjectId)
                              ? subjectId
                              : subjects.first.id,
                          decoration:
                              InputDecoration(labelText: l10n.subjects),
                          items: [
                            for (final s in subjects)
                              DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                          ],
                          onChanged: (v) => setState(() => subjectId = v!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          value: teacherId,
                          decoration:
                              InputDecoration(labelText: l10n.teachers),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(l10n.unspecified),
                            ),
                            for (final t in teachers)
                              DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ),
                          ],
                          onChanged: (v) => setState(() => teacherId = v),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          value: classroomId,
                          decoration:
                              InputDecoration(labelText: l10n.classrooms),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(l10n.unspecified),
                            ),
                            for (final c in classrooms)
                              DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                          ],
                          onChanged: (v) => setState(() => classroomId = v),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: capacityCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(labelText: l10n.capacity),
                          validator: (v) => int.tryParse(v ?? '') == null
                              ? l10n.number
                              : null,
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
                    context.read<CrudListCubit<StudyGroup>>().save(
                          StudyGroup(
                            id: existing?.id ?? '',
                            name: nameCtrl.text.trim(),
                            branchId:
                                existing?.branchId ?? AppDefaults.branchId,
                            gradeId: gradeId,
                            subjectId: subjectId,
                            teacherId: teacherId,
                            classroomId: classroomId,
                            capacity: int.parse(capacityCtrl.text),
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
    final grades = [...?context.watch<CrudListCubit<Grade>>().state.items];
    final subjects =
        [...?context.watch<CrudListCubit<Subject>>().state.items];
    final teachers =
        [...?context.watch<CrudListCubit<Teacher>>().state.items];
    final classrooms =
        [...?context.watch<CrudListCubit<Classroom>>().state.items];
    final gradeName = {for (final g in grades) g.id: g.name};
    final subjectName = {for (final s in subjects) s.id: s.name};

    return AdminPageFrame(
      title: l10n.groups,
      onAdd: () => _openForm(
        context,
        grades: grades,
        subjects: subjects,
        teachers: teachers,
        classrooms: classrooms,
      ),
      child: BlocBuilder<CrudListCubit<StudyGroup>, CrudListState<StudyGroup>>(
        builder: (context, state) {
          if (state.isLoading && state.items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.items ?? [];
          return ResponsiveDataTable(
            columns: [
              DataColumnSpec(l10n.group),
              DataColumnSpec(l10n.grade),
              DataColumnSpec(l10n.subjects),
              DataColumnSpec(l10n.capacity),
            ],
            rowCount: items.length,
            cellBuilder: (r, c) {
              final g = items[r];
              return switch (c) {
                0 => g.name,
                1 => gradeName[g.gradeId] ?? g.gradeId,
                2 => subjectName[g.subjectId] ?? g.subjectId,
                _ => '${g.capacity}',
              };
            },
            mobileTitleBuilder: (r) => items[r].name,
            mobileSubtitleBuilder: (r) =>
                '${gradeName[items[r].gradeId] ?? ''} · ${subjectName[items[r].subjectId] ?? ''}',
            onEdit: (r) => _openForm(
              context,
              existing: items[r],
              grades: grades,
              subjects: subjects,
              teachers: teachers,
              classrooms: classrooms,
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
