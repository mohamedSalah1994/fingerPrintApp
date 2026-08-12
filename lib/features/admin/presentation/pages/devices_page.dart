import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fingerprint_app/app/theme/app_colors.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/core/responsive/breakpoints.dart';
import 'package:fingerprint_app/core/services/zk_sidecar_client.dart';
import 'package:fingerprint_app/core/services/zk_sidecar_launcher.dart';
import 'package:fingerprint_app/core/widgets/app_animations.dart';
import 'package:fingerprint_app/features/admin/domain/entities/attendance_entities.dart';
import 'package:fingerprint_app/features/admin/domain/entities/people_entities.dart';
import 'package:fingerprint_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:fingerprint_app/features/admin/presentation/cubit/crud_list_cubit.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/responsive_data_table.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/searchable_select.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CrudListCubit<FingerprintDevice>(
            watch: repo.watchDevices,
            save: repo.saveDevice,
            remove: repo.deleteDevice,
            idOf: (e) => e.id,
          ),
        ),
        BlocProvider(
          create: (_) => CrudListCubit<BiometricMapping>(
            watch: repo.watchBiometricMappings,
            save: repo.saveBiometricMapping,
            remove: repo.deleteBiometricMapping,
            idOf: (e) => e.id,
          ),
        ),
        BlocProvider(
          create: (_) => CrudListCubit<Student>(
            watch: repo.watchStudents,
            save: repo.saveStudent,
            remove: repo.deleteStudent,
            idOf: (e) => e.id,
          ),
        ),
      ],
      child: const _DevicesView(),
    );
  }
}

class _DevicesView extends StatefulWidget {
  const _DevicesView();

  @override
  State<_DevicesView> createState() => _DevicesViewState();
}

class _DevicesViewState extends State<_DevicesView> {
  final _sidecar = ZkSidecarClient();
  /// null = checking, true = online, false = offline after retries
  bool? _sidecarOnline;
  bool _connecting = false;
  bool _busy = false;
  Timer? _healthTimer;
  int _connectGeneration = 0;

