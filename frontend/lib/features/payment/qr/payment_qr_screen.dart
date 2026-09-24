import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/misc.dart';

class PaymentQrScreen extends ConsumerStatefulWidget {
  const PaymentQrScreen({super.key});

  @override
  ConsumerState<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends ConsumerState<PaymentQrScreen> {
  var _fail = false;
  var _confirmed = false;

  Future<void> _pay() async {
    setState(() => _confirmed = true);
    ref.read(demoFailChoiceProvider.notifier).state = _fail ? 'fail' : '';
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    context.push('/payment/processing');
  }

  @override
  Widget build(BuildContext context) {
    final amount = ref.watch(paymentAmountProvider);

    return Scaffold(
      appBar: const TripGoAppBar(title: 'Scan & pay'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                TripGoCard(
                  child: Column(
                    children: [
                      Text('Scan this code with any UPI app', style: AppTypography.captionStyle),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: QrImageView(
                          data: 'upi://pay?pa=tripgo@app.tripgo&pn=TripGo&am=${amount.toStringAsFixed(2)}&cu=INR',
                          size: 180,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(formatMoney(amount), style: AppTypography.displayStyle),
                      const SizedBox(height: 4),
                      Text('TripGo · tripgo@app.tripgo', style: AppTypography.captionStyle),
                    ],
                  ),
                ),
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
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TripGoButton(
                label: _confirmed ? 'Forwarding…' : 'I have paid',
                loading: _confirmed,
                onPressed: _confirmed ? null : _pay,
              ),
            ),
          ),
        ],
      ),
    );
  }
}