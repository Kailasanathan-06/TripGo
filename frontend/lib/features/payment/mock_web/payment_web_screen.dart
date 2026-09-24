import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/misc.dart';

class PaymentWebScreen extends ConsumerStatefulWidget {
  const PaymentWebScreen({super.key});

  @override
  ConsumerState<PaymentWebScreen> createState() => _PaymentWebScreenState();
}

class _PaymentWebScreenState extends ConsumerState<PaymentWebScreen> {
  final _cardNumber = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  var _method = 'card';
  var _fail = false;

  @override
  void dispose() {
    _cardNumber.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    ref.read(demoFailChoiceProvider.notifier).state = _fail ? 'fail' : '';
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    context.push('/payment/processing');
  }

  @override
  Widget build(BuildContext context) {
    final amount = ref.watch(paymentAmountProvider);
    final method = ref.watch(paymentMethodProvider);

    return Scaffold(
      appBar: const TripGoAppBar(title: 'Checkout'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                TripGoCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount payable', style: AppTypography.bodyStyle),
                      Text(formatMoney(amount), style: AppTypography.titleStyle),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TripGoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_method == 'card' ? 'Card details' : ('Net banking / ' + _method), style: AppTypography.headingStyle),
                      const SizedBox(height: AppSpacing.md),
                      if (_method == 'card') ...[
                        TripGoTextField(
                          label: 'Card number',
                          controller: _cardNumber,
                          hint: '1234 5678 9012 3456',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.credit_card_rounded,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(child: TripGoTextField(label: 'Expiry', controller: _expiry, hint: 'MM/YY')),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TripGoTextField(label: 'CVV', controller: _cvv, hint: '•••', obscure: true, keyboardType: TextInputType.number),
                            ),
                          ],
                        ),
                      ] else ...[
                        DropdownButtonFormField<String>(
                          value: _method,
                          decoration: const InputDecoration(labelText: 'Select bank'),
                          items: const [
                            DropdownMenuItem(value: 'bank1', child: Text('SBI Bank')),
                            DropdownMenuItem(value: 'bank2', child: Text('HDFC Bank')),
                            DropdownMenuItem(value: 'bank3', child: Text('ICICI Bank')),
                          ],
                          onChanged: (v) => setState(() => _method = v ?? 'bank1'),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          const Icon(Icons.failed_outlined, color: AppColors.cyan, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          const Expanded(child: Text('Demo lab: toggle failure to test the cancelled/refund path.', style: AppTypography.smallStyle)),
                        ],
                      ),
                      SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Simulate payment failure'),
                        value: _fail,
                        onChanged: (v) => setState(() => _fail = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
              child: TripGoButton(label: 'Pay ${formatMoney(amount)}', icon: Icons.lock_outline_rounded, onPressed: _pay),
            ),
          ),
        ],
      ),
    );
  }
}