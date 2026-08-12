import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class SearchableOption<T> {
  const SearchableOption({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final T value;
  final String label;
  final String? subtitle;
}

/// Form-like field that opens a searchable dialog.
/// Typing waits [debounce] (default 1s) then calls [onSearch].
class SearchableSelectField<T> extends StatelessWidget {
  const SearchableSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.labelOf,
    required this.onSearch,
    required this.onChanged,
    this.allowClear = false,
    this.clearLabel,
    this.validator,
    this.fieldHeight = 56,
  });

  final String label;
  final T? value;
  final String Function(T value) labelOf;
  final Future<List<SearchableOption<T>>> Function(String query) onSearch;
  final ValueChanged<T?> onChanged;
  final bool allowClear;
  final String? clearLabel;
  final String? Function(T?)? validator;
  final double fieldHeight;

  @override
  Widget build(BuildContext context) {
    final error = validator?.call(value);
    final display = value == null ? null : labelOf(value as T);

    return SizedBox(
      height: fieldHeight,
      child: FormField<T?>(
        initialValue: value,
        validator: (_) => validator?.call(value),
        builder: (state) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              errorText: state.errorText ?? error,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (allowClear && value != null)
                    IconButton(
                      tooltip: clearLabel ??
                          AppLocalizations.of(context).clearSelection,
                      onPressed: () {
                        state.didChange(null);
                        onChanged(null);
                      },
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                    ),
                  const Icon(Icons.arrow_drop_down_rounded),
                  const SizedBox(width: 4),
                ],
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            isEmpty: display == null || display.isEmpty,
            child: InkWell(
              onTap: () async {
                final picked = await showSearchableSelectDialog<T>(
                  context: context,
                  title: label,
                  selected: value,
                  labelOf: labelOf,
                  onSearch: onSearch,
                  allowClear: allowClear,
                  clearLabel: clearLabel,
                );
                if (picked == SearchableSelectResult.cancelled) return;
                final typed = picked as T?;
                state.didChange(typed);
                onChanged(typed);
              },
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  display ?? '',
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum SearchableSelectResult { cancelled }

Future<Object?> showSearchableSelectDialog<T>({
  required BuildContext context,
  required String title,
  required T? selected,
  required String Function(T value) labelOf,
  required Future<List<SearchableOption<T>>> Function(String query) onSearch,
  bool allowClear = false,
  String? clearLabel,
  Duration debounce = const Duration(seconds: 1),
}) {
  return showDialog<Object?>(
    context: context,
    builder: (ctx) => _SearchableSelectDialog<T>(
      title: title,
      selected: selected,
      labelOf: labelOf,
      onSearch: onSearch,
      allowClear: allowClear,
      clearLabel: clearLabel,
      debounce: debounce,
    ),
  );
}

/// Multi-select searchable dialog. Returns selected values, or null if cancelled.
Future<List<T>?> showSearchableMultiSelectDialog<T>({
  required BuildContext context,
  required String title,
  required Set<T> initiallySelected,
  required String Function(T value) labelOf,
  required Future<List<SearchableOption<T>>> Function(String query) onSearch,
  Duration debounce = const Duration(milliseconds: 300),
}) {
  return showDialog<List<T>?>(
    context: context,
    builder: (ctx) => _SearchableMultiSelectDialog<T>(
      title: title,
      initiallySelected: initiallySelected,
      labelOf: labelOf,
      onSearch: onSearch,
      debounce: debounce,
    ),
  );
}

/// Local list search helper used after the dialog debounce.
Future<List<SearchableOption<T>>> searchableLocalFilter<T>({
  required List<T> items,
  required String query,
  required String Function(T value) labelOf,
  String Function(T value)? subtitleOf,
  int limit = 80,
}) async {
  // Keep this async so call sites always "await a request".
  await Future<void>.delayed(Duration.zero);
  final q = query.trim().toLowerCase();
  Iterable<T> filtered = items;
  if (q.isNotEmpty) {
    filtered = items.where((e) {
      final label = labelOf(e).toLowerCase();
      final sub = subtitleOf?.call(e).toLowerCase() ?? '';
      return label.contains(q) || sub.contains(q);
    });
  }
  return filtered
      .take(limit)
      .map(
        (e) => SearchableOption<T>(
          value: e,
          label: labelOf(e),
          subtitle: subtitleOf?.call(e),
        ),
      )
      .toList(growable: false);
}

class _SearchableSelectDialog<T> extends StatefulWidget {
  const _SearchableSelectDialog({
    required this.title,
    required this.selected,
    required this.labelOf,
    required this.onSearch,
    required this.allowClear,
    required this.clearLabel,
    required this.debounce,
  });

  final String title;
  final T? selected;
  final String Function(T value) labelOf;
  final Future<List<SearchableOption<T>>> Function(String query) onSearch;
  final bool allowClear;
  final String? clearLabel;
  final Duration debounce;

  @override
  State<_SearchableSelectDialog<T>> createState() =>
      _SearchableSelectDialogState<T>();
}

class _SearchableSelectDialogState<T> extends State<_SearchableSelectDialog<T>> {
  final _controller = TextEditingController();
  Timer? _debounce;
  var _loading = true;
  var _query = '';
  Object? _error;
  List<SearchableOption<T>> _options = const [];

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });
    _debounce = Timer(widget.debounce, () => _runSearch(value));
  }

  Future<void> _runSearch(String query) async {
    final normalized = query.trim();
    setState(() {
      _loading = true;
      _error = null;
      _query = normalized;
    });
    try {
      final results = await widget.onSearch(normalized);
      if (!mounted || _query != normalized) return;
      setState(() {
        _options = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || _query != normalized) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.search,
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear_rounded),
                      ),
              ),
              onChanged: (v) {
                setState(() {});
                _onQueryChanged(v);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.searchDebounceHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (widget.allowClear)
              ListTile(
                dense: true,
                leading: const Icon(Icons.remove_circle_outline),
                title: Text(widget.clearLabel ?? l10n.unspecified),
                onTap: () => Navigator.pop(context, null),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('${l10n.syncFailed}: $_error'))
                      : _options.isEmpty
                          ? Center(child: Text(l10n.noSearchResults))
                          : ListView.separated(
                              itemCount: _options.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final opt = _options[i];
                                final selected = widget.selected != null &&
                                    opt.value == widget.selected;
                                return ListTile(
                                  selected: selected,
                                  title: Text(opt.label),
                                  subtitle: opt.subtitle == null
                                      ? null
                                      : Text(opt.subtitle!),
                                  trailing: selected
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          color: theme.colorScheme.primary,
                                        )
                                      : null,
                                  onTap: () =>
                                      Navigator.pop(context, opt.value),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, SearchableSelectResult.cancelled),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

class _SearchableMultiSelectDialog<T> extends StatefulWidget {
  const _SearchableMultiSelectDialog({
    required this.title,
    required this.initiallySelected,
    required this.labelOf,
    required this.onSearch,
    required this.debounce,
  });

  final String title;
  final Set<T> initiallySelected;
  final String Function(T value) labelOf;
  final Future<List<SearchableOption<T>>> Function(String query) onSearch;
  final Duration debounce;

  @override
  State<_SearchableMultiSelectDialog<T>> createState() =>
      _SearchableMultiSelectDialogState<T>();
}

class _SearchableMultiSelectDialogState<T>
    extends State<_SearchableMultiSelectDialog<T>> {
  final _controller = TextEditingController();
  Timer? _debounce;
  var _loading = true;
  var _query = '';
  Object? _error;
  List<SearchableOption<T>> _options = const [];
  late Set<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initiallySelected};
    _runSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });
    _debounce = Timer(widget.debounce, () => _runSearch(value));
  }

  Future<void> _runSearch(String query) async {
    final normalized = query.trim();
    setState(() {
      _loading = true;
      _error = null;
      _query = normalized;
    });
    try {
      final results = await widget.onSearch(normalized);
      if (!mounted || _query != normalized) return;
      setState(() {
        _options = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || _query != normalized) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _toggle(T value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.search,
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear_rounded),
                      ),
              ),
              onChanged: (v) {
                setState(() {});
                _onQueryChanged(v);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  l10n.selectedStudentsCount(_selected.length),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _options.isEmpty
                      ? null
                      : () => setState(() {
                            _selected.addAll(_options.map((o) => o.value));
                          }),
                  child: Text(l10n.selectAllVisible),
                ),
                TextButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => setState(() => _selected.clear()),
                  child: Text(l10n.clearSelection),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('${l10n.syncFailed}: $_error'))
                      : _options.isEmpty
                          ? Center(child: Text(l10n.noSearchResults))
                          : ListView.separated(
                              itemCount: _options.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final opt = _options[i];
                                final selected = _selected.contains(opt.value);
                                return CheckboxListTile(
                                  value: selected,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(opt.label),
                                  subtitle: opt.subtitle == null
                                      ? null
                                      : Text(opt.subtitle!),
                                  onChanged: (_) => _toggle(opt.value),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected.toList()),
          child: Text(l10n.done),
        ),
      ],
    );
  }
}
