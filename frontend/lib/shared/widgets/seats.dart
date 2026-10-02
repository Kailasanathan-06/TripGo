import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum SeatState { available, selected, booked, ladies, male, unavailable, held }

SeatState seatStateFromStatus(String status, {String gender = ''}) {
  final s = status.toUpperCase();
  final g = gender.toUpperCase();
  if (s == 'BOOKED') {
    if (g == 'F' || g == 'FEMALE') {
      return SeatState.ladies;
    }
    return SeatState.booked;
  }
  if (s == 'HELD') return SeatState.held;
  if (s == 'UNAVAILABLE') return SeatState.unavailable;
  if (g == 'F' || g == 'FEMALE') {
    return SeatState.ladies;
  }
  return SeatState.available;
}

class SeatStyle {
  static Color color(SeatState state, {required bool selected}) {
    if (selected) return AppColors.success;
    switch (state) {
      case SeatState.selected:
        return AppColors.success;
      case SeatState.booked:
        return const Color(0xFF94A3B8);
      case SeatState.ladies:
        return const Color(0xFFDB2777);
      case SeatState.male:
        return const Color(0xFF2563EB);
      case SeatState.held:
        return AppColors.warning;
      case SeatState.unavailable:
        return const Color(0xFF94A3B8);
      default:
        return AppColors.royalBlue;
    }
  }

  static Color bgColor(SeatState state, {required bool selected}) {
    if (selected) return AppColors.success;
    switch (state) {
      case SeatState.booked:
        return const Color(0xFFF1F5F9);
      case SeatState.ladies:
        return const Color(0xFFFDF2F8);
      case SeatState.male:
        return const Color(0xFFEFF6FF);
      case SeatState.held:
        return const Color(0xFFFEF3C7);
      case SeatState.unavailable:
        return const Color(0xFFF1F5F9);
      default:
        return AppColors.white;
    }
  }

  static Color borderColor(SeatState state, {required bool selected}) {
    if (selected) return const Color(0xFF16A34A);
    switch (state) {
      case SeatState.booked:
        return const Color(0xFFCBD5E1);
      case SeatState.ladies:
        return const Color(0xFFF472B6);
      case SeatState.male:
        return const Color(0xFF93C5FD);
      case SeatState.held:
        return AppColors.warning;
      case SeatState.unavailable:
        return const Color(0xFFCBD5E1);
      default:
        return AppColors.royalBlue.withValues(alpha: 0.55);
    }
  }

  static bool selectable(SeatState state) =>
      state == SeatState.available || state == SeatState.selected;
}

/// Helper to parse train berth numbers like "1L", "3LB", "4MB", "6SU", "7SL", "24"
class BerthLabelInfo {
  final String number;
  final String typeCode;
  final String typeName;

  const BerthLabelInfo({
    required this.number,
    required this.typeCode,
    required this.typeName,
  });

  factory BerthLabelInfo.parse(String raw) {
    final s = raw.trim();
    final match = RegExp(r'^([A-Za-z]*)(\d+)([A-Za-z]*)$').firstMatch(s);
    if (match != null) {
      final prefix = match.group(1) ?? '';
      final digits = match.group(2) ?? '';
      final suffix = match.group(3) ?? '';
      var code = (suffix.isNotEmpty ? suffix : prefix).toUpperCase();

      if (code == 'L') code = 'LB';
      if (code == 'M') code = 'MB';
      if (code == 'U') code = 'UB';
      if (code == 'S') code = 'SL';

      return BerthLabelInfo(
        number: digits.isNotEmpty ? digits : s,
        typeCode: code,
        typeName: _typeName(code),
      );
    }
    return BerthLabelInfo(number: s, typeCode: '', typeName: 'Berth');
  }

  static String _typeName(String code) {
    switch (code) {
      case 'LB':
        return 'Lower';
      case 'MB':
        return 'Middle';
      case 'UB':
        return 'Upper';
      case 'SL':
        return 'Side Lower';
      case 'SU':
        return 'Side Upper';
      case 'W':
      case 'WS':
        return 'Window';
      case 'A':
      case 'AS':
        return 'Aisle';
      default:
        return code.isNotEmpty ? code : 'Berth';
    }
  }
}

/// Realistic bus seat widget with chair shape, headrest cushion, armrests and clear labels.
class TripGoSeat extends StatelessWidget {
  final String label;
  final SeatState state;
  final bool selected;
  final VoidCallback onTap;
  final bool isSleeper;

  const TripGoSeat({
    super.key,
    required this.label,
    required this.state,
    required this.selected,
    required this.onTap,
    this.isSleeper = false,
  });

