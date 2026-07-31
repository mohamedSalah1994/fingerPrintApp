import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fingerprint_app/app/theme/app_colors.dart';
import 'package:fingerprint_app/core/utils/seed_admin.dart';
import 'package:fingerprint_app/core/widgets/app_animations.dart';
import 'package:fingerprint_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fingerprint_app/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:fingerprint_app/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:fingerprint_app/l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width > 480 ? 440.0 : width - 32;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDark
                ? [
                    AppColors.darkBackground,
                    AppColors.darkSurface,
                    const Color(0xFF0A2A3A),
                  ]
                : const [
                    Color(0xFFE8F5F0),
                    AppColors.background,
                    Color(0xFFE7EEF4),
                  ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.language,
                    onPressed: () => context.read<LocaleCubit>().toggle(),
                    icon: Icon(Icons.translate, color: scheme.onSurface),
                  ),
                  IconButton(
                    tooltip: l10n.theme,
                    onPressed: () =>
                        context.read<ThemeCubit>().toggleLightDark(),
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: FadeSlideIn(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardWidth),
                    child: Material(
                      color: scheme.surface,
                      elevation: 0,
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: scheme.outlineVariant),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.gradientStart,
                                      AppColors.gradientEnd,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.28),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                l10n.appTitle,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.controlPanel,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 28),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [],
                                enableSuggestions: false,
                                autocorrect: false,
                                decoration: InputDecoration(
                                  labelText: l10n.email,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return l10n.enterEmail;
                                  }
                                  if (!v.contains('@')) {
                                    return l10n.invalidEmail;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                autofillHints: const [],
                                enableSuggestions: false,
                                autocorrect: false,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: l10n.password,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return l10n.enterPassword;
                                  }
                                  if (v.length < 6) {
                                    return l10n.passwordTooShort;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, state) {
                                  final loading = state is AuthLoading;
                                  final error = state is AuthError
                                      ? state.message
                                      : null;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (error != null) ...[
                                        FadeSlideIn(
                                          offsetY: 6,
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.danger
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.danger
                                                    .withValues(alpha: 0.25),
                                              ),
                                            ),
                                            child: Text(
                                              error,
                                              style: const TextStyle(
                                                color: AppColors.danger,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      ScaleTap(
                                        onTap: loading ? null : _submit,
                                        child: AbsorbPointer(
                                          absorbing: true,
                                          child: FilledButton(
                                            onPressed:
                                                loading ? null : _submit,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 4,
                                              ),
                                              child: loading
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : Text(l10n.login),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (kDebugMode) ...[
                                        const SizedBox(height: 10),
                                        TextButton(
                                          onPressed: loading
                                              ? null
                                              : () async {
                                                  final email =
                                                      _emailController
                                                              .text
                                                              .trim()
                                                              .isEmpty
                                                          ? 'admin@center.com'
                                                          : _emailController
                                                              .text
                                                              .trim();
                                                  final password =
                                                      _passwordController
                                                              .text
                                                              .isEmpty
                                                          ? 'Admin123!'
                                                          : _passwordController
                                                              .text;
                                                  try {
                                                    await seedAdminAndBranch(
                                                      email: email,
                                                      password: password,
                                                      displayName:
                                                          l10n.systemAdmin,
                                                    );
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    _emailController.text =
                                                        email;
                                                    _passwordController.text =
                                                        password;
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          l10n.adminSetupDone,
                                                        ),
                                                      ),
                                                    );
                                                    context
                                                        .read<AuthCubit>()
                                                        .signIn(
                                                          email: email,
                                                          password: password,
                                                        );
                                                  } catch (e) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          describeFirebaseError(
                                                            e,
                                                          ),
                                                        ),
                                                        backgroundColor:
                                                            AppColors.danger,
                                                      ),
                                                    );
                                                  }
                                                },
                                          child: Text(l10n.seedAdminDev),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
