import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/crud_list_cubit.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/responsive_data_table.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class StagesPage extends StatelessWidget {
  const StagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return BlocProvider(
      create: (_) => CrudListCubit<Stage>(
        watch: repo.watchStages,
        save: repo.saveStage,
        remove: repo.deleteStage,
        idOf: (e) => e.id,
      ),
      child: const _StagesView(),
    );
  }
}

class _StagesView extends StatelessWidget {
  const _StagesView();

  Future<void> _openForm(BuildContext context, {Stage? existing}) async {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final orderCtrl =
        TextEditingController(text: '${existing?.order ?? 0}');
    final formKey = GlobalKey<FormState>();

    await showEntityFormDialog(
      context: context,
      title: existing == null ? l10n.addStage : l10n.editStage,
      formKey: formKey,
      form: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameCtrl,
            decoration: InputDecoration(labelText: l10n.stageName),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: orderCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.order),
            validator: (v) =>
                int.tryParse(v ?? '') == null ? l10n.number : null,
          ),
        ],
      ),
      onSave: () {
        final stage = Stage(
          id: existing?.id ?? '',
          name: nameCtrl.text.trim(),
          order: int.parse(orderCtrl.text),
          branchId: existing?.branchId ?? AppDefaults.branchId,
        );
        context.read<CrudListCubit<Stage>>().save(stage);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdminPageFrame(
      title: l10n.stagesTitle,
      onAdd: () => _openForm(context),
      child: BlocBuilder<CrudListCubit<Stage>, CrudListState<Stage>>(
        builder: (context, state) {
          if (state.isLoading && state.items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = [...?state.items]
            ..sort((a, b) => a.order.compareTo(b.order));
          return ResponsiveDataTable(
            columns: [
              DataColumnSpec(l10n.name),
              DataColumnSpec(l10n.order),
            ],
            rowCount: items.length,
            cellBuilder: (r, c) =>
                c == 0 ? items[r].name : '${items[r].order}',
            mobileTitleBuilder: (r) => items[r].name,
            mobileSubtitleBuilder: (r) =>
                '${l10n.order}: ${items[r].order}',
            onEdit: (r) => _openForm(context, existing: items[r]),
            onDelete: (r) async {
              final ok = await confirmDelete(context, items[r].name);
              if (!context.mounted || !ok) return;
              context.read<CrudListCubit<Stage>>().delete(items[r]);
            },
          );
        },
      ),
    );
  }
}
