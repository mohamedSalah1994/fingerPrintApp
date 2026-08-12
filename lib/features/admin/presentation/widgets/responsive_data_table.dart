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

/// Admin table with client-side pagination (and optional filter box).
class ResponsiveDataTable extends StatefulWidget {
  const ResponsiveDataTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.cellBuilder,
    required this.mobileTitleBuilder,
    required this.mobileSubtitleBuilder,
    this.cellWidgetBuilder,
    this.mobileLeadingBuilder,
    this.onEdit,
    this.onLink,
    this.onOpen,
    this.onDelete,
    this.emptyMessage,
    this.rowsPerPageOptions = const [10, 25, 50],
    this.initialRowsPerPage = 10,
    this.enableFilter = true,
  });

  final List<DataColumnSpec> columns;
  final int rowCount;
  final String Function(int row, int col) cellBuilder;
  final String Function(int row) mobileTitleBuilder;
  final String Function(int row) mobileSubtitleBuilder;
  /// When non-null for a cell, renders this widget instead of [cellBuilder] text.
  final Widget? Function(int row, int col)? cellWidgetBuilder;
  final Widget? Function(int row)? mobileLeadingBuilder;
  final void Function(int row)? onEdit;
  final void Function(int row)? onLink;
  final void Function(int row)? onOpen;
  final void Function(int row)? onDelete;
  final String? emptyMessage;
  final List<int> rowsPerPageOptions;
  final int initialRowsPerPage;
  final bool enableFilter;

  @override
  State<ResponsiveDataTable> createState() => _ResponsiveDataTableState();
}

class _ResponsiveDataTableState extends State<ResponsiveDataTable> {
  late int _rowsPerPage;
  var _page = 0;
  final _filterCtrl = TextEditingController();
  var _filter = '';

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.initialRowsPerPage;
  }

  @override
  void didUpdateWidget(covariant ResponsiveDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rowCount != widget.rowCount) {
      final maxPage = _maxPageFor(_visibleIndexes.length);
      if (_page > maxPage) _page = maxPage;
    }
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  List<int> get _visibleIndexes {
    final all = List<int>.generate(widget.rowCount, (i) => i);
    final q = _filter.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((i) {
      if (widget.mobileTitleBuilder(i).toLowerCase().contains(q)) return true;
      if (widget.mobileSubtitleBuilder(i).toLowerCase().contains(q)) return true;
      for (var c = 0; c < widget.columns.length; c++) {
        if (widget.cellBuilder(i, c).toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList(growable: false);
  }

  int _maxPageFor(int total) {
    if (total <= 0) return 0;
    return ((total - 1) / _rowsPerPage).floor();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final empty = widget.emptyMessage ?? l10n.noData;
    final visible = _visibleIndexes;

    if (widget.rowCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            empty,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final maxPage = _maxPageFor(visible.length);
    final page = _page.clamp(0, maxPage);
    final start = visible.isEmpty ? 0 : page * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, visible.length);
    final pageIndexes = visible.isEmpty ? <int>[] : visible.sublist(start, end);

    final width = MediaQuery.sizeOf(context).width;
    final isMobile = AppBreakpoints.isMobile(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.enableFilter)
                SizedBox(
                  width: isMobile ? double.infinity : 280,
                  child: TextField(
                    controller: _filterCtrl,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: l10n.search,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _filter.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _filterCtrl.clear();
                                setState(() {
                                  _filter = '';
                                  _page = 0;
                                });
                              },
                              icon: const Icon(Icons.clear_rounded, size: 18),
                            ),
                    ),
                    onChanged: (v) => setState(() {
                      _filter = v;
                      _page = 0;
                    }),
                  ),
                ),
              Text(
                l10n.paginationSummary(
                  visible.isEmpty ? 0 : start + 1,
                  end,
                  visible.length,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: pageIndexes.isEmpty
              ? Center(child: Text(l10n.noSearchResults))
              : isMobile
                  ? ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: pageIndexes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final i = pageIndexes[idx];
                        return Card(
                          child: ScaleTap(
                            onTap: widget.onEdit == null
                                ? null
                                : () => widget.onEdit!(i),
                            child: ListTile(
                              leading: widget.mobileLeadingBuilder?.call(i),
                              title: Text(widget.mobileTitleBuilder(i)),
                              subtitle: Text(widget.mobileSubtitleBuilder(i)),
                              trailing: _RowActions(
                                onOpen: widget.onOpen == null
                                    ? null
                                    : () => widget.onOpen!(i),
                                onEdit: widget.onEdit == null
                                    ? null
                                    : () => widget.onEdit!(i),
                                onLink: widget.onLink == null
                                    ? null
                                    : () => widget.onLink!(i),
                                onDelete: widget.onDelete == null
                                    ? null
                                    : () => widget.onDelete!(i),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth - 32,
                            ),
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
                                for (final c in widget.columns)
                                  DataColumn(label: Text(c.label)),
                                DataColumn(label: Text(l10n.actions)),
                              ],
                              rows: [
                                for (final i in pageIndexes)
                                  DataRow(
                                    cells: [
                                      for (var c = 0;
                                          c < widget.columns.length;
                                          c++)
                                        DataCell(
                                          widget.cellWidgetBuilder
                                                  ?.call(i, c) ??
                                              Text(widget.cellBuilder(i, c)),
                                        ),
                                      DataCell(
                                        _RowActions(
                                          onOpen: widget.onOpen == null
                                              ? null
                                              : () => widget.onOpen!(i),
                                          onEdit: widget.onEdit == null
                                              ? null
                                              : () => widget.onEdit!(i),
                                          onLink: widget.onLink == null
                                              ? null
                                              : () => widget.onLink!(i),
                                          onDelete: widget.onDelete == null
                                              ? null
                                              : () => widget.onDelete!(i),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        _PaginationBar(
          page: page,
          maxPage: maxPage,
          rowsPerPage: _rowsPerPage,
          rowsPerPageOptions: widget.rowsPerPageOptions,
          onRowsPerPage: (v) => setState(() {
            _rowsPerPage = v;
            _page = 0;
          }),
          onPrev: page <= 0
              ? null
              : () => setState(() => _page = page - 1),
          onNext: page >= maxPage
              ? null
              : () => setState(() => _page = page + 1),
        ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.maxPage,
    required this.rowsPerPage,
    required this.rowsPerPageOptions,
    required this.onRowsPerPage,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int maxPage;
  final int rowsPerPage;
  final List<int> rowsPerPageOptions;
  final ValueChanged<int> onRowsPerPage;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Text(l10n.rowsPerPage, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: rowsPerPage,
              underline: const SizedBox.shrink(),
              items: [
                for (final n in rowsPerPageOptions)
                  DropdownMenuItem(value: n, child: Text('$n')),
              ],
              onChanged: (v) {
                if (v != null) onRowsPerPage(v);
              },
            ),
            const Spacer(),
            Text(
              l10n.pageOf(page + 1, maxPage + 1),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            IconButton(
              tooltip: l10n.previousPage,
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: l10n.nextPage,
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({this.onOpen, this.onEdit, this.onLink, this.onDelete});

  final VoidCallback? onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onLink;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onOpen != null)
          IconButton(
            tooltip: l10n.viewDetails,
            onPressed: onOpen,
            icon: const Icon(Icons.visibility_outlined, color: AppColors.info),
          ),
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
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
      ],
    );
  }
}