  @override
  Widget build(BuildContext context) {
    final interactive = SeatStyle.selectable(state);
    final bg = SeatStyle.bgColor(state, selected: selected);
    final border = SeatStyle.borderColor(state, selected: selected);
    final textColor = selected
        ? AppColors.white
        : (state == SeatState.booked || state == SeatState.unavailable
            ? const Color(0xFF94A3B8)
            : (state == SeatState.ladies ? const Color(0xFFDB2777) : AppColors.royalBlue));

    if (isSleeper) {
      return _buildSleeper(context, interactive, bg, border, textColor);
    }
    return _buildSeater(context, interactive, bg, border, textColor);
  }

  Widget _buildSeater(
    BuildContext context,
    bool interactive,
    Color bg,
    Color border,
    Color textColor,
  ) {
    return Semantics(
      label: 'Seat $label, ${state.name}',
      button: true,
      enabled: interactive,
      child: AnimatedScale(
        scale: selected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 44,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: interactive ? onTap : null,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border, width: selected ? 2 : 1.4),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    else if (interactive)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    // Headrest notch at top of seat
                    Container(
                      height: 5,
                      margin: const EdgeInsets.only(top: 2, left: 6, right: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.45)
                            : border.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    // Seat bottom cushion accent
                    if (selected)
                      Container(
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 2, left: 8, right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                    else if (state == SeatState.ladies)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Icon(Icons.female, size: 10, color: Color(0xFFDB2777)),
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

  Widget _buildSleeper(
    BuildContext context,
    bool interactive,
    Color bg,
    Color border,
    Color textColor,
  ) {
    return Semantics(
      label: 'Sleeper berth $label, ${state.name}',
      button: true,
      enabled: interactive,
      child: AnimatedScale(
        scale: selected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 44,
          height: 72,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: interactive ? onTap : null,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border, width: selected ? 2 : 1.4),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    // Pillow / Headrest cushion
                    Container(
                      height: 12,
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.3)
                            : border.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.single_bed_rounded,
                          size: 10,
                          color: selected ? Colors.white : border,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'SLEEP',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w600,
                          fontSize: 8,
                          letterSpacing: 0.5,
                        ),
                      ),
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

/// Realistic Train Berth widget displaying both Berth Number and Berth Type badge (e.g. LB, MB, UB, SL, SU).
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
    final interactive = SeatStyle.selectable(state);
    final bg = SeatStyle.bgColor(state, selected: selected);
    final border = SeatStyle.borderColor(state, selected: selected);
    final info = BerthLabelInfo.parse(label);

    final numberColor = selected
        ? AppColors.white
        : (state == SeatState.booked || state == SeatState.unavailable
            ? const Color(0xFF94A3B8)
            : (state == SeatState.ladies ? const Color(0xFFDB2777) : AppColors.textPrimary));

    final badgeTextColor = selected
        ? Colors.white
        : (state == SeatState.booked || state == SeatState.unavailable
            ? const Color(0xFF64748B)
            : AppColors.royalBlue);

    final badgeBgColor = selected
        ? Colors.white.withValues(alpha: 0.25)
        : (state == SeatState.booked
            ? const Color(0xFFE2E8F0)
            : AppColors.lightBlue);

    return Semantics(
      label: 'Berth ${info.number} ${info.typeName}, ${state.name}',
      button: true,
      enabled: interactive,
      child: AnimatedScale(
        scale: selected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 58,
          height: 52,
          margin: const EdgeInsets.all(3),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: interactive ? onTap : null,
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: border, width: selected ? 2.0 : 1.3),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    else if (interactive)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    // Pillow bar on the left indicating train sleeper berth headrest
                    Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.5)
                            : (state == SeatState.booked
                                ? const Color(0xFFCBD5E1)
                                : AppColors.royalBlue.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Berth Number (clearly visible)
                          Text(
                            info.number,
                            style: TextStyle(
                              color: numberColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Berth Type Badge (e.g. LB, MB, UB, SL, SU)
                          if (info.typeCode.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: badgeBgColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                info.typeCode,
                                style: TextStyle(
                                  color: badgeTextColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 8.5,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                        ],
                      ),
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

/// A comprehensive legend widget for seat & berth state
class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(Color bg, Color border, Color text, String label, {Widget? icon}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: border, width: 1.2),
            ),
            child: Center(
              child: icon ??
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: border,
                      shape: BoxShape.circle,
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 5),
          Text(label, style: AppTypography.captionStyle),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          item(AppColors.white, AppColors.royalBlue, AppColors.royalBlue, 'Available'),
          const SizedBox(width: AppSpacing.md),
          item(
            AppColors.success,
            const Color(0xFF16A34A),
            Colors.white,
            'Selected',
            icon: const Icon(Icons.check, size: 11, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          item(const Color(0xFFF1F5F9), const Color(0xFFCBD5E1), const Color(0xFF64748B), 'Booked'),
          const SizedBox(width: AppSpacing.md),
          item(
            const Color(0xFFFDF2F8),
            const Color(0xFFF472B6),
            const Color(0xFFDB2777),
            'Ladies',
            icon: const Icon(Icons.female, size: 10, color: Color(0xFFDB2777)),
          ),
        ],
      ),
    );
  }
}