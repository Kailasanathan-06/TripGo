import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class TripGoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Gradient? gradient;

  const TripGoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white, valueColor: AlwaysStoppedAnimation(AppColors.white)),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.white),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.white)),
            ],
          );
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient ?? AppColors.gradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: SizedBox(height: 52, width: double.infinity, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}

class TripGoOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const TripGoOutlinedButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
      label: Text(label, style: AppTypography.bodyMedium),
    );
  }
}

class TripGoStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const TripGoStatusChip({super.key, required this.label, required this.color});

  factory TripGoStatusChip.fromState(String state) {
    switch (state.toUpperCase()) {
      case 'CONFIRMED':
        return TripGoStatusChip(label: 'Confirmed', color: AppColors.success);
      case 'CANCELLED':
        return TripGoStatusChip(label: 'Cancelled', color: AppColors.error);
      case 'HELD':
      case 'PAYMENT_PENDING':
        return TripGoStatusChip(label: 'Payment Pending', color: AppColors.warning);
      case 'EXPIRED':
        return TripGoStatusChip(label: 'Expired', color: AppColors.textSecondary);
      default:
        return TripGoStatusChip(label: state, color: AppColors.electricBlue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTypography.smallStyle.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}