import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/fields.dart';
import '../auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  final _obscure = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _email = TextEditingController();
    _phone = TextEditingController();
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    final state = ref.read(authProvider).valueOrNull;
    if (state?.authenticated ?? false) {
      context.go('/home');
    } else if (state?.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state!.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    return AuthScaffold(
      title: 'Create account',
      subtitle: 'Join TripGo and start booking your journeys instantly.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Already have an account?', style: AppTypography.captionStyle),
          TextButton(onPressed: () => context.go('/login'), child: const Text('Login')),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TripGoTextField(
              label: 'Full name',
              hint: 'Your name',
              controller: _name,
              validator: validateName,
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
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
              label: 'Mobile number',
              hint: '10-digit mobile',
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: validateMobile,
              prefixIcon: Icons.phone_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            TripGoTextField(
              label: 'Password',
              hint: 'Minimum 6 characters',
              controller: _password,
              validator: validatePassword,
              prefixIcon: Icons.lock_outline_rounded,
              obscure: _obscure,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.xl),
            TripGoButton(label: 'Create account', loading: loading, onPressed: loading ? null : _submit),
          ],
        ),
      ),
    );
  }
}