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
import '../../../shared/widgets/misc.dart';

class PaymentMethodScreen extends ConsumerWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(confirmedBookingProvider);
    final amount = ref.watch(paymentAmountProvider);

    return Scaffold(
      appBar: const TripGoAppBar(title: 'Payment method'),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.background.withOpacity(0.3),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (booking != null)
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      boxShadow: const [AppShadows.card],
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(booking.transportType == 'bus' ? Icons.directions_bus_filled : Icons.train_rounded, color: AppColors.white),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text('${booking.source} → ${booking.destination}', style: AppTypography.headingStyle.copyWith(color: AppColors.white))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: Text('Pending', style: AppTypography.captionStyle.copyWith(color: AppColors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Amount payable', style: AppTypography.labelStyle.copyWith(color: AppColors.white.withOpacity(0.7))),
                            Text(formatMoney(amount > 0 ? amount : booking.totalAmount), style: AppTypography.displayStyle.copyWith(color: AppColors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                Text('Choose a method', style: AppTypography.headingStyle),
                const SizedBox(height: AppSpacing.md),
                _MethodTile(
                  icon: Icons.qr_code_2_rounded,
                  title: 'UPI',
                  subtitle: 'Pay using any UPI app',
                  onTap: () {
                    ref.read(paymentMethodProvider.notifier).state = 'upi';
                    context.push('/payment/app');
                  },
                ),
                _MethodTile(
                  icon: Icons.credit_card_rounded,
                  title: 'Credit / Debit Card',
                  subtitle: 'Visa, Mastercard, RuPay',
                  onTap: () {
                    ref.read(paymentMethodProvider.notifier).state = 'card';
                    context.push('/payment/web');
                  },
                ),
                _MethodTile(
                  icon: Icons.account_balance_rounded,
                  title: 'Net banking',
                  subtitle: 'All major banks',
                  onTap: () {
                    ref.read(paymentMethodProvider.notifier).state = 'netbanking';
                    context.push('/payment/web');
                  },
                ),
                _MethodTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Wallet',
                  subtitle: 'TripGo wallet balance',
                  onTap: () {
                    ref.read(paymentMethodProvider.notifier).state = 'wallet';
                    context.push('/payment/web');
                  },
                ),
                _MethodTile(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scan & pay',
                  subtitle: 'Pay by scanning a QR code',
                  onTap: () {
                    ref.read(paymentMethodProvider.notifier).state = 'qr';
                    context.push('/payment/qr');
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.success),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Payments are processed securely via TripGo safe gateway.', style: AppTypography.captionStyle),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: AppColors.border.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppColors.cyanGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.white, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTypography.headingStyle),
                        const SizedBox(height: 4),
                        Text(subtitle, style: AppTypography.captionStyle),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.royalBlue, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}