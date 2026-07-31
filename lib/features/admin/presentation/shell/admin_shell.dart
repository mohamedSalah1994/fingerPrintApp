import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fingerprint_app/app/theme/app_colors.dart';
import 'package:fingerprint_app/core/responsive/breakpoints.dart';
import 'package:fingerprint_app/core/widgets/app_animations.dart';
import 'package:fingerprint_app/features/admin/presentation/shell/admin_nav.dart';
import 'package:fingerprint_app/features/auth/domain/entities/app_user.dart';
import 'package:fingerprint_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fingerprint_app/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:fingerprint_app/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

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
              extended: width >= 1280,
            ),
            Expanded(
              child: Column(
                children: [
                  const _TopBar(),
                  Expanded(child: child),
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
              onDestinationSelected: (i) =>
                  context.go(AdminNav.destinations[i].path),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Icon(Icons.school_rounded, color: Colors.white),
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
                  const _TopBar(),
                  Expanded(child: child),
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
            icon: const Icon(Icons.translate),
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
      body: child,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

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
            const Spacer(),
            IconButton(
              tooltip: l10n.language,
              onPressed: () => context.read<LocaleCubit>().toggle(),
              icon: const Icon(Icons.translate),
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
    required this.extended,
  });

  final int selected;
  final AppUser? user;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: extended ? 268 : 228,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.accent],
                    ),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.centerManagement,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              user?.displayName ?? l10n.systemAdmin,
              style: const TextStyle(
                color: Color(0xFFB7CBC4),
                fontSize: 13,
              ),
            ),
          ),
          const Divider(color: Color(0xFF1F5A4C), height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              itemCount: AdminNav.destinations.length,
              itemBuilder: (context, i) {
                final d = AdminNav.destinations[i];
                final isSelected = i == selected;
                final accentBorder = BorderSide(
                  color: AppColors.accent,
                  width: 3,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ScaleTap(
                    onTap: () => context.go(d.path),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.sidebarHover
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border(
                                right: isRtl ? accentBorder : BorderSide.none,
                                left: isRtl ? BorderSide.none : accentBorder,
                              )
                            : null,
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          d.icon,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFB7CBC4),
                        ),
                        title: Text(
                          d.labelBuilder(l10n),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFFB7CBC4),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Color(0xFF1F5A4C), height: 1),
          ScaleTap(
            onTap: () => context.read<AuthCubit>().signOut(),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFB7CBC4)),
              title: Text(
                l10n.logout,
                style: const TextStyle(color: Color(0xFFB7CBC4)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
