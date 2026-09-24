import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'buttons.dart';

class TripGoLoading extends StatelessWidget {
  final String message;

  const TripGoLoading({super.key, this.message = 'Loading…'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.royalBlue),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(message, style: AppTypography.captionStyle),
        ],
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => _skeletonCard(),
    );
  }

  Widget _skeletonCard() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _ShimmerBox(40, 40, circle: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _skeletonLines(2)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _skeletonLines(3),
        ],
      ),
    );
  }

  Widget _skeletonLines(int count) => Column(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Align(alignment: Alignment.centerLeft, child: _ShimmerBox(200, 12)),
            ),
        ],
      );
}

class _ShimmerBox extends StatefulWidget {
  final double width, height;
  final bool circle;

  const _ShimmerBox(this.width, this.height, {this.circle = false});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: 0.4 + 0.3 * _controller.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.6),
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.circle ? null : BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }
}

class TripGoErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  const TripGoErrorState({super.key, required this.message, this.onRetry, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.royalBlue),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Something went wrong', style: AppTypography.titleStyle),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTypography.captionStyle, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            if (onRetry != null)
              SizedBox(width: 200, child: TripGoButton(label: 'Retry', onPressed: onRetry)),
            if (onBack != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: TextButton(onPressed: onBack, child: const Text('Go back')),
              ),
          ],
        ),
      ),
    );
  }
}

class TripGoEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  const TripGoEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
              child: Icon(icon, size: 44, color: AppColors.royalBlue),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTypography.titleStyle, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTypography.captionStyle, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}