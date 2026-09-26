import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_bootstrap.dart';
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
    try {
      await ApiBootstrap.ensureReady(onProgress: _setStatus);
    } on ApiBootstrapException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.detail.isEmpty ? e.message : '${e.message}\n\n${e.detail.trim()}';
      });
      return;
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

  @override
  void dispose() {
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
                    _BootStatus(error: _error, message: _status, retrying: _retrying, onRetry: _retry),
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

class _BootStatus extends StatelessWidget {
  const _BootStatus({
    required this.error,
    required this.message,
    required this.retrying,
    required this.onRetry,
  });

  final String? error;
  final String message;
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

    return Row(
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionStyle.copyWith(color: AppColors.lightBlue),
          ),
        ),
      ],
    );
  }
}
