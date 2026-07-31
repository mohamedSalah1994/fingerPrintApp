import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/crud_list_cubit.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/responsive_data_table.dart';
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
      ],
      child: const _SubjectsView(),
    );
  }
}

class _SubjectsView extends StatelessWidget {
  const _SubjectsView();

  Future<void> _openForm(
    BuildContext context, {
    Subject? existing,
    required List<Stage> stages,
  }) async {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String? stageId = existing?.stageId;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title:
                  Text(existing == null ? l10n.addSubject : l10n.editSubject),
              content: SizedBox(
                width: 420,
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
                      DropdownButtonFormField<String?>(
                        value: stageId,
                        decoration: InputDecoration(
                          labelText: l10n.stageOptional,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(l10n.allOrUnspecified),
                          ),
                          for (final s in stages)
                            DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                        ],
                        onChanged: (v) => setState(() => stageId = v),
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
                    context.read<CrudListCubit<Subject>>().save(
                          Subject(
                            id: existing?.id ?? '',
                            name: nameCtrl.text.trim(),
                            branchId:
                                existing?.branchId ?? AppDefaults.branchId,
                            stageId: stageId,
                            gradeId: existing?.gradeId,
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
    final stages = [...?context.watch<CrudListCubit<Stage>>().state.items];
    final stageName = {for (final s in stages) s.id: s.name};

    return AdminPageFrame(
      title: l10n.subjectsTitle,
      onAdd: () => _openForm(context, stages: stages),
      child: BlocBuilder<CrudListCubit<Subject>, CrudListState<Subject>>(
        builder: (context, state) {
          if (state.isLoading && state.items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.items ?? [];
          return ResponsiveDataTable(
            columns: [
              DataColumnSpec(l10n.subjects),
              DataColumnSpec(l10n.stages),
            ],
            rowCount: items.length,
            cellBuilder: (r, c) {
              final s = items[r];
              return c == 0
                  ? s.name
                  : (s.stageId == null
                      ? '—'
                      : (stageName[s.stageId] ?? s.stageId!));
            },
            mobileTitleBuilder: (r) => items[r].name,
            mobileSubtitleBuilder: (r) => items[r].stageId == null
                ? l10n.allStages
                : (stageName[items[r].stageId] ?? ''),
            onEdit: (r) =>
                _openForm(context, existing: items[r], stages: stages),
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
