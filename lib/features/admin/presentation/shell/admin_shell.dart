import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fingerprint_app/app/di/injection.dart';
import 'package:fingerprint_app/app/theme/app_colors.dart';
import 'package:fingerprint_app/core/responsive/breakpoints.dart';
import 'package:fingerprint_app/core/widgets/app_animations.dart';
import 'package:fingerprint_app/features/admin/presentation/shell/admin_nav.dart';
import 'package:fingerprint_app/features/auth/domain/entities/app_user.dart';
import 'package:fingerprint_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fingerprint_app/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:fingerprint_app/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const _prefsKey = 'admin_sidebar_collapsed';
  var _collapsed = false;

  @override
  void initState() {
    super.initState();
    _loadCollapsed();
  }

  Future<void> _loadCollapsed() async {
    try {
      final prefs = sl<SharedPreferences>();
      final value = prefs.getBool(_prefsKey) ?? false;
      if (mounted) setState(() => _collapsed = value);
    } catch (_) {
      // Ignore preference load failures (e.g. web hot restart).
    }
  }

  Future<void> _setCollapsed(bool value) async {
    setState(() => _collapsed = value);
    try {
      await sl<SharedPreferences>().setBool(_prefsKey, value);
    } catch (_) {}
  }

  void _toggleCollapsed() => _setCollapsed(!_collapsed);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final location = GoRouterState.of(context).uri.toString();
    final selected = AdminNav.indexForLocation(location);
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final user = context.select(
      (AuthCubit c) => c.state is AuthAuthenticated
          ? (c.state as AuthAuthenticated).user
          : null,
    );

    String label(AdminDestination d) => d.labelBuilder(l10n);

    if (AppBreakpoints.isDesktop(width)) {
      return Scaffold(
        backgroundColor: bg,
        body: Row(
          children: [
            _Sidebar(
              selected: selected,
              user: user,
              collapsed: _collapsed,
              onToggle: _toggleCollapsed,
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    showSidebarToggle: true,
                    collapsed: _collapsed,
                    onToggleSidebar: _toggleCollapsed,
                  ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (AppBreakpoints.isTablet(width)) {
      return Scaffold(
        backgroundColor: bg,
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: AppColors.sidebar,
              selectedIndex: selected,
              extended: !_collapsed && width >= 1000,
              onDestinationSelected: (i) =>
                  context.go(AdminNav.destinations[i].path),
              labelType: _collapsed
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Icon(Icons.school_rounded, color: Colors.white),
                  ),
                  IconButton(
                    tooltip: _collapsed
                        ? l10n.expandSidebar
                        : l10n.collapseSidebar,
                    onPressed: _toggleCollapsed,
                    icon: Icon(
                      _collapsed
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              destinations: [
                for (final d in AdminNav.destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon, color: const Color(0xFFB7CBC4)),
                    selectedIcon: Icon(d.icon, color: Colors.white),
                    label: Text(
                      label(d),
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    showSidebarToggle: true,
                    collapsed: _collapsed,
                    onToggleSidebar: _toggleCollapsed,
                  ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(label(AdminNav.destinations[selected])),
        actions: [
          IconButton(
            tooltip: l10n.language,
            onPressed: () => context.read<LocaleCubit>().toggle(),
            icon: const Icon(Icons.language_outlined),
          ),
          IconButton(
            tooltip: l10n.theme,
            onPressed: () => context.read<ThemeCubit>().toggleLightDark(),
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: l10n.logout,
            onPressed: () => context.read<AuthCubit>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.sidebar,
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    (user?.displayName.isNotEmpty ?? false)
                        ? user!.displayName.characters.first
                        : 'A',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  user?.displayName ?? l10n.systemAdmin,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Color(0xFFB7CBC4)),
                ),
              ),
              const Divider(color: Color(0xFF1F5A4C)),
              Expanded(
                child: ListView.builder(
                  itemCount: AdminNav.destinations.length,
                  itemBuilder: (context, i) {
                    final d = AdminNav.destinations[i];
                    final isSelected = i == selected;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: AppColors.sidebarHover,
                      leading: Icon(
                        d.icon,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFB7CBC4),
                      ),
                      title: Text(
                        label(d),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFB7CBC4),
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.go(d.path);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: widget.child,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    this.showSidebarToggle = false,
    this.collapsed = false,
    this.onToggleSidebar,
  });

  final bool showSidebarToggle;
  final bool collapsed;
  final VoidCallback? onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            if (showSidebarToggle && onToggleSidebar != null)
              IconButton(
                tooltip:
                    collapsed ? l10n.expandSidebar : l10n.collapseSidebar,
                onPressed: onToggleSidebar,
                icon: Icon(
                  collapsed
                      ? (isRtl
                          ? Icons.keyboard_double_arrow_left_rounded
                          : Icons.keyboard_double_arrow_right_rounded)
                      : (isRtl
                          ? Icons.keyboard_double_arrow_right_rounded
                          : Icons.keyboard_double_arrow_left_rounded),
                ),
              ),
            const Spacer(),
            IconButton(
              tooltip: l10n.language,
              onPressed: () => context.read<LocaleCubit>().toggle(),
              icon: const Icon(Icons.language_outlined),
            ),
            IconButton(
              tooltip: l10n.theme,
              onPressed: () => context.read<ThemeCubit>().toggleLightDark(),
              icon: Icon(
                theme.brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
            ),
            IconButton(
              tooltip: l10n.settings,
              onPressed: () => context.go('/admin/settings'),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.user,
    required this.collapsed,
    required this.onToggle,
  });

  final int selected;
  final AppUser? user;
  final bool collapsed;
  final VoidCallback onToggle;

  static const _expandedWidth = 268.0;
  static const _collapsedWidth = 72.0;
  static const _labelRevealWidth = 140.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: collapsed ? _collapsedWidth : _expandedWidth,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use actual width during animation so labels/ListTiles never
          // appear while the rail is still narrow.
          final showLabels = constraints.maxWidth >= _labelRevealWidth;

          final brandMark = Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [AppColors.primaryLight, AppColors.accent],
              ),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white),
          );

          final toggleButton = IconButton(
            tooltip: collapsed ? l10n.expandSidebar : l10n.collapseSidebar,
            onPressed: onToggle,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              collapsed
                  ? (isRtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded)
                  : (isRtl
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded),
              color: const Color(0xFFB7CBC4),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  showLabels ? 16 : 8,
                  16,
                  showLabels ? 12 : 8,
                  8,
                ),
                child: showLabels
                    ? Row(
                        children: [
                          brandMark,
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.centerManagement,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          toggleButton,
                        ],
                      )
                    : Column(
                        children: [
                          brandMark,
                          const SizedBox(height: 4),
                          toggleButton,
                        ],
                      ),
              ),
              if (showLabels)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    user?.displayName ?? l10n.systemAdmin,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB7CBC4),
                      fontSize: 13,
                    ),
                  ),
                ),
              const Divider(color: Color(0xFF1F5A4C), height: 1),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: showLabels ? 10 : 8,
                  ),
                  itemCount: AdminNav.destinations.length,
                  itemBuilder: (context, i) {
                    final d = AdminNav.destinations[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _SidebarNavItem(
                        icon: d.icon,
                        label: d.labelBuilder(l10n),
                        selected: i == selected,
                        showLabel: showLabels,
                        isRtl: isRtl,
                        onTap: () => context.go(d.path),
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: Color(0xFF1F5A4C), height: 1),
              _SidebarNavItem(
                icon: Icons.logout,
                label: l10n.logout,
                selected: false,
                showLabel: showLabels,
                isRtl: isRtl,
                onTap: () => context.read<AuthCubit>().signOut(),
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.showLabel,
    required this.isRtl,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool showLabel;
  final bool isRtl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentBorder = BorderSide(color: AppColors.accent, width: 3);
    final color = selected ? Colors.white : const Color(0xFFB7CBC4);

    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 400),
      child: ScaleTap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? 12 : 0,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.sidebarHover : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border(
                    right: isRtl ? accentBorder : BorderSide.none,
                    left: isRtl ? BorderSide.none : accentBorder,
                  )
                : null,
          ),
          child: showLabel
              ? Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(child: Icon(icon, color: color, size: 22)),
        ),
      ),
    );
  }
}
