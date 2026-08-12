import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/core/utils/image_bytes_picker.dart';
import 'package:fingerprint_app/core/utils/teacher_photo.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/crud_list_cubit.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/responsive_data_table.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/searchable_select.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class TeachersPage extends StatelessWidget {
  const TeachersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CrudListCubit<Teacher>(
            watch: repo.watchTeachers,
            save: repo.saveTeacher,
            remove: repo.deleteTeacher,
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
          create: (_) => CrudListCubit<Grade>(
            watch: repo.watchGrades,
            save: repo.saveGrade,
            remove: repo.deleteGrade,
            idOf: (e) => e.id,
          ),
        ),
      ],
      child: const _TeachersView(),
    );
  }
}

class _TeachersView extends StatelessWidget {
  const _TeachersView();

  Future<void> _openForm(
    BuildContext context, {
    Teacher? existing,
    required List<Subject> subjects,
    required List<Grade> grades,
  }) async {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<AdminRepository>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    var method = existing?.salaryMethod ?? SalaryMethod.perSession;
    final selectedSubjects = {...?existing?.subjectIds};
    final selectedGrades = {...?existing?.gradeIds};
    final formKey = GlobalKey<FormState>();
    var isSaving = false;
    final needsLogin = existing?.userId == null;
    Uint8List? photoBytes;
    var photoUrl = existing?.photoUrl;
    var removePhoto = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            final hasPhoto = photoBytes != null ||
                (!removePhoto &&
                    photoUrl != null &&
                    photoUrl!.isNotEmpty);
            final displayName = nameCtrl.text.trim().isEmpty
                ? (existing?.name ?? '?')
                : nameCtrl.text.trim();

            return AlertDialog(
              title: Text(
                existing == null ? l10n.addTeacher : l10n.editTeacher,
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              PersonAvatar(
                                name: displayName,
                                photoUrl: removePhoto ? null : photoUrl,
                                localBytes: photoBytes,
                                radius: 44,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.teacherPhotoOptional,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: isSaving
                                        ? null
                                        : () async {
                                            try {
                                              final bytes =
                                                  await pickImageBytes();
                                              if (bytes == null) return;
                                              setState(() {
                                                photoBytes = bytes;
                                                removePhoto = false;
                                              });
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      l10n.userCreateFailed(
                                                        '$e',
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                    icon: const Icon(Icons.photo_outlined),
                                    label: Text(
                                      hasPhoto
                                          ? l10n.changePhoto
                                          : l10n.pickPhoto,
                                    ),
                                  ),
                                  if (hasPhoto)
                                    TextButton.icon(
                                      onPressed: isSaving
                                          ? null
                                          : () => setState(() {
                                                photoBytes = null;
                                                removePhoto = true;
                                                photoUrl = null;
                                              }),
                                      icon: const Icon(Icons.delete_outline),
                                      label: Text(l10n.removePhoto),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
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
                        SearchableSelectField<SalaryMethod>(
                          label: l10n.paymentMethod,
                          value: method,
                          labelOf: (m) => _salaryLabel(l10n, m),
                          onSearch: (q) => searchableLocalFilter(
                            items: SalaryMethod.values,
                            query: q,
                            labelOf: (m) => _salaryLabel(l10n, m),
                          ),
                          onChanged: (v) =>
                              setState(() => method = v ?? method),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.specializedSubjects,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: subjects.map((s) {
                            final selected = selectedSubjects.contains(s.id);
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
                        const SizedBox(height: 16),
                        Text(
                          l10n.teachingGrades,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: grades.map((g) {
                            final selected = selectedGrades.contains(g.id);
                            return FilterChip(
                              label: Text(g.name),
                              selected: selected,
                              onSelected: (v) => setState(() {
                                if (v) {
                                  selectedGrades.add(g.id);
                                } else {
                                  selectedGrades.remove(g.id);
                                }
                              }),
                            );
                          }).toList(),
                        ),
                        if (needsLogin) ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              l10n.teacherAppLogin,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.createLoginHint,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: '${l10n.loginEmail} (${l10n.unspecified})',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              if (!v.contains('@')) return l10n.invalidEmail;
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passwordCtrl,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText:
                                  '${l10n.loginPassword} (${l10n.unspecified})',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              if (v.length < 6) return l10n.passwordMin6;
                              return null;
                            },
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.verified_user_outlined),
                            title: Text(l10n.accountLinked),
                            subtitle: Text(existing!.userId!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setState(() => isSaving = true);
                          String? photoWarning;
                          try {
                            final email = emailCtrl.text.trim();
                            final password = passwordCtrl.text;
                            final wantsLogin =
                                email.isNotEmpty && password.length >= 6;

                            final base = Teacher(
                              id: existing?.id ?? '',
                              name: nameCtrl.text.trim(),
                              branchId:
                                  existing?.branchId ?? AppDefaults.branchId,
                              phone: phoneCtrl.text.trim().isEmpty
                                  ? null
                                  : phoneCtrl.text.trim(),
                              photoUrl: removePhoto
                                  ? ''
                                  : (photoUrl ?? existing?.photoUrl),
                              salaryMethod: method,
                              subjectIds: selectedSubjects.toList(),
                              gradeIds: selectedGrades.toList(),
                              userId: existing?.userId,
                              status: existing?.status ?? 'active',
                            );

                            final saved = await repo
                                .createTeacherWithLogin(
                                  teacher: base,
                                  loginEmail: wantsLogin ? email : null,
                                  loginPassword:
                                      wantsLogin ? password : null,
                                )
                                .timeout(const Duration(seconds: 30));

                            if (photoBytes != null) {
                              try {
                                final url = await repo.uploadTeacherPhoto(
                                  teacherId: saved.id,
                                  bytes: photoBytes!,
                                );
                                await repo.saveTeacher(
                                  Teacher(
                                    id: saved.id,
                                    name: saved.name,
                                    branchId: saved.branchId,
                                    phone: saved.phone,
                                    userId: saved.userId,
                                    photoUrl: url,
                                    salaryMethod: saved.salaryMethod,
                                    subjectIds: saved.subjectIds,
                                    gradeIds: saved.gradeIds,
                                    status: saved.status,
                                  ),
                                );
                              } catch (e) {
                                // Last resort: embed small photo on the teacher doc.
                                try {
                                  final fallback = teacherPhotoDataUri(
                                    photoBytes!,
                                  );
                                  if (fallback.length < 900000) {
                                    await repo.saveTeacher(
                                      Teacher(
                                        id: saved.id,
                                        name: saved.name,
                                        branchId: saved.branchId,
                                        phone: saved.phone,
                                        userId: saved.userId,
                                        photoUrl: fallback,
                                        salaryMethod: saved.salaryMethod,
                                        subjectIds: saved.subjectIds,
                                        gradeIds: saved.gradeIds,
                                        status: saved.status,
                                      ),
                                    );
                                  } else {
                                    photoWarning =
                                        '${l10n.teacherPhoto}: $e';
                                  }
                                } catch (e2) {
                                  photoWarning =
                                      '${l10n.teacherPhoto}: $e2';
                                }
                              }
                            } else if (removePhoto) {
                              await repo.saveTeacher(
                                Teacher(
                                  id: saved.id,
                                  name: saved.name,
                                  branchId: saved.branchId,
                                  phone: saved.phone,
                                  userId: saved.userId,
                                  photoUrl: '',
                                  salaryMethod: saved.salaryMethod,
                                  subjectIds: saved.subjectIds,
                                  gradeIds: saved.gradeIds,
                                  status: saved.status,
                                ),
                              );
                            }

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    photoWarning ?? l10n.save,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setState(() => isSaving = false);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.userCreateFailed('$e')),
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subjects =
        [...?context.watch<CrudListCubit<Subject>>().state.items];
    final grades = [...?context.watch<CrudListCubit<Grade>>().state.items];
    final subjectName = {for (final s in subjects) s.id: s.name};
    final gradeName = {for (final g in grades) g.id: g.name};

    return AdminPageFrame(
      title: l10n.teachers,
      onAdd: () => _openForm(
        context,
        subjects: subjects,
        grades: grades,
      ),
      child: BlocBuilder<CrudListCubit<Teacher>, CrudListState<Teacher>>(
        builder: (context, state) {
          if (state.isLoading && state.items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.items ?? [];
          return ResponsiveDataTable(
            columns: [
              DataColumnSpec(l10n.teacherPhoto),
              DataColumnSpec(l10n.name),
              DataColumnSpec(l10n.specializedSubjects),
              DataColumnSpec(l10n.teachingGrades),
              DataColumnSpec(l10n.account),
            ],
            rowCount: items.length,
            cellBuilder: (r, c) {
              final t = items[r];
              return switch (c) {
                0 => personInitial(t.name),
                1 => t.name,
                2 => t.subjectIds.isEmpty
                    ? '—'
                    : t.subjectIds
                        .map((id) => subjectName[id] ?? id)
                        .join('، '),
                3 => t.gradeIds.isEmpty
                    ? '—'
                    : t.gradeIds.map((id) => gradeName[id] ?? id).join('، '),
                _ => t.userId == null
                    ? l10n.accountNotLinked
                    : l10n.accountLinked,
              };
            },
            cellWidgetBuilder: (r, c) {
              if (c != 0) return null;
              final t = items[r];
              return PersonAvatar(
                name: t.name,
                photoUrl: t.photoUrl,
                radius: 20,
              );
            },
            mobileLeadingBuilder: (r) {
              final t = items[r];
              return PersonAvatar(
                name: t.name,
                photoUrl: t.photoUrl,
                radius: 22,
              );
            },
            mobileTitleBuilder: (r) => items[r].name,
            mobileSubtitleBuilder: (r) {
              final t = items[r];
              return t.phone ?? _salaryLabel(l10n, t.salaryMethod);
            },
            onOpen: (r) => context.go('/admin/teachers/${items[r].id}'),
            onEdit: (r) => _openForm(
              context,
              existing: items[r],
              subjects: subjects,
              grades: grades,
            ),
            onDelete: (r) async {
              final ok = await confirmDelete(context, items[r].name);
              if (!context.mounted || !ok) return;
              context.read<CrudListCubit<Teacher>>().delete(items[r]);
            },
          );
        },
      ),
    );
  }
}

String _salaryLabel(AppLocalizations l10n, SalaryMethod method) {
  return switch (method) {
    SalaryMethod.perSession => l10n.salaryPerSession,
    SalaryMethod.perStudent => l10n.salaryPerStudent,
    SalaryMethod.monthlyFixed => l10n.salaryMonthly,
    SalaryMethod.hybrid => l10n.salaryHybrid,
  };
}
