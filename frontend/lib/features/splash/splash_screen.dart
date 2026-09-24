import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    await ref.read(authProvider.future);
    if (!mounted) return;
    final state = ref.read(authProvider).valueOrNull;
    if (state?.authenticated ?? false) {
      context.go('/home');
    } else {
      context.go('/welcome');
    }
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}