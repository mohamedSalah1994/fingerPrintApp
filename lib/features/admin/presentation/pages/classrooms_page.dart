import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/features/admin/domain/entities/academic_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/crud_list_cubit.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/responsive_data_table.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class ClassroomsPage extends StatelessWidget {
  const ClassroomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return BlocProvider(
      create: (_) => CrudListCubit<Classroom>(
        watch: repo.watchClassrooms,
        save: repo.saveClassroom,
        remove: repo.deleteClassroom,
        idOf: (e) => e.id,
      ),
      child: const _ClassroomsView(),
    );
  }
}

class _ClassroomsView extends StatelessWidget {
  const _ClassroomsView();

  Future<void> _openForm(BuildContext context, {Classroom? existing}) async {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final capacityCtrl =
        TextEditingController(text: '${existing?.capacity ?? 20}');
    final buildingCtrl =
        TextEditingController(text: existing?.building ?? '');
    final floorCtrl = TextEditingController(text: existing?.floor ?? '');
    final formKey = GlobalKey<FormState>();

    await showEntityFormDialog(
      context: context,
      title: existing == null ? l10n.addClassroom : l10n.editClassroom,
      formKey: formKey,
      form: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameCtrl,
            decoration: InputDecoration(labelText: l10n.classroomName),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: capacityCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.capacity),
            validator: (v) =>
                int.tryParse(v ?? '') == null ? l10n.number : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: buildingCtrl,
            decoration: InputDecoration(labelText: l10n.building),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: floorCtrl,
            decoration: InputDecoration(labelText: l10n.floor),
          ),
        ],
      ),
      onSave: () {
        context.read<CrudListCubit<Classroom>>().save(
              Classroom(
                id: existing?.id ?? '',
                name: nameCtrl.text.trim(),
                capacity: int.parse(capacityCtrl.text),
                branchId: existing?.branchId ?? AppDefaults.branchId,
                building: buildingCtrl.text.trim().isEmpty
                    ? null
                    : buildingCtrl.text.trim(),
                floor: floorCtrl.text.trim().isEmpty
                    ? null
                    : floorCtrl.text.trim(),
              ),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdminPageFrame(
      title: l10n.classrooms,
      onAdd: () => _openForm(context),
      child: BlocBuilder<CrudListCubit<Classroom>, CrudListState<Classroom>>(
        builder: (context, state) {
          if (state.isLoading && state.items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.items ?? [];
          return ResponsiveDataTable(
            columns: [
              DataColumnSpec(l10n.classrooms),
              DataColumnSpec(l10n.capacity),
              DataColumnSpec(l10n.building),
              DataColumnSpec(l10n.floor),
            ],
            rowCount: items.length,
            cellBuilder: (r, c) {
              final e = items[r];
              return switch (c) {
                0 => e.name,
                1 => '${e.capacity}',
                2 => e.building ?? '—',
                _ => e.floor ?? '—',
              };
            },
            mobileTitleBuilder: (r) => items[r].name,
            mobileSubtitleBuilder: (r) =>
                '${l10n.capacity}: ${items[r].capacity}',
            onEdit: (r) => _openForm(context, existing: items[r]),
            onDelete: (r) async {
              final ok = await confirmDelete(context, items[r].name);
              if (!context.mounted || !ok) return;
              context.read<CrudListCubit<Classroom>>().delete(items[r]);
            },
          );
        },
      ),
    );
  }
}
