import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cards.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.valueOrNull?.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.royalBlue)));
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TripGoCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.lightBlue,
                    child: Text(user.initials, style: AppTypography.displayStyle.copyWith(color: AppColors.royalBlue)),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName, style: AppTypography.titleStyle),
                        const SizedBox(height: 4),
                        Text(user.email, style: AppTypography.captionStyle),
                        if (user.phone.isNotEmpty) Text(user.phone, style: AppTypography.captionStyle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _MenuTile(
              icon: Icons.confirmation_number_rounded,
              title: 'My tickets',
              subtitle: 'View your e-tickets and bookings',
              onTap: () => context.go('/bookings'),
            ),
            _MenuTile(
              icon: Icons.local_offer_rounded,
              title: 'Offers',
              subtitle: 'Coupons and deals for your trips',
              onTap: () => context.go('/offers'),
            ),
            _MenuTile(
              icon: Icons.notifications_rounded,
              title: 'Inbox',
              subtitle: 'Booking updates and announcements',
              onTap: () => context.go('/inbox'),
            ),
            _MenuTile(
              icon: Icons.qr_code_2_rounded,
              title: 'Check PNR',
              subtitle: 'Look up a ticket by PNR number',
              onTap: () => context.push('/pnr'),
            ),
            _MenuTile(
              icon: Icons.settings_rounded,
              title: 'Settings',
              subtitle: 'Theme, preferences and app info',
              onTap: () => context.push('/settings'),
            ),
            const SizedBox(height: AppSpacing.lg),
            TripGoOutlinedButton(
              label: 'Log out',
              icon: Icons.logout_rounded,
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                ref.read(bookingFlowProvider.notifier).clear();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text('TripGo v1.0.0', style: AppTypography.captionStyle),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TripGoCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.royalBlue, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.captionStyle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}