  @override
  void initState() {
    super.initState();
    _ensureSidecarConnected(launchHelper: true);
    _healthTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) {
        if (_connecting) return;
        _refreshHealth();
      },
    );
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    super.dispose();
  }

  Future<bool> _ping() async {
    try {
      await _sidecar.health();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _refreshHealth() async {
    final ok = await _ping();
    if (!mounted) return;
    setState(() {
      _sidecarOnline = ok;
      if (ok) _connecting = false;
    });
    if (!ok && !_connecting) {
      await _ensureSidecarConnected(launchHelper: true);
    }
  }

  /// On Devices page open (or retry): show connecting, try start helper, poll.
  Future<void> _ensureSidecarConnected({required bool launchHelper}) async {
    final gen = ++_connectGeneration;
    if (!mounted) return;
    setState(() {
      _connecting = true;
      _sidecarOnline = null;
    });

    if (await _ping()) {
      if (!mounted || gen != _connectGeneration) return;
      setState(() {
        _sidecarOnline = true;
        _connecting = false;
      });
      return;
    }

    if (launchHelper) {
      await ZkSidecarLauncher.requestStart();
    }

    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted || gen != _connectGeneration) return;
      if (await _ping()) {
        setState(() {
          _sidecarOnline = true;
          _connecting = false;
        });
        return;
      }
    }

    if (!mounted || gen != _connectGeneration) return;
    setState(() {
      _sidecarOnline = false;
      _connecting = false;
    });
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : null,
      ),
    );
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDeviceForm(
    BuildContext context, {
    FingerprintDevice? existing,
  }) async {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final ipCtrl = TextEditingController(text: existing?.ipAddress ?? '');
    final portCtrl =
        TextEditingController(text: '${existing?.port ?? 4370}');
    final commKeyCtrl =
        TextEditingController(text: '${existing?.commKey ?? 0}');
    final serialCtrl =
        TextEditingController(text: existing?.serialNumber ?? '');
    final locationCtrl =
        TextEditingController(text: existing?.location ?? '');
    final modelCtrl =
        TextEditingController(text: existing?.model ?? 'K50 Pro');
    var forceUdp = existing?.forceUdp ?? false;
    var status = existing?.status ?? 'active';
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setLocal) {
            return AlertDialog(
              title: Text(existing == null ? l10n.addDevice : l10n.editDevice),
              content: SizedBox(
                width: 460,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
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
                          controller: ipCtrl,
                          decoration:
                              InputDecoration(labelText: l10n.ipAddress),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.required
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: portCtrl,
                                keyboardType: TextInputType.number,
                                decoration:
                                    InputDecoration(labelText: l10n.port),
                                validator: (v) => int.tryParse(v ?? '') == null
                                    ? l10n.number
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: commKeyCtrl,
                                keyboardType: TextInputType.number,
                                decoration:
                                    InputDecoration(labelText: l10n.commKey),
                                validator: (v) => int.tryParse(v ?? '') == null
                                    ? l10n.number
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: serialCtrl,
                          decoration:
                              InputDecoration(labelText: l10n.serialNumber),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: locationCtrl,
                          decoration:
                              InputDecoration(labelText: l10n.location),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: modelCtrl,
                          decoration: const InputDecoration(labelText: 'Model'),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.forceUdp),
                          value: forceUdp,
                          onChanged: (v) => setLocal(() => forceUdp = v),
                        ),
                        SearchableSelectField<String>(
                          label: l10n.status,
                          value: status,
                          labelOf: (s) => s,
                          onSearch: (q) => searchableLocalFilter(
                            items: const ['active', 'inactive'],
                            query: q,
                            labelOf: (s) => s,
                          ),
                          onChanged: (v) =>
                              setLocal(() => status = v ?? 'active'),
                        ),
                      ],
                    ),
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
                    context.read<CrudListCubit<FingerprintDevice>>().save(
                          FingerprintDevice(
                            id: existing?.id ?? '',
                            name: nameCtrl.text.trim(),
                            branchId:
                                existing?.branchId ?? AppDefaults.branchId,
                            serialNumber: serialCtrl.text.trim(),
                            model: modelCtrl.text.trim().isEmpty
                                ? 'K50 Pro'
                                : modelCtrl.text.trim(),
                            status: status,
                            location: locationCtrl.text.trim().isEmpty
                                ? null
                                : locationCtrl.text.trim(),
                            lastSyncAt: existing?.lastSyncAt,
                            ipAddress: ipCtrl.text.trim(),
                            port: int.parse(portCtrl.text.trim()),
                            commKey: int.parse(commKeyCtrl.text.trim()),
                            forceUdp: forceUdp,
                            vendor: existing?.vendor ?? 'zkteco',
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

  Future<void> _testConnection(FingerprintDevice device) async {
    final l10n = AppLocalizations.of(context);
    final ip = device.ipAddress?.trim() ?? '';
    if (ip.isEmpty) {
      _snack(l10n.connectionFailed, error: true);
      return;
    }
    await _runBusy(() async {
      try {
        await _sidecar.testConnection(
          ip: ip,
          port: device.port,
          commKey: device.commKey,
          forceUdp: device.forceUdp,
        );
        _snack(l10n.connectionOk);
        await _refreshHealth();
      } catch (e) {
        _snack('${l10n.connectionFailed}: $e', error: true);
      }
    });
  }

  String _syncSummary(Map<String, dynamic> body) {
    final results = (body['results'] as List?) ?? const [];
    var punches = 0;
    var written = 0;
    var unmapped = 0;
    final unmappedIds = <String>{};
    for (final raw in results) {
      if (raw is! Map) continue;
      final r = Map<String, dynamic>.from(raw);
      punches += (r['punches'] as num?)?.toInt() ?? 0;
      written += (r['written'] as num?)?.toInt() ?? 0;
      unmapped += (r['unmapped'] as num?)?.toInt() ?? 0;
      final ids = (r['unmapped_ids'] as List?) ?? const [];
      for (final id in ids) {
        unmappedIds.add('$id');
      }
    }
    final extra = unmappedIds.isEmpty
        ? ''
        : ' · بدون ربط: ${unmappedIds.take(5).join(', ')}';
    return 'سجلات الجهاز: $punches · تم الحفظ: $written · بدون ربط: $unmapped$extra';
  }

  Future<void> _syncDevice(FingerprintDevice device) async {
    final l10n = AppLocalizations.of(context);
    await _runBusy(() async {
      try {
        final body = await _sidecar.sync(deviceId: device.id);
        _snack('${l10n.syncDone} — ${_syncSummary(body)}');
        await _refreshHealth();
      } catch (e) {
        _snack('${l10n.syncFailed}: $e', error: true);
      }
    });
  }

  Future<void> _syncAll() async {
    final l10n = AppLocalizations.of(context);
    await _runBusy(() async {
      try {
        final body = await _sidecar.sync();
        _snack('${l10n.syncDone} — ${_syncSummary(body)}');
        await _refreshHealth();
      } catch (e) {
        _snack('${l10n.syncFailed}: $e', error: true);
      }
    });
  }

  Future<void> _startLoop() async {
    final l10n = AppLocalizations.of(context);
    await _runBusy(() async {
      try {
        await _sidecar.startLoop();
        _snack(l10n.startAutoSync);
        await _refreshHealth();
      } catch (e) {
        _snack('${l10n.syncFailed}: $e', error: true);
      }
    });
  }

  Future<void> _stopLoop() async {
    final l10n = AppLocalizations.of(context);
    await _runBusy(() async {
      try {
        await _sidecar.stopLoop();
        _snack(l10n.stopAutoSync);
        await _refreshHealth();
      } catch (e) {
        _snack('${l10n.syncFailed}: $e', error: true);
      }
    });
  }

  Future<void> _loadDeviceUsers(FingerprintDevice device) async {
    final l10n = AppLocalizations.of(context);
    final students =
        [...?context.read<CrudListCubit<Student>>().state.items];
    if (students.isEmpty) {
      _snack(l10n.noStudentsYet, error: true);
      return;
    }

    var failed = false;
    List<Map<String, dynamic>> users = const [];
    await _runBusy(() async {
      try {
        users = await _sidecar.deviceUsers(device.id);
        await _refreshHealth();
      } catch (e) {
        failed = true;
        _snack('${l10n.connectionFailed}: $e', error: true);
      }
    });
    if (!mounted || failed) return;
    if (users.isEmpty) {
      _snack(l10n.noData);
      return;
    }

    final mappingsCubit = context.read<CrudListCubit<BiometricMapping>>();
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _DeviceUsersDialog(
          device: device,
          users: users,
          students: students,
          onSaveMapping: (mapping) async {
            await mappingsCubit.save(mapping);
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.mappingSaved)),
            );
          },
        );
      },
    );
  }

  String _formatSync(DateTime? at) {
    if (at == null) return '—';
    return DateFormat('yyyy-MM-dd HH:mm').format(at.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final devices =
        [...?context.watch<CrudListCubit<FingerprintDevice>>().state.items]
          ..sort((a, b) => a.name.compareTo(b.name));
    final mappings =
        [...?context.watch<CrudListCubit<BiometricMapping>>().state.items];
    final students =
        [...?context.watch<CrudListCubit<Student>>().state.items];
    final studentName = {for (final s in students) s.id: s.name};
    final deviceName = {for (final d in devices) d.id: d.name};
    final devicesLoading =
        context.watch<CrudListCubit<FingerprintDevice>>().state.isLoading &&
            context.watch<CrudListCubit<FingerprintDevice>>().state.items ==
                null;

    return AdminPageFrame(
      title: l10n.devices,
      onAdd: () => _openDeviceForm(context),
      addLabel: l10n.addDevice,
      actions: [
        if (_busy)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidecarBanner(
            online: _sidecarOnline,
            connecting: _connecting,
            onlineLabel: l10n.sidecarOnline,
            offlineLabel: l10n.sidecarOffline,
            connectingLabel: l10n.sidecarConnecting,
            connectingHint: l10n.sidecarConnectingHint,
            hint: l10n.sidecarHint,
            retryLabel: l10n.sidecarRetry,
            onRetry: () => _ensureSidecarConnected(launchHelper: true),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _syncAll,
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: Text(l10n.syncAll),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _startLoop,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(l10n.startAutoSync),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _stopLoop,
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: Text(l10n.stopAutoSync),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: devicesLoading
                ? const Center(child: CircularProgressIndicator())
                : _DeviceList(
                    devices: devices,
                    formatSync: _formatSync,
                    onEdit: (d) => _openDeviceForm(context, existing: d),
                    onDelete: (d) async {
                      final ok = await confirmDelete(context, d.name);
                      if (!context.mounted || !ok) return;
                      context
                          .read<CrudListCubit<FingerprintDevice>>()
                          .delete(d);
                    },
                    onTest: _testConnection,
                    onSync: _syncDevice,
                    onLoadUsers: _loadDeviceUsers,
                  ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Text(
              l10n.biometricMappings,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ResponsiveDataTable(
              columns: [
                DataColumnSpec(l10n.student),
                DataColumnSpec(l10n.deviceUserId),
                DataColumnSpec(l10n.devices),
              ],
              rowCount: mappings.length,
              cellBuilder: (r, c) {
                final m = mappings[r];
                return switch (c) {
                  0 => studentName[m.studentId] ?? m.studentId,
                  1 => m.deviceUserId,
                  _ => deviceName[m.deviceId] ?? m.deviceId,
                };
              },
              mobileTitleBuilder: (r) =>
                  studentName[mappings[r].studentId] ??
                  mappings[r].studentId,
              mobileSubtitleBuilder: (r) {
                final m = mappings[r];
                final dn = deviceName[m.deviceId] ?? m.deviceId;
                return '${l10n.deviceUserId}: ${m.deviceUserId} · $dn';
              },
              emptyMessage: l10n.noData,
              onDelete: (r) async {
                final m = mappings[r];
                final label =
                    studentName[m.studentId] ?? m.deviceUserId;
                final ok = await confirmDelete(context, label);
                if (!context.mounted || !ok) return;
                context.read<CrudListCubit<BiometricMapping>>().delete(m);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidecarBanner extends StatelessWidget {
  const _SidecarBanner({
    required this.online,
    required this.connecting,
    required this.onlineLabel,
    required this.offlineLabel,
    required this.connectingLabel,
    required this.connectingHint,
    required this.hint,
    required this.retryLabel,
    required this.onRetry,
  });

  final bool? online;
  final bool connecting;
  final String onlineLabel;
  final String offlineLabel;
  final String connectingLabel;
  final String connectingHint;
  final String hint;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final checking = connecting || online == null;
    final ok = online == true && !connecting;
    final color = checking
        ? AppColors.info
        : ok
            ? AppColors.success
            : AppColors.danger;
    final bg = color.withValues(alpha: 0.12);
    final label = checking
        ? connectingLabel
        : ok
            ? onlineLabel
            : offlineLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              if (checking)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: color,
                  ),
                )
              else
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (checking || !ok) ...[
                      const SizedBox(height: 2),
                      Text(
                        checking ? connectingHint : hint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!ok)
                TextButton(
                  onPressed: connecting ? null : onRetry,
                  child: Text(retryLabel),
                )
              else
                IconButton(
                  tooltip: retryLabel,
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh_rounded, color: color, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({
    required this.devices,
    required this.formatSync,
    required this.onEdit,
    required this.onDelete,
    required this.onTest,
    required this.onSync,
    required this.onLoadUsers,
  });

  final List<FingerprintDevice> devices;
  final String Function(DateTime?) formatSync;
  final void Function(FingerprintDevice) onEdit;
  final void Function(FingerprintDevice) onDelete;
  final void Function(FingerprintDevice) onTest;
  final void Function(FingerprintDevice) onSync;
  final void Function(FingerprintDevice) onLoadUsers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;

    if (devices.isEmpty) {
      return Center(
        child: Text(
          l10n.noData,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    if (AppBreakpoints.isMobile(width)) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        itemCount: devices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final d = devices[i];
          return Card(
            child: ListTile(
              title: Text(d.name),
              subtitle: Text(
                '${d.ipAddress ?? '—'}:${d.port} · ${d.status}\n'
                '${formatSync(d.lastSyncAt)}',
              ),
              isThreeLine: true,
              trailing: _DeviceActionsMenu(
                onTest: () => onTest(d),
                onSync: () => onSync(d),
                onLoadUsers: () => onLoadUsers(d),
                onEdit: () => onEdit(d),
                onDelete: () => onDelete(d),
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
                DataColumn(label: Text(l10n.name)),
                DataColumn(label: Text(l10n.ipAddress)),
                DataColumn(label: Text(l10n.port)),
                DataColumn(label: Text(l10n.status)),
                const DataColumn(label: Text('Last sync')),
                DataColumn(label: Text(l10n.actions)),
              ],
              rows: [
                for (final d in devices)
                  DataRow(
                    cells: [
                      DataCell(Text(d.name)),
                      DataCell(Text(d.ipAddress ?? '—')),
                      DataCell(Text('${d.port}')),
                      DataCell(
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(d.status),
                          backgroundColor: d.status == 'active'
                              ? AppColors.success.withValues(alpha: 0.12)
                              : scheme.surfaceContainerHighest,
                          side: BorderSide.none,
                        ),
                      ),
                      DataCell(Text(formatSync(d.lastSyncAt))),
                      DataCell(
                        _DeviceActionsMenu(
                          onTest: () => onTest(d),
                          onSync: () => onSync(d),
                          onLoadUsers: () => onLoadUsers(d),
                          onEdit: () => onEdit(d),
                          onDelete: () => onDelete(d),
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

class _DeviceActionsMenu extends StatelessWidget {
  const _DeviceActionsMenu({
    required this.onTest,
    required this.onSync,
    required this.onLoadUsers,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onTest;
  final VoidCallback onSync;
  final VoidCallback onLoadUsers;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: l10n.actions,
      onSelected: (value) {
        switch (value) {
          case 'test':
            onTest();
          case 'sync':
            onSync();
          case 'users':
            onLoadUsers();
          case 'edit':
            onEdit();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'test', child: Text(l10n.testConnection)),
        PopupMenuItem(value: 'sync', child: Text(l10n.syncNow)),
        PopupMenuItem(value: 'users', child: Text(l10n.deviceUsers)),
        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
        PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
      ],
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.more_vert_rounded),
      ),
    );
  }
}

class _DeviceUsersDialog extends StatefulWidget {
  const _DeviceUsersDialog({
    required this.device,
    required this.users,
    required this.students,
    required this.onSaveMapping,
  });

  final FingerprintDevice device;
  final List<Map<String, dynamic>> users;
  final List<Student> students;
  final Future<void> Function(BiometricMapping mapping) onSaveMapping;

  @override
  State<_DeviceUsersDialog> createState() => _DeviceUsersDialogState();
}

class _DeviceUsersDialogState extends State<_DeviceUsersDialog> {
  late final Map<String, String?> _selectedStudent;

  @override
  void initState() {
    super.initState();
    _selectedStudent = {
      for (final u in widget.users) '${u['user_id']}': null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text('${l10n.deviceUsers} · ${widget.device.name}'),
      content: SizedBox(
        width: 520,
        height: 420,
        child: widget.users.isEmpty
            ? Center(child: Text(l10n.noData))
            : ListView.separated(
                itemCount: widget.users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final u = widget.users[i];
                  final userId = '${u['user_id'] ?? ''}';
                  final name = '${u['name'] ?? ''}';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(name.isEmpty ? userId : name),
                    subtitle: Text('${l10n.deviceUserId}: $userId'),
                    trailing: SizedBox(
                      width: 200,
                      child: Row(
                        children: [
                          Expanded(
                            child: SearchableSelectField<Student>(
                              label: l10n.student,
                              value: widget.students.cast<Student?>().firstWhere(
                                    (s) => s?.id == _selectedStudent[userId],
                                    orElse: () => null,
                                  ),
                              labelOf: (s) => s.name,
                              onSearch: (q) => searchableLocalFilter(
                                items: widget.students,
                                query: q,
                                labelOf: (s) => s.name,
                              ),
                              onChanged: (s) => setState(
                                () => _selectedStudent[userId] = s?.id,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          ScaleTap(
                            onTap: () async {
                              final studentId = _selectedStudent[userId];
                              if (studentId == null) return;
                              await widget.onSaveMapping(
                                BiometricMapping(
                                  id: '',
                                  studentId: studentId,
                                  deviceId: widget.device.id,
                                  deviceUserId: userId,
                                  branchId: widget.device.branchId.isEmpty
                                      ? AppDefaults.branchId
                                      : widget.device.branchId,
                                  status: 'active',
                                ),
                              );
                            },
                            child: AbsorbPointer(
                              child: IconButton(
                                tooltip: l10n.linkStudent,
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.link_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
