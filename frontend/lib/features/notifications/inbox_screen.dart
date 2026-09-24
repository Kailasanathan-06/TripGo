import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/providers.dart';
import '../../shared/services/services.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/misc.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: notifications.when(
          data: (list) => list.isEmpty
              ? const TripGoEmptyState(icon: Icons.notifications_none_rounded, title: 'All caught up', message: 'You have no notifications.')
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      title: const Text('Inbox'),
                      toolbarHeight: 72,
                      actions: [
                        TextButton(
                          onPressed: () async {
                            await NotificationRepository().markAllRead();
                            ref.invalidate(notificationsProvider);
                          },
                          child: const Text('Mark all read'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverList.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) => _NotificationCard(notification: list[i]),
                      ),
                    ),
                  ],
                ),
          error: (e, __) => TripGoErrorState(message: '$e', onRetry: () => ref.invalidate(notificationsProvider)),
          loading: () => const ShimmerList(),
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = switch (notification.type) {
      'booking' => Icons.confirmation_number_rounded,
      'payment' => Icons.payments_outlined,
      'offer' => Icons.local_offer_rounded,
      'cancellation' => Icons.cancel_outlined,
      _ => Icons.notifications_rounded,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TripGoCard(
        onTap: notification.read
            ? null
            : () async {
                await NotificationRepository().markRead(notification.id);
                ref.invalidate(notificationsProvider);
              },
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notification.read ? AppColors.lightBlue : AppColors.royalBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: notification.read ? AppColors.royalBlue : AppColors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: AppTypography.bodyMedium),
                  const SizedBox(height: 4),
                  Text(notification.message, style: AppTypography.captionStyle),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!notification.read)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  )
                else
                  const SizedBox(height: 10),
                const SizedBox(height: 4),
                Text(formatShortDate(notification.createdAt), style: AppTypography.smallStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}