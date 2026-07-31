import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/crud_list_cubit.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/responsive_data_table.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CrudListCubit<Grade>(
            watch: repo.watchGrades,
            save: repo.saveGrade,
            remove: repo.deleteGrade,
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
      child: const _GradesView(),
    );
  }
}

class _GradesView extends StatelessWidget {
  const _GradesView();

  Future<void> _openForm(
    BuildContext context, {
    Grade? existing,
    required List<Stage> stages,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (stages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addStageFirst)),
      );
      return;
    }
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final orderCtrl =
        TextEditingController(text: '${existing?.order ?? 0}');
    var stageId = existing?.stageId ?? stages.first.id;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title: Text(existing == null ? l10n.addGrade : l10n.editGrade),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: stages.any((s) => s.id == stageId)
                            ? stageId
                            : stages.first.id,
                        decoration: InputDecoration(labelText: l10n.stages),
                        items: [
                          for (final s in stages)
                            DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                        ],
                        onChanged: (v) => setState(() => stageId = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameCtrl,
                        decoration:
                            InputDecoration(labelText: l10n.gradeName),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.required
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: orderCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l10n.order),
                        validator: (v) => int.tryParse(v ?? '') == null
                            ? l10n.number
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
                    context.read<CrudListCubit<Grade>>().save(
                          Grade(
                            id: existing?.id ?? '',
                            stageId: stageId,
                            name: nameCtrl.text.trim(),
                            order: int.parse(orderCtrl.text),
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
    final stagesState = context.watch<CrudListCubit<Stage>>().state;
    final stages = [...?stagesState.items]
      ..sort((a, b) => a.order.compareTo(b.order));
    final stageName = {for (final s in stages) s.id: s.name};

    return AdminPageFrame(
      title: l10n.gradesTitle,
      onAdd: () => _openForm(context, stages: stages),
      child: BlocBuilder<CrudListCubit<Grade>, CrudListState<Grade>>(
        builder: (context, state) {
          if (state.isLoading && state.items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = [...?state.items]
            ..sort((a, b) => a.order.compareTo(b.order));
          return ResponsiveDataTable(
            columns: [
              DataColumnSpec(l10n.grade),
              DataColumnSpec(l10n.stages),
              DataColumnSpec(l10n.order),
            ],
            rowCount: items.length,
            cellBuilder: (r, c) {
              final g = items[r];
              return switch (c) {
                0 => g.name,
                1 => stageName[g.stageId] ?? g.stageId,
                _ => '${g.order}',
              };
            },
            mobileTitleBuilder: (r) => items[r].name,
            mobileSubtitleBuilder: (r) =>
                stageName[items[r].stageId] ?? items[r].stageId,
            onEdit: (r) =>
                _openForm(context, existing: items[r], stages: stages),
            onDelete: (r) async {
              final ok = await confirmDelete(context, items[r].name);
              if (!context.mounted || !ok) return;
              context.read<CrudListCubit<Grade>>().delete(items[r]);
            },
          );
        },
      ),
    );
  }
}
