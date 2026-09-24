import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/feedback.dart';
import '../providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripGoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? trailing;
  final bool showBack;

  const TripGoAppBar({super.key, required this.title, this.trailing, this.showBack = true});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      title: Text(title),
      actions: [if (trailing != null) trailing!],
    );
  }
}

class TripGoBottomNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const TripGoBottomNav({super.key, required this.currentIndex, required this.onTap});

  static const tabs = [
    (icon: Icons.home_rounded, selected: Icons.home_rounded, label: 'Home'),
    (icon: Icons.confirmation_number_outlined, selected: Icons.confirmation_number_rounded, label: 'Bookings'),
    (icon: Icons.local_offer_outlined, selected: Icons.local_offer_rounded, label: 'Offers'),
    (icon: Icons.notifications_none_rounded, selected: Icons.notifications_rounded, label: 'Inbox'),
    (icon: Icons.person_outline_rounded, selected: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [AppShadows.soft],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < tabs.length; i++)
                _NavItem(
                  icon: currentIndex == i ? tabs[i].selected : tabs[i].icon,
                  label: tabs[i].label,
                  selected: currentIndex == i,
                  onTap: () => onTap(i),
                  badge: i == 3 && unread > 0 ? unread : 0,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap, required this.badge});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.gradient : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: selected ? AppColors.white : AppColors.textSecondary),
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.smallStyle.copyWith(fontSize: 10, color: selected ? AppColors.royalBlue : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class TripGoPassengerCounter extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const TripGoPassengerCounter({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CounterButton(icon: Icons.remove_rounded, onTap: value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 48,
          child: Text('$value', textAlign: TextAlign.center, style: AppTypography.headingStyle),
        ),
        _CounterButton(icon: Icons.add_rounded, onTap: value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.35 : 1,
      child: Material(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, size: 18, color: AppColors.royalBlue),
          ),
        ),
      ),
    );
  }
}

/// Simplifies showing Riverpod async-provider loading/error/data.
class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Future<void> Function()? retry;

  const AsyncValueView({super.key, required this.value, required this.builder, this.retry});

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) => builder(data),
      error: (error, _) => TripGoErrorState(message: error.toString(), onRetry: retry),
      loading: () => const TripGoLoading(),
    );
  }
}