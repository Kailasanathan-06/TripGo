import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../shared/providers/providers.dart';
import '../../shared/services/services.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/fields.dart';
import '../../shared/widgets/misc.dart';

class BookingReviewScreen extends ConsumerStatefulWidget {
  const BookingReviewScreen({super.key});

  @override
  ConsumerState<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends ConsumerState<BookingReviewScreen> {
  var _creating = false;
  var _validatingCoupon = false;
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _validateCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() => _validatingCoupon = true);
    try {
      final flow = ref.read(bookingFlowProvider)!;
      final passengerFare = flow.unitFare * ref.read(passengersProvider).length;
      final discount = await OfferRepository().validateCoupon(code: code, transportType: flow.transport, fare: passengerFare);
      ref.read(offerDiscountProvider.notifier).state = discount;
      ref.read(offerCodeProvider.notifier).state = code;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Coupon applied: $discount')));
    } catch (e) {
      ref.read(offerDiscountProvider.notifier).state = 0;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _validatingCoupon = false);
    }
  }

  Future<void> _createBooking() async {
    if (_creating) return;
    final flow = ref.read(bookingFlowProvider)!;
    final passengers = ref.read(passengersProvider);
    setState(() => _creating = true);
    try {
      final booking = await BookingRepository().create(
        transportType: flow.transport,
        scheduleId: flow.scheduleId,
        coachId: flow.coachId,
        seatLabels: flow.selectedSeats,
        passengers: passengers,
        offerCode: ref.read(offerCodeProvider),
      );
      ref.read(confirmedBookingProvider.notifier).state = booking;
      ref.read(paymentAmountProvider.notifier).state = booking.totalAmount;
      if (!mounted) return;
      context.push('/payment/method');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(bookingFlowProvider);
    final passengers = ref.watch(passengersProvider);
    final discount = ref.watch(offerDiscountProvider);

    if (flow == null || passengers.isEmpty) {
      return const Scaffold(
        appBar: TripGoAppBar(title: 'Review booking'),
        body: TripGoEmptyState(icon: Icons.error_outline, title: 'No booking in progress', message: 'Start a new search to book your journey.'),
      );
    }

    final passengerFare = flow.unitFare * passengers.length;
    final serviceFee = flow.transport == 'bus' ? 50.0 : 40.0;
    final tax = (passengerFare * 0.05);
    final total = passengerFare + serviceFee + tax - discount;

    return Scaffold(
      appBar: const TripGoAppBar(title: 'Review booking'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TripGoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(flow.transport == 'bus' ? Icons.directions_bus_filled : Icons.train_rounded, color: AppColors.royalBlue),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(flow.vehicleName.isEmpty ? flow.vehicleNumber : flow.vehicleName,
                          style: AppTypography.headingStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(flow.departure, style: AppTypography.titleStyle),
                          Text(flow.route.split('Ã¢â€ â€™').first.trim(), style: AppTypography.captionStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: AppColors.cyan),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(flow.arrival, style: AppTypography.titleStyle),
                          Text(flow.route.split('Ã¢â€ â€™').last.trim(), style: AppTypography.captionStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(flow.travelDateLabel, style: AppTypography.smallStyle),
                    Text('Seats: ${flow.selectedSeats.join(', ')}',
                        style: AppTypography.smallStyle.copyWith(color: AppColors.royalBlue, fontWeight: FontWeight.w600)),
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
                Text('Passengers', style: AppTypography.headingStyle),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < passengers.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text('${i + 1}', style: AppTypography.smallStyle.copyWith(color: AppColors.royalBlue)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text('${passengers[i].fullName} Ã‚Â· ${passengers[i].age} yrs', style: AppTypography.bodyStyle),
                        ),
                        Text(passengers[i].gender, style: AppTypography.smallStyle),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TripGoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apply coupon', style: AppTypography.headingStyle),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TripGoTextField(
                        label: 'Coupon code',
                        controller: _couponController,
                        hint: 'e.g. TRIPGO50',
                        prefixIcon: Icons.local_offer_outlined,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    TripGoOutlinedButton(
                      label: 'Apply',
                      onPressed: _validatingCoupon ? null : _validateCoupon,
                    ),
                  ],
                ),
                if (discount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text('Coupon applied Ã‚Â· discount ${formatMoney(discount)}', style: AppTypography.smallStyle.copyWith(color: AppColors.success)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TripGoCard(
            color: AppColors.lightBlue.withValues(alpha: 0.4),
            child: TripGoFareSummary(
              passengerFare: passengerFare,
              serviceFee: serviceFee,
              tax: tax,
              discount: discount,
              total: total,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Cancellation: Full refund if cancelled 24h before departure. Terms apply. By proceeding you agree to TripGo Terms & Conditions.',
            style: AppTypography.captionStyle,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_creating) const TripGoLoading(message: 'Reserving your seatsÃ¢â‚¬Â¦'),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total payable', style: AppTypography.captionStyle),
                    Text(formatMoney(_creating ? 0 : total), style: AppTypography.titleStyle),
                  ],
                ),
              ),
              Expanded(
                child: TripGoButton(
                  label: 'Proceed to pay',
                  icon: Icons.lock_outline_rounded,
                  loading: _creating,
                  onPressed: _creating ? null : _createBooking,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}