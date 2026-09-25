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

class PaymentAppScreen extends ConsumerStatefulWidget {
  const PaymentAppScreen({super.key});

  @override
  ConsumerState<PaymentAppScreen> createState() => _PaymentAppScreenState();
}

class _PaymentAppScreenState extends ConsumerState<PaymentAppScreen> {
  bool _fail = false;
  var _pin = '';
  var _paying = false;
  bool _showPinPad = false;

  void _initiate() {
    final amount = ref.read(paymentAmountProvider);
    if (amount <= 0 && ref.read(confirmedBookingProvider) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No booking found. Start a new search.')));
      return;
    }
    setState(() {
      _showPinPad = true;
      _pin = '';
    });
  }

  void _enterPin(String digit) {
    if (_pin.length >= 4) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) _pay();
  }

  Future<void> _pay() async {
    if (_paying) return;
    setState(() => _paying = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _paying = false);
    ref.read(demoFailChoiceProvider.notifier).state = _fail ? 'fail' : '';
    context.push('/payment/processing');
  }

  void _deletePin() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final amount = ref.watch(paymentAmountProvider);

    return Scaffold(
      appBar: const TripGoAppBar(title: 'UPI payment'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                TripGoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TRIPGO UPI', style: AppTypography.captionStyle.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w700, color: AppColors.royalBlue)),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Amount to pay', style: AppTypography.labelStyle),
                      const SizedBox(height: 2),
                      Text(formatMoney(amount), style: AppTypography.displayStyle),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
                            child: const Icon(Icons.storefront_rounded, color: AppColors.royalBlue),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TRIPGO Pvt Ltd', style: AppTypography.bodyMedium),
                              Text('tripgo@app.tripgo', style: AppTypography.captionStyle),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.verified_user_rounded, color: AppColors.success),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TripGoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.cyan, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Demo lab: toggle to simulate a failed payment while testing.',
                              style: AppTypography.smallStyle,
                            ),
                          ),
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
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: !_showPinPad
                  ? TripGoButton(label: 'Pay ${formatMoney(amount)}', icon: Icons.lock_outline_rounded, onPressed: _initiate)
                  : Column(
                      children: [
                        Text('Enter 4-digit PIN', style: AppTypography.captionStyle),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < 4; i++)
                              Container(
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i < _pin.length ? AppColors.royalBlue : AppColors.border,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (var i = 1; i <= 9; i++)
                              _keypadKey('$i', () => _enterPin('$i')),
                            _keypadKey('X', _deletePin),
                            _keypadKey('0', () => _enterPin('0')),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keypadKey(String label, VoidCallback onTap) {
    return Material(
      color: AppColors.lightBlue,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 72,
          height: 52,
          child: Center(child: Text(label, style: AppTypography.headingStyle)),
        ),
      ),
    );
  }
}