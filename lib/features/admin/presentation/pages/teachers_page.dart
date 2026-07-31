import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/crud_list_cubit.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/responsive_data_table.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class TeachersPage extends StatelessWidget {
  const TeachersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return BlocProvider(
      create: (_) => CrudListCubit<Teacher>(
        watch: repo.watchTeachers,
        save: repo.saveTeacher,
        remove: repo.deleteTeacher,
        idOf: (e) => e.id,
      ),
      child: const _TeachersView(),
    );
  }
}

class _TeachersView extends StatelessWidget {
  const _TeachersView();

  Future<void> _openForm(BuildContext context, {Teacher? existing}) async {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    var method = existing?.salaryMethod ?? SalaryMethod.perSession;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title:
                  Text(existing == null ? l10n.addTeacher : l10n.editTeacher),
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
                      DropdownButtonFormField<SalaryMethod>(
                        value: method,
                        decoration: InputDecoration(
                          labelText: l10n.paymentMethod,
                        ),
                        items: [
                          for (final m in SalaryMethod.values)
                            DropdownMenuItem(
                              value: m,
                              child: Text(_salaryLabel(l10n, m)),
                            ),
                        ],
                        onChanged: (v) => setState(() => method = v!),
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
                    context.read<CrudListCubit<Teacher>>().save(
                          Teacher(
                            id: existing?.id ?? '',
                            name: nameCtrl.text.trim(),
                            branchId:
                                existing?.branchId ?? AppDefaults.branchId,
                            phone: phoneCtrl.text.trim().isEmpty
                                ? null
                                : phoneCtrl.text.trim(),
                            salaryMethod: method,
                            subjectIds: existing?.subjectIds ?? const [],
                            userId: existing?.userId,
                            status: existing?.status ?? 'active',
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
    return AdminPageFrame(
      title: l10n.teachers,
      onAdd: () => _openForm(context),
      child: BlocBuilder<CrudListCubit<Teacher>, CrudListState<Teacher>>(
        builder: (context, state) {
          if (state.isLoading && state.items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.items ?? [];
          return ResponsiveDataTable(
            columns: [
              DataColumnSpec(l10n.name),
              DataColumnSpec(l10n.phone),
              DataColumnSpec(l10n.paymentMethod),
            ],
            rowCount: items.length,
            cellBuilder: (r, c) {
              final t = items[r];
              return switch (c) {
                0 => t.name,
                1 => t.phone ?? '—',
                _ => _salaryLabel(l10n, t.salaryMethod),
              };
            },
            mobileTitleBuilder: (r) => items[r].name,
            mobileSubtitleBuilder: (r) =>
                items[r].phone ?? _salaryLabel(l10n, items[r].salaryMethod),
            onEdit: (r) => _openForm(context, existing: items[r]),
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
