import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/misc.dart';

class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(myTicketsProvider);
    final bookings = ref.watch(myBookingsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: true,
              title: Text('My tickets'),
              toolbarHeight: 72,
            ),
            SliverToBoxAdapter(
              child: bookings.maybeWhen(
                data: (pending) {
                  final awaiting = pending.where((b) => b.pnr == null && !b.isCancelled).toList();
                  if (awaiting.isEmpty) return const SizedBox.shrink();
                  return _PendingPayments(awaiting: awaiting);
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ),
            tickets.maybeWhen(
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: TripGoEmptyState(
                      icon: Icons.confirmation_number_outlined,
                      title: 'No tickets yet',
                      message: 'When you book a journey, your e-tickets will show up here.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => TripGoTicketCard(
                      ticket: list[i],
                      onTap: () => context.push('/ticket/${list[i].pnr}'),
                    ),
                  ),
                );
              },
              orElse: () => const SliverToBoxAdapter(child: TripGoLoading(message: 'Loading your tickets…')),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }
}

class _PendingPayments extends ConsumerWidget {
  final List<BookingModel> awaiting;

  const _PendingPayments({required this.awaiting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: TripGoCard(
        color: AppColors.lightBlue.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payments pending', style: AppTypography.headingStyle),
            const SizedBox(height: AppSpacing.sm),
            for (final b in awaiting.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${b.source} → ${b.destination} · ${b.totalAmount.toStringAsFixed(0)}', style: AppTypography.bodyStyle),
                    ),
                    TripGoOutlinedButton(
                      label: 'Pay now',
                      onPressed: () {
                        ref.read(confirmedBookingProvider.notifier).state = b;
                        ref.read(paymentAmountProvider.notifier).state = b.totalAmount;
                        context.push('/payment/method');
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}