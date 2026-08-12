import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fingerprint_app/features/admin/domain/entities/attendance_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/responsive_data_table.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/searchable_select.dart';
import 'package:fingerprint_app/features/auth/domain/entities/app_user.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

String _roleLabel(AppLocalizations l10n, UserRole role) {
  return role == UserRole.admin ? l10n.roleAdmin : l10n.roleTeacher;
}

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  Future<void> _openForm(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<AdminRepository>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    var role = UserRole.teacher;
    final formKey = GlobalKey<FormState>();
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title: Text(
                role == UserRole.admin
                    ? l10n.createAdminUser
                    : l10n.createTeacherUser,
              ),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SearchableSelectField<UserRole>(
                          label: l10n.role,
                          value: role,
                          labelOf: (r) => _roleLabel(l10n, r),
                          onSearch: (q) => searchableLocalFilter(
                            items: UserRole.values,
                            query: q,
                            labelOf: (r) => _roleLabel(l10n, r),
                          ),
                          onChanged: (v) => setState(() => role = v ?? role),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: InputDecoration(labelText: l10n.name),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.required
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(labelText: l10n.email),
                          validator: (v) => (v == null ||
                                  !v.contains('@') ||
                                  v.trim().isEmpty)
                              ? l10n.invalidEmail
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordCtrl,
                          obscureText: true,
                          decoration:
                              InputDecoration(labelText: l10n.password),
                          validator: (v) => (v == null || v.length < 6)
                              ? l10n.passwordMin6
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneCtrl,
                          decoration: InputDecoration(labelText: l10n.phone),
                        ),
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
                          try {
                            await repo.createStaffUser(
                              email: emailCtrl.text.trim(),
                              password: passwordCtrl.text,
                              displayName: nameCtrl.text.trim(),
                              role: role,
                              phone: phoneCtrl.text.trim().isEmpty
                                  ? null
                                  : phoneCtrl.text.trim(),
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.userCreated)),
                              );
                            }
                          } catch (e) {
                            setState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(l10n.userCreateFailed('$e')),
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
    final repo = context.read<AdminRepository>();
    return AdminPageFrame(
      title: l10n.users,
      addLabel: l10n.addUser,
      onAdd: () => _openForm(context),
      child: StreamBuilder<List<StaffUser>>(
        stream: repo.watchStaffUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          return ResponsiveDataTable(
            columns: [
              DataColumnSpec(l10n.name),
              DataColumnSpec(l10n.email),
              DataColumnSpec(l10n.role),
              DataColumnSpec(l10n.phone),
            ],
            rowCount: items.length,
            cellBuilder: (r, c) {
              final u = items[r];
              return switch (c) {
                0 => u.displayName,
                1 => u.email,
                2 => _roleLabel(l10n, u.role),
                _ => u.phone ?? '—',
              };
            },
            mobileTitleBuilder: (r) => items[r].displayName,
            mobileSubtitleBuilder: (r) =>
                '${items[r].email} · ${_roleLabel(l10n, items[r].role)}',
          );
        },
      ),
    );
  }
}
