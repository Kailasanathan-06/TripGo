import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/misc.dart';

class PaymentMethodScreen extends ConsumerWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(confirmedBookingProvider);
    final amount = ref.watch(paymentAmountProvider);

    return Scaffold(
      appBar: const TripGoAppBar(title: 'Payment method'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (booking != null)
            TripGoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(booking.transportType == 'bus' ? Icons.directions_bus_filled : Icons.train_rounded, color: AppColors.royalBlue),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text('${booking.source} → ${booking.destination}', style: AppTypography.headingStyle)),
                      TripGoStatusChip.fromState(booking.state),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount payable', style: AppTypography.labelStyle),
                      Text(formatMoney(amount > 0 ? amount : booking.totalAmount), style: AppTypography.displayStyle),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
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
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Text('Payments are processed securely via TripGo safe gateway.', style: AppTypography.captionStyle),
            ],
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
      child: TripGoCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.royalBlue, size: 24),
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