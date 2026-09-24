import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/services/services.dart';
import '../../../shared/widgets/feedback.dart';

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.royalBlue),
              ),
              const SizedBox(height: 32),
              Text('Processing payment', style: AppTypography.titleStyle),
              const SizedBox(height: 8),
              Text(_message, style: AppTypography.captionStyle, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Amount ${formatMoney(amount)}', style: AppTypography.smallStyle),
            ],
          ),
        ),
      ),
    );
  }
}