import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/fields.dart';
import '../auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _password;
  final _obscure = true;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController();
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).login(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;
    final state = ref.read(authProvider).valueOrNull;
    if (state?.authenticated ?? false) {
      context.go('/home');
    } else if (state?.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state!.error!)));
    }
  }

  void _fillDemo() {
    setState(() {
      _email.text = 'demo@tripgo.app';
      _password.text = 'demo12345';
    });
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    final auth = ref.watch(authProvider).valueOrNull;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/welcome');
      },
      child: AuthScaffold(
        title: 'Welcome back',
        subtitle: 'Login to book your next journey with TripGo.',
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('New to TripGo?', style: AppTypography.captionStyle),
            TextButton(onPressed: () => context.go('/register'), child: const Text('Create account')),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TripGoTextField(
                label: 'Email address',
                hint: 'you@example.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
                prefixIcon: Icons.mail_outline_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              TripGoTextField(
                label: 'Password',
                controller: _password,
                validator: validatePassword,
                prefixIcon: Icons.lock_outline_rounded,
                obscure: _obscure,
                textInputAction: TextInputAction.done,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: const Text('Forgot password?'),
                ),
              ),
              if (auth?.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(auth!.error!, style: AppTypography.bodyStyle.copyWith(color: AppColors.error))),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TripGoButton(
                label: 'Login',
                loading: loading,
                onPressed: loading ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: _fillDemo,
                icon: const Icon(Icons.science_outlined, size: 18),
                label: const Text('Use demo account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}