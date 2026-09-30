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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 40,
              bottom: 40,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              gradient: success ? AppColors.cyanGradient : const LinearGradient(colors: [AppColors.error, Color(0xFFC0392B)]),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: (success ? AppColors.success : AppColors.error).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    success ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                    size: 80,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  success ? 'Payment Successful!' : 'Payment Failed',
                  style: AppTypography.displayStyle.copyWith(color: AppColors.white, fontSize: 28),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  success
                      ? 'Your seats are confirmed. An e-ticket has been generated.'
                      : 'We could not complete your payment. You can retry from the payment screen.',
                  style: AppTypography.bodyStyle.copyWith(color: AppColors.white.withOpacity(0.9)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (booking != null)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.border.withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Travel details', style: AppTypography.captionStyle),
                            if (reference.isNotEmpty) Text('Ref: $reference', style: AppTypography.captionStyle),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${booking.source} → ${booking.destination}', style: AppTypography.headingStyle),
                                  const SizedBox(height: 4),
                                  Text(success && booking.pnr != null ? 'PNR: ${booking.pnr}' : 'Booking ID: #${booking.id}', style: AppTypography.bodyStyle.copyWith(color: AppColors.royalBlue)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Total Paid', style: AppTypography.captionStyle),
                                const SizedBox(height: 2),
                                Text(formatMoney(amount > 0 ? amount : booking.totalAmount), style: AppTypography.titleStyle.copyWith(color: AppColors.royalBlue)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
                if (success && booking?.pnr != null)
                  TripGoButton(
                    label: 'View e-ticket',
                    icon: Icons.confirmation_number_rounded,
                    onPressed: () => context.push('/ticket/${booking!.pnr}'),
                  )
                else if (!success)
                  TripGoButton(
                    label: 'Retry payment',
                    icon: Icons.refresh_rounded,
                    onPressed: () => context.go('/payment/method'),
                  ),
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
    );
  }
}