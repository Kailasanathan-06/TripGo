import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum SeatState { available, selected, booked, ladies, male, unavailable, held }

SeatState seatStateFromStatus(String status, {String gender = ''}) {
  switch (status.toUpperCase()) {
    case 'BOOKED':
      return SeatState.booked;
    case 'HELD':
      return SeatState.held;
    case 'UNAVAILABLE':
      return SeatState.unavailable;
    default:
      return SeatState.available;
  }
}

class SeatStyle {
  static Color color(SeatState state, {required bool selected}) {
    switch (state) {
      case SeatState.selected:
        return AppColors.success;
      case SeatState.booked:
        return AppColors.border;
      case SeatState.ladies:
        return const Color(0xFFF9A8D4);
      case SeatState.male:
        return const Color(0xFF93C5FD);
      case SeatState.held:
        return AppColors.warning;
      case SeatState.unavailable:
        return const Color(0xFFCBD5E1);
      default:
        return AppColors.royalBlue;
    }
  }

  static bool selectable(SeatState state) =>
      state == SeatState.available || state == SeatState.selected;

  static String icon(SeatState state) {
    switch (state) {
      case SeatState.unavailable:
        return '—';
      default:
        return '';
    }
  }
}

class TripGoSeat extends StatelessWidget {
  final String label;
  final SeatState state;
  final bool selected;
  final VoidCallback onTap;

  const TripGoSeat({
    super.key,
    required this.label,
    required this.state,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = SeatStyle.color(state, selected: selected);
    final interactive = SeatStyle.selectable(state);
    return Semantics(
      label: 'Seat $label',
      button: true,
      enabled: interactive,
      child: AnimatedScale(
        scale: selected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 38,
          height: 38,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? color : (state == SeatState.unavailable ? color : color.withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.55),
              width: selected ? 2 : 1.2,
            ),
          ),
          child: InkWell(
            onTap: interactive ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Center(
              child: Text(
                label,
                style: AppTypography.smallStyle.copyWith(
                  color: selected ? AppColors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TripGoBerth extends StatelessWidget {
  final String label;
  final SeatState state;
  final bool selected;
  final VoidCallback onTap;

  const TripGoBerth({
    super.key,
    required this.label,
    required this.state,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = SeatStyle.color(state, selected: selected);
    final interactive = SeatStyle.selectable(state);
    return Semantics(
      label: 'Berth $label',
      button: true,
      enabled: interactive,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? color : (state == SeatState.unavailable ? color : color.withValues(alpha: 0.16)),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color, width: selected ? 2 : 1.2),
        ),
        child: InkWell(
          onTap: interactive ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Center(
            child: Text(
              label.replaceAll(RegExp(r'[0-9]'), ''),
              style: AppTypography.smallStyle.copyWith(
                color: selected ? AppColors.white : color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(SeatState s, String label) {
      final color = SeatStyle.color(s, selected: false);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: s == SeatState.available ? AppColors.lightBlue : color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: s == SeatState.available ? AppColors.royalBlue : color),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.captionStyle),
        ],
      );
    }

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        item(SeatState.available, 'Available'),
        item(SeatState.selected, 'Selected'),
        item(SeatState.booked, 'Booked'),
        item(SeatState.unavailable, 'Unavailable'),
      ],
    );
  }
}