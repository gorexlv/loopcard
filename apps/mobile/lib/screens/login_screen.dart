import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/loop_theme.dart';
import '../widgets/app_page.dart';
import '../widgets/glass_surface.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _createAccount = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!email.contains('@') || password.length < 8) {
      setState(() => _error = context.l10n.tr('authValidation'));
      return;
    }
    await _run(() {
      if (_createAccount) {
        return widget.authService.signUpWithEmail(
          email: email,
          password: password,
        );
      }
      return widget.authService.signInWithEmail(
        email: email,
        password: password,
      );
    });
  }

  Future<void> _provider(AppAuthProvider provider) =>
      _run(() => widget.authService.signInWithProvider(provider));

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object error) {
    final value = error.toString().toLowerCase();
    if (value.contains('invalid login') || value.contains('credentials')) {
      return context.l10n.tr('authInvalidCredentials');
    }
    if (value.contains('provider is not enabled') ||
        value.contains('unsupported provider')) {
      return context.l10n.tr('authProviderUnavailable');
    }
    return context.l10n.tr('authFailed');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.loopColors;
    return AppPage(
      branded: true,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _createAccount
                    ? l10n.tr('authCreateTitle')
                    : l10n.tr('authWelcomeTitle'),
                style: TextStyle(
                  fontSize: 31,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.tr('authSubtitle'),
                style: TextStyle(fontSize: 14, color: palette.muted),
              ),
            ],
          ),
          const SizedBox(height: 28),
          GlassSurface(
            radius: 30,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              child: Column(
                children: [
                  _AuthField(
                    key: const ValueKey('login-email'),
                    controller: _emailController,
                    label: l10n.tr('authEmail'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _AuthField(
                    key: const ValueKey('login-password'),
                    controller: _passwordController,
                    label: l10n.tr('authPassword'),
                    obscureText: _obscurePassword,
                    suffix: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: palette.muted,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _error == null
                          ? const SizedBox.shrink()
                          : Text(
                              _error!,
                              maxLines: 2,
                              style: const TextStyle(
                                fontSize: 12,
                                color: LoopTheme.coral,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      key: const ValueKey('login-submit'),
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: LoopTheme.teal,
                        foregroundColor: const Color(0xFF07130F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF07130F),
                              ),
                            )
                          : Text(
                              _createAccount
                                  ? l10n.tr('authCreateAction')
                                  : l10n.tr('authSignInAction'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                            _createAccount = !_createAccount;
                            _error = null;
                          }),
                    child: Text(
                      _createAccount
                          ? l10n.tr('authHaveAccount')
                          : l10n.tr('authNeedAccount'),
                      style: TextStyle(color: palette.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: Divider(color: palette.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.tr('authOr'),
                      style: TextStyle(fontSize: 12, color: palette.subtle),
                    ),
                  ),
                  Expanded(child: Divider(color: palette.divider)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ProviderButton(
                      label: 'Google',
                      symbol: 'G',
                      onTap: _loading
                          ? null
                          : () => _provider(AppAuthProvider.google),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProviderButton(
                      label: 'Apple',
                      symbol: '',
                      onTap: _loading
                          ? null
                          : () => _provider(AppAuthProvider.apple),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                l10n.tr('authTerms'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: palette.subtle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: false,
      enableSuggestions: !obscureText,
      style: TextStyle(fontSize: 15, color: context.loopColors.ink),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        filled: true,
        fillColor: context.loopColors.glass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.loopColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.loopColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LoopTheme.teal),
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.symbol,
    required this.onTap,
  });

  final String label;
  final String symbol;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          foregroundColor: context.loopColors.ink,
          side: BorderSide(color: context.loopColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              symbol,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
