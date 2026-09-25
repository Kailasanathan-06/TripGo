import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/cards.dart';

class PaymentResultScreen extends ConsumerWidget {
  final String outcome;

  const PaymentResultScreen({super.key, required this.outcome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final success = outcome == 'success';
    final booking = ref.watch(confirmedBookingProvider);
    final reference = ref.watch(paymentReferenceProvider);
    final amount = ref.watch(paymentAmountProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: success ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 72,
                      color: success ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(success ? 'Payment successful' : 'Payment failed', style: AppTypography.displayStyle),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    success
                        ? 'Your seats are confirmed. An e-ticket has been generated.'
                        : 'We could not complete your payment. You can retry from the payment screen.',
                    style: AppTypography.captionStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  if (booking != null)
                    TripGoCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${booking.source} ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ ${booking.destination}', style: AppTypography.headingStyle),
                              const SizedBox(height: 4),
                              Text(success && booking.pnr != null ? 'PNR ${booking.pnr}' : 'Booking #${booking.id}', style: AppTypography.captionStyle),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatMoney(amount > 0 ? amount : booking.totalAmount), style: AppTypography.titleStyle),
                              const SizedBox(height: 4),
                              Text(reference.isEmpty ? '' : reference, style: AppTypography.captionStyle),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (reference.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text('Payment ref  $reference', style: AppTypography.captionStyle),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (success && booking?.pnr != null)
                    TripGoButton(
                      label: 'View e-ticket',
                      icon: Icons.confirmation_number_rounded,
                      onPressed: () => context.push('/ticket/${booking!.pnr}'),
                    )
                  else if (!success)
                    TripGoButton(label: 'Retry payment', icon: Icons.refresh_rounded, onPressed: () => context.go('/payment/method')),
                  const SizedBox(height: AppSpacing.md),
                  TripGoOutlinedButton(
                    label: 'Back to home',
                    icon: Icons.home_rounded,
                    onPressed: () {
                      ref.read(bookingFlowProvider.notifier).clear();
                      ref.read(passengersProvider.notifier).state = const [];
                      ref.read(offerCodeProvider.notifier).state = '';
                      ref.read(offerDiscountProvider.notifier).state = 0;
                      context.go('/home');
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