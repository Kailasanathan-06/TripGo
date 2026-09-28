import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_bootstrap.dart';
import '../../core/network/server_override.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  String _status = 'Starting the TripGo server';
  String? _error;
  bool _retrying = false;

  /// Ticks once a second for as long as the API is coming up, so a cold start that
  /// is genuinely slow can be told apart from one that has stopped. A bare spinner
  /// with a frozen line of text is indistinguishable from a hang, which is exactly
  /// the ambiguity that made this hard to diagnose.
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.7, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.6, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _bootstrap();
  }

  /// Brings the embedded API online, then routes to the right place.
  ///
  /// The server lives inside this process, so it only has to be warmed up once per
  /// launch; there is nothing to connect to over a network.
  Future<void> _bootstrap() async {
    _startElapsedTimer();
    try {
      // Read before the first attempt: a stored address has to be known up front or
      // the app would start its own slow server before noticing it is overridden.
      await ServerOverride.load();
      await ApiBootstrap.ensureReady(onProgress: _setStatus);
    } on ApiBootstrapException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.detail.isEmpty ? e.message : '${e.message}\n\n${e.detail.trim()}';
      });
      return;
    } finally {
      _elapsedTimer?.cancel();
    }

    // Let the logo animation finish before leaving the splash screen.
    try {
      await _controller.forward().orCancel;
    } catch (_) {
      // The controller was disposed because the screen went away first.
    }
    await ref.read(authProvider.future);
    if (!mounted) return;
    final state = ref.read(authProvider).valueOrNull;
    if (state?.authenticated ?? false) {
      context.go('/home');
    } else {
      context.go('/welcome');
    }
  }

  void _setStatus(String message) {
    if (!mounted || message == _status) return;
    setState(() => _status = message);
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedSeconds = 0;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _retry() async {
    setState(() {
      _retrying = true;
      _error = null;
      _status = 'Starting the TripGo server';
    });
    ApiBootstrap.reset();
    await _bootstrap();
    if (mounted) setState(() => _retrying = false);
  }

  /// Lets the user point the app at a TripGo server on their computer, or send it
  /// back to the one inside the APK.
  ///
  /// Changing this has to restart the attempt, so the dialog saves first and then
  /// clears whatever was already resolved.
  Future<void> _editServerOverride() async {
    final field = TextEditingController(text: ServerOverride.hostPort ?? '');
    String? problem;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkNavy,
          title: Text('Use a server on my computer', style: AppTypography.bodyStyle.copyWith(color: AppColors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Run "python manage.py runserver 0.0.0.0:8000" on your laptop, then '
                'enter its address in this Wi-Fi network, for example 192.168.1.5:8000.',
                style: AppTypography.captionStyle.copyWith(color: AppColors.lightBlue),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: field,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: '192.168.1.5:8000',
                  hintStyle: TextStyle(color: AppColors.lightBlue.withValues(alpha: 0.5)),
                  errorText: problem,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Leave this empty to use the server built into the app.',
                style: AppTypography.captionStyle.copyWith(
                  color: AppColors.lightBlue.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  ServerOverride.normaliseForPreview(field.text);
                  Navigator.of(context).pop(true);
                } on FormatException catch (e) {
                  setDialogState(() => problem = e.message);
                }
              },
              child: const Text('Connect'),
            ),
          ],
        ),
      ),
    );

    if (accepted != true) {
      field.dispose();
      return;
    }

    try {
      await ServerOverride.save(field.text);
    } on FormatException catch (e) {
      if (mounted) {
        setState(() => _error = 'That address cannot be used: ${e.message}');
        field.dispose();
        return;
      }
    }
    field.dispose();
    if (!mounted) return;
    ApiBootstrap.reset();
    await _retry();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.royalBlue, AppColors.cyan]),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(color: AppColors.royalBlue.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 12)),
                        ],
                      ),
                      child: const Icon(Icons.route_rounded, size: 64, color: AppColors.white),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'TRIPGO',
                      style: AppTypography.displayStyle.copyWith(color: AppColors.white, letterSpacing: 4),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Your Journey. One Smart Ticket.',
                      style: AppTypography.captionStyle.copyWith(color: AppColors.lightBlue),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _BootStatus(
                      error: _error,
                      message: _status,
                      elapsedSeconds: _elapsedSeconds,
                      retrying: _retrying,
                      onRetry: _retry,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ServerControl(
                      hostPort: ServerOverride.hostPort,
                      onEdit: _editServerOverride,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows which server the app will use and lets the address be changed.
class _ServerControl extends StatelessWidget {
  const _ServerControl({required this.hostPort, required this.onEdit});

  final String? hostPort;
  final Future<void> Function() onEdit;

  @override
  Widget build(BuildContext context) {
    final usingRemote = hostPort != null;
    return TextButton.icon(
      onPressed: onEdit,
      icon: Icon(
        usingRemote ? Icons.dns_rounded : Icons.smartphone_rounded,
        size: 14,
        color: AppColors.lightBlue,
      ),
      label: Text(
        usingRemote ? 'Server: $hostPort' : 'Using the server in this app',
        style: AppTypography.captionStyle.copyWith(
          color: AppColors.lightBlue.withValues(alpha: 0.8),
          fontSize: 11,
        ),
      ),
    );
  }
}

class _BootStatus extends StatelessWidget {
  const _BootStatus({
    required this.error,
    required this.message,
    required this.elapsedSeconds,
    required this.retrying,
    required this.onRetry,
  });

  final String? error;
  final String message;
  final int elapsedSeconds;
  final bool retrying;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error!,
            textAlign: TextAlign.center,
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionStyle.copyWith(color: AppColors.lightBlue),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: retrying ? null : onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lightBlue),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionStyle.copyWith(color: AppColors.lightBlue),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Starting up · ${elapsedSeconds}s',
          textAlign: TextAlign.center,
          style: AppTypography.captionStyle.copyWith(
            color: AppColors.lightBlue.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
