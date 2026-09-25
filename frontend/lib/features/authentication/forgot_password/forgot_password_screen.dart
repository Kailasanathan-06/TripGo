import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/services/services.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/fields.dart';
import '../auth_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  var _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthRepository().forgotPassword(_email.text.trim());
      if (!mounted) return;
      context.go('/otp', extra: _email.text.trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Forgot password',
      subtitle: "Enter your registered email and we'll send you a one-time OTP.",
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TripGoTextField(
              label: 'Email address',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
              prefixIcon: Icons.mail_outline_rounded,
            ),
            const SizedBox(height: AppSpacing.xl),
            TripGoButton(label: 'Send OTP', loading: _loading, onPressed: _loading ? null : _submit),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => context.pop(),
              child: Text('Back to login', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _otp = TextEditingController();
  final _password = TextEditingController();
  var _loading = false;

  @override
  void initState() {
    super.initState();
    final extra = GoRouterState.of(context).extra;
    _email = TextEditingController(text: extra is String ? extra : '');
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthRepository().verifyOtp(email: _email.text.trim(), otp: _otp.text.trim(), newPassword: _password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. Please login.')));
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Verify OTP',
      subtitle: 'Enter the 6-digit code sent to your email and set a new password.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TripGoTextField(
              label: 'Email address',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
              prefixIcon: Icons.mail_outline_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            TripGoTextField(
              label: 'OTP',
              hint: '6-digit code',
              controller: _otp,
              keyboardType: TextInputType.number,
              validator: (v) => (v ?? '').length == 6 ? null : 'Enter the 6-digit OTP',
              prefixIcon: Icons.password_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            TripGoTextField(
              label: 'New password',
              controller: _password,
              validator: validatePassword,
              obscure: true,
              prefixIcon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: AppSpacing.xl),
            TripGoButton(label: 'Reset password', loading: _loading, onPressed: _loading ? null : _submit),
          ],
        ),
      ),
    );
  }
}