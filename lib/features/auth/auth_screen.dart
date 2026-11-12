import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/event_category.dart';
import '../../data/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../shell/app_shell.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final repo = ref.read(authRepositoryProvider);
    setState(() => _busy = true);
    try {
      if (_isSignUp) {
        final result = await repo.signUp(
          email: _email.text.trim(),
          password: _password.text,
          displayName: _name.text.trim(),
        );
        if (result == SignUpResult.needsEmailConfirmation && mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.mark_email_read_rounded, size: 40),
              content: Text(l10n.confirmEmailSent, textAlign: TextAlign.center),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.ok),
                ),
              ],
            ),
          );
          if (mounted) setState(() => _isSignUp = false);
        }
      } else {
        await repo.signIn(email: _email.text.trim(), password: _password.text);
      }
      // Başarılı girişte yönlendirmeyi router üstlenir.
    } catch (e) {
      if (mounted) showSnack(context, l10n.errorGeneric(_readableError(e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _readableError(Object e) {
    final text = e.toString();
    final match = RegExp(r'message: ([^,)]+)').firstMatch(text);
    return match?.group(1) ?? text;
  }

  Future<void> _forgotPassword() async {
    final l10n = context.l10n;
    final email = _email.text.trim();
    if (!_isValidEmail(email)) {
      showSnack(context, l10n.errorInvalidEmail);
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (mounted) showSnack(context, l10n.resetEmailSent);
    } catch (e) {
      if (mounted) showSnack(context, l10n.errorGeneric(_readableError(e)));
    }
  }

  static bool _isValidEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDemo = ref.watch(isDemoModeProvider);

    final form = Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppLogo(size: 48),
            const SizedBox(height: 24),
            Text(l10n.authWelcome, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              l10n.authSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l10n.signIn)),
                ButtonSegment(value: true, label: Text(l10n.signUp)),
              ],
              selected: {_isSignUp},
              onSelectionChanged: (s) => setState(() => _isSignUp = s.first),
            ),
            const SizedBox(height: 20),
            if (_isSignUp) ...[
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: InputDecoration(
                  labelText: l10n.displayName,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.errorRequired : null,
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
              ),
              validator: (v) =>
                  _isValidEmail(v?.trim() ?? '') ? null : l10n.errorInvalidEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: [
                _isSignUp ? AutofillHints.newPassword : AutofillHints.password,
              ],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? l10n.errorPasswordShort : null,
            ),
            if (!_isSignUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: Text(l10n.forgotPassword),
                ),
              )
            else
              const SizedBox(height: 16),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(_isSignUp ? l10n.signUp : l10n.signIn),
            ),
            if (isDemo) ...[
              const SizedBox(height: 16),
              Text(
                l10n.demoAdminHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final formPanel = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: form,
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      extendBodyBehindAppBar: context.isWide,
      body: context.isWide
          ? Row(
              children: [
                const Expanded(child: _HeroPanel()),
                Expanded(child: formPanel),
              ],
            )
          : formPanel,
    );
  }
}

/// Geniş ekranda giriş sayfasının sol tarafındaki görsel alan.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B5F6B), AppColors.sea, AppColors.sunset],
          stops: [0, 0.55, 1],
        ),
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in EventCategory.values.take(6))
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(c.icon, color: Colors.white, size: 28),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            l10n.appTagline,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.aboutApp,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
