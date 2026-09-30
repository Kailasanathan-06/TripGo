import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/services/services.dart';

class PaymentProcessingScreen extends ConsumerStatefulWidget {
  const PaymentProcessingScreen({super.key});

  @override
  ConsumerState<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends ConsumerState<PaymentProcessingScreen> {
  var _message = 'Contacting your bank…';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final booking = ref.read(confirmedBookingProvider);
    final bookingId = booking?.id ?? 0;
    if (bookingId == 0) {
      if (!mounted) return;
      context.go('/payment/result?status=failed');
      return;
    }

    final method = ref.read(paymentMethodProvider).isEmpty ? 'card' : ref.read(paymentMethodProvider);
    final fail = ref.read(demoFailChoiceProvider) == 'fail';

    try {
      final started = await PaymentRepository().pay(bookingId: bookingId, method: method, action: 'start');
      ref.read(paymentReferenceProvider.notifier).state = started.reference;

      setState(() => _message = fail ? 'Your payment is being declined…' : 'Authorizing payment…');
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      final result = await PaymentRepository().pay(bookingId: bookingId, method: method, action: fail ? 'failure' : 'success');
      if (!mounted) return;

      if (result.booking != null && result.booking!.isConfirmed) {
        ref.read(confirmedBookingProvider.notifier).state = result.booking;
        await invalidateUserData(ref);
        if (!mounted) return;
        context.go('/payment/result?status=success');
      } else {
        ref.read(confirmedBookingProvider.notifier).state = result.booking;
        if (!mounted) return;
        context.go('/payment/result?status=failed');
      }
    } catch (e) {
      if (!mounted) return;
      context.go('/payment/result?status=failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = ref.watch(paymentAmountProvider);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.gradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.royalBlue.withOpacity(0.3), blurRadius: 40, spreadRadius: 10),
                ],
              ),
              child: const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(strokeWidth: 6, color: AppColors.white),
              ),
            ),
            const SizedBox(height: 40),
            Text('Processing Payment', style: AppTypography.displayStyle.copyWith(color: AppColors.white, fontSize: 24)),
            const SizedBox(height: 12),
            Text(_message, style: AppTypography.bodyMedium.copyWith(color: AppColors.white.withOpacity(0.9)), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text('Amount: ${formatMoney(amount)}', style: AppTypography.headingStyle.copyWith(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }
}