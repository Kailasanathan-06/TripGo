import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
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

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  String _status = 'Connecting to TripGo server\u2026';
  String? _error;
  bool _retrying = false;

  static const _maxAutoAttempts = 0;
  static const _retryDelay = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _fade = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.6, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap({int attempt = 1}) async {
    try {
      await ApiBootstrap.ensureReady(
        healthTimeout: const Duration(seconds: 4),
        onProgress: _setStatus,
      );
    } on ApiBootstrapException catch (e) {
      if (!mounted) return;
      if (attempt <= _maxAutoAttempts) {
        _setStatus(
            'Retrying\u2026 (attempt ${attempt + 1} of ${_maxAutoAttempts + 1})');
        await Future<void>.delayed(_retryDelay * attempt);
        if (!mounted) return;
        ApiBootstrap.reset();
        return _bootstrap(attempt: attempt + 1);
      }
      setState(() {
        _error =
            e.detail.isEmpty ? e.message : '${e.message}\n\n${e.detail.trim()}';
      });
      return;
    }

    // Let the animation finish, then decide where to route.
    try {
      await _controller.forward().orCancel;
    } catch (_) {}
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
      _status = 'Connecting to TripGo server\u2026';
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
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── App logo ──
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.royalBlue, AppColors.cyan]),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.royalBlue.withValues(alpha: 0.5),
                              blurRadius: 40,
                              offset: const Offset(0, 12)),
                        ],
                      ),
                      child: const Icon(Icons.route_rounded,
                          size: 64, color: AppColors.white),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'TRIPGO',
                      style: AppTypography.displayStyle
                          .copyWith(color: AppColors.white, letterSpacing: 4),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppConstants.tagline,
                      style: AppTypography.captionStyle
                          .copyWith(color: AppColors.lightBlue),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _BootStatus(
                      error: _error,
                      message: _status,
                      retrying: _retrying,
                      onRetry: _retry,
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

class _BootStatus extends StatefulWidget {
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
  State<_BootStatus> createState() => _BootStatusState();
}

class _BootStatusState extends State<_BootStatus> {
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ipController.text = ApiBootstrap.baseUrl;
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.error != null) {
      return Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.error!,
            textAlign: TextAlign.center,
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionStyle
                .copyWith(color: AppColors.lightBlue),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: TextField(
              controller: _ipController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                labelText: 'Server API URL',
                labelStyle: TextStyle(color: AppColors.white.withOpacity(0.7)),
                filled: true,
                fillColor: AppColors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: widget.retrying ? null : () {
              ApiBootstrap.updateBaseUrl(_ipController.text);
              widget.onRetry();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Update IP & Retry'),
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
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.lightBlue),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionStyle
                    .copyWith(color: AppColors.lightBlue),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
