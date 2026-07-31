import 'package:flutter/material.dart';
import 'package:fingerprint_app/app/theme/app_colors.dart';
import 'package:fingerprint_app/core/responsive/breakpoints.dart';
import 'package:fingerprint_app/core/widgets/app_animations.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class DataColumnSpec {
  const DataColumnSpec(this.label, {this.flex = 1});

  final String label;
  final int flex;
}

class ResponsiveDataTable extends StatelessWidget {
  const ResponsiveDataTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.cellBuilder,
    required this.mobileTitleBuilder,
    required this.mobileSubtitleBuilder,
    this.onEdit,
    this.onLink,
    this.onDelete,
    this.emptyMessage,
  });

  final List<DataColumnSpec> columns;
  final int rowCount;
  final String Function(int row, int col) cellBuilder;
  final String Function(int row) mobileTitleBuilder;
  final String Function(int row) mobileSubtitleBuilder;
  final void Function(int row)? onEdit;
  final void Function(int row)? onLink;
  final void Function(int row)? onDelete;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final empty = emptyMessage ?? l10n.noData;

    if (rowCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            empty,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    if (AppBreakpoints.isMobile(width)) {
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: rowCount,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          return Card(
            child: ScaleTap(
              onTap: onEdit == null ? null : () => onEdit!(i),
              child: ListTile(
                title: Text(mobileTitleBuilder(i)),
                subtitle: Text(mobileSubtitleBuilder(i)),
                trailing: _RowActions(
                  onEdit: onEdit == null ? null : () => onEdit!(i),
                  onLink: onLink == null ? null : () => onLink!(i),
                  onDelete: onDelete == null ? null : () => onDelete!(i),
                ),
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth - 32),
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                scheme.surfaceContainerHighest,
              ),
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
              columns: [
                for (final c in columns) DataColumn(label: Text(c.label)),
                DataColumn(label: Text(l10n.actions)),
              ],
              rows: [
                for (var i = 0; i < rowCount; i++)
                  DataRow(
                    cells: [
                      for (var c = 0; c < columns.length; c++)
                        DataCell(Text(cellBuilder(i, c))),
                      DataCell(
                        _RowActions(
                          onEdit: onEdit == null ? null : () => onEdit!(i),
                          onLink: onLink == null ? null : () => onLink!(i),
                          onDelete:
                              onDelete == null ? null : () => onDelete!(i),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({this.onEdit, this.onLink, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onLink;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onLink != null)
          IconButton(
            tooltip: l10n.link,
            onPressed: onLink,
            icon: const Icon(Icons.link, color: AppColors.primary),
          ),
        if (onEdit != null)
          IconButton(
            tooltip: l10n.edit,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColors.info),
          ),
        if (onDelete != null)
          IconButton(
            tooltip: l10n.delete,
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.danger,
            ),
          ),
      ],
    );
  }
}
