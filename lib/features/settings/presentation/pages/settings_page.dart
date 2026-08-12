import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fingerprint_app/app/theme/app_colors.dart';
import 'package:fingerprint_app/core/widgets/app_animations.dart';
import 'package:fingerprint_app/features/admin/presentation/widgets/admin_page_frame.dart';
import 'package:fingerprint_app/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:fingerprint_app/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AdminPageFrame(
      title: l10n.settings,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FadeSlideIn(
            child: Text(
              l10n.preferences,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.language,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<LocaleCubit, LocaleState>(
                      builder: (context, state) {
                        return SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'ar',
                              label: Text(l10n.arabic),
                              icon: const Icon(Icons.language_outlined),
                            ),
                            ButtonSegment(
                              value: 'en',
                              label: Text(l10n.english),
                              icon: const Icon(Icons.language_outlined),
                            ),
                          ],
                          selected: {state.locale.languageCode},
                          onSelectionChanged: (value) {
                            context.read<LocaleCubit>().setLocale(
                                  Locale(value.first),
                                );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.appearance,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<ThemeCubit, ThemeState>(
                      builder: (context, state) {
                        return SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(l10n.lightMode),
                              icon: const Icon(Icons.light_mode_outlined),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(l10n.darkMode),
                              icon: const Icon(Icons.dark_mode_outlined),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(l10n.systemMode),
                              icon: const Icon(Icons.settings_suggest_outlined),
                            ),
                          ],
                          selected: {state.themeMode},
                          onSelectionChanged: (value) {
                            context
                                .read<ThemeCubit>()
                                .setThemeMode(value.first);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${l10n.theme}: ${switch (context.watch<ThemeCubit>().state.themeMode) {
                                ThemeMode.light => l10n.lightMode,
                                ThemeMode.dark => l10n.darkMode,
                                ThemeMode.system => l10n.systemMode,
                              }}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          ScaleTap(
                            onTap: () =>
                                context.read<ThemeCubit>().toggleLightDark(),
                            child: Icon(
                              theme.brightness == Brightness.dark
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
