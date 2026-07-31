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

class EnrollmentsPage extends StatelessWidget {
  const EnrollmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CrudListCubit<Enrollment>(
            watch: repo.watchEnrollments,
            save: repo.saveEnrollment,
            remove: repo.deleteEnrollment,
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
          create: (_) => CrudListCubit<Grade>(
            watch: repo.watchGrades,
            save: repo.saveGrade,
            remove: repo.deleteGrade,
            idOf: (e) => e.id,
          ),
        ),
      ],
      child: const _EnrollmentsView(),
    );
  }
}

class _EnrollmentsView extends StatelessWidget {
  const _EnrollmentsView();

  Future<void> _openForm(
    BuildContext context, {
    Enrollment? existing,
    required List<Student> students,
    required List<Grade> grades,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (students.isEmpty || grades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addStudentsGradesFirst)),
      );
      return;
    }
    var studentId = existing?.studentId ?? students.first.id;
    var gradeId = existing?.gradeId ?? grades.first.id;
    var type = existing?.type ?? EnrollmentType.full;
    final feeCtrl =
        TextEditingController(text: '${existing?.fee ?? 0}');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title: Text(
                existing == null ? l10n.addEnrollment : l10n.editEnrollment,
              ),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: students.any((s) => s.id == studentId)
                              ? studentId
                              : students.first.id,
                          decoration:
                              InputDecoration(labelText: l10n.student),
                          items: [
                            for (final s in students)
                              DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                          ],
                          onChanged: (v) => setState(() => studentId = v!),
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
                        DropdownButtonFormField<EnrollmentType>(
                          value: type,
                          decoration: InputDecoration(
                            labelText: l10n.enrollmentType,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: EnrollmentType.full,
                              child: Text(l10n.fullAllSubjects),
                            ),
                            DropdownMenuItem(
                              value: EnrollmentType.partial,
                              child: Text(l10n.partialSelected),
                            ),
                          ],
                          onChanged: (v) => setState(() => type = v!),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: feeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: l10n.fee),
                          validator: (v) => double.tryParse(v ?? '') == null
                              ? l10n.number
                              : null,
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
                    context.read<CrudListCubit<Enrollment>>().save(
                          Enrollment(
                            id: existing?.id ?? '',
                            studentId: studentId,
                            gradeId: gradeId,
                            type: type,
                            branchId:
                                existing?.branchId ?? AppDefaults.branchId,
                            fee: double.parse(feeCtrl.text),
                            note: noteCtrl.text.trim().isEmpty
                                ? null
                                : noteCtrl.text.trim(),
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
    final students =
        [...?context.watch<CrudListCubit<Student>>().state.items];
    final grades = [...?context.watch<CrudListCubit<Grade>>().state.items];
    final studentName = {for (final s in students) s.id: s.name};
    final gradeName = {for (final g in grades) g.id: g.name};

    return AdminPageFrame(
      title: l10n.enrollments,
      onAdd: () =>
          _openForm(context, students: students, grades: grades),
      child:
          BlocBuilder<CrudListCubit<Enrollment>, CrudListState<Enrollment>>(
        builder: (context, state) {
          if (state.isLoading && state.items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.items ?? [];
          return ResponsiveDataTable(
            columns: [
              DataColumnSpec(l10n.student),
              DataColumnSpec(l10n.grade),
              DataColumnSpec(l10n.type),
              DataColumnSpec(l10n.fee),
            ],
            rowCount: items.length,
            cellBuilder: (r, c) {
              final e = items[r];
              return switch (c) {
                0 => studentName[e.studentId] ?? e.studentId,
                1 => gradeName[e.gradeId] ?? e.gradeId,
                2 => e.type == EnrollmentType.full ? l10n.full : l10n.partial,
                _ => e.fee.toStringAsFixed(0),
              };
            },
            mobileTitleBuilder: (r) =>
                studentName[items[r].studentId] ?? items[r].studentId,
            mobileSubtitleBuilder: (r) =>
                '${items[r].type == EnrollmentType.full ? l10n.full : l10n.partial} · ${items[r].fee.toStringAsFixed(0)}',
            onEdit: (r) => _openForm(
              context,
              existing: items[r],
              students: students,
              grades: grades,
            ),
            onDelete: (r) async {
              final label = studentName[items[r].studentId] ?? items[r].id;
              final ok = await confirmDelete(context, label);
              if (!context.mounted || !ok) return;
              context.read<CrudListCubit<Enrollment>>().delete(items[r]);
            },
          );
        },
      ),
    );
  }
}
