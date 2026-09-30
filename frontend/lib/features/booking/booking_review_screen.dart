import 'dart:math';

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

class _BookingReviewScreenState extends ConsumerState<BookingReviewScreen> with SingleTickerProviderStateMixin {
  var _creating = false;
  var _validatingCoupon = false;
  final _couponController = TextEditingController();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animController.forward();
  }

  @override
  void dispose() {
    _couponController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _validateCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _validatingCoupon = true);
    try {
      final flow = ref.read(bookingFlowProvider)!;
      final passengerFare = flow.unitFare * ref.read(passengersProvider).length;
      final discount = await OfferRepository().validateCoupon(code: code, transportType: flow.transport, fare: passengerFare);
      ref.read(offerDiscountProvider.notifier).state = discount;
      ref.read(offerCodeProvider.notifier).state = code;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Awesome! Coupon applied: \u20b9$discount off')));
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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background animated header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) {
                return Transform.scale(
                  scale: 1.0 + (1.0 - val) * 0.1,
                  child: Opacity(
                    opacity: val,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.deepBlue, AppColors.royalBlue, AppColors.cyan],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -50,
                            top: -20,
                            child: Icon(
                              flow.transport == 'bus' ? Icons.directions_bus_filled : Icons.train_rounded,
                              size: 200,
                              color: AppColors.white.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
                      onPressed: () => context.pop(),
                    ),
                    Text('Review your trip', style: AppTypography.titleStyle.copyWith(color: AppColors.white)),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    children: [
                      // Animated Ticket Card
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, 50 * (1 - Curves.easeOutBack.transform(_animController.value))),
                            child: Opacity(
                              opacity: Curves.easeIn.transform(_animController.value),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            boxShadow: [
                              BoxShadow(color: AppColors.royalBlue.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.royalBlue.withOpacity(0.05),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: AppColors.cyan.withOpacity(0.2), shape: BoxShape.circle),
                                      child: Icon(flow.transport == 'bus' ? Icons.directions_bus_filled : Icons.train_rounded, color: AppColors.royalBlue, size: 20),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(flow.vehicleName.isEmpty ? flow.vehicleNumber : flow.vehicleName,
                                            style: AppTypography.headingStyle.copyWith(color: AppColors.darkNavy)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: AppColors.border),
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          FittedBox(fit: BoxFit.scaleDown, child: Text(flow.departure, style: AppTypography.displayStyle.copyWith(fontSize: 24, color: AppColors.darkNavy))),
                                          FittedBox(fit: BoxFit.scaleDown, child: Text(flow.route.split('â†’').first.trim(), style: AppTypography.captionStyle)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Column(
                                          children: [
                                            const Icon(Icons.arrow_forward_rounded, color: AppColors.cyan, size: 28),
                                            Text(flow.travelDateLabel, style: AppTypography.smallStyle.copyWith(color: AppColors.royalBlue, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          FittedBox(fit: BoxFit.scaleDown, child: Text(flow.arrival, style: AppTypography.displayStyle.copyWith(fontSize: 24, color: AppColors.darkNavy))),
                                          FittedBox(fit: BoxFit.scaleDown, child: Text(flow.route.split('â†’').last.trim(), style: AppTypography.captionStyle)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Dash separator
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final dashCount = (constraints.constrainWidth() / 10).floor();
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: List.generate(dashCount, (_) => Container(width: 5, height: 2, color: AppColors.border)),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Selected Seats', style: AppTypography.smallStyle),
                                          Text(flow.selectedSeats.join(', '), style: AppTypography.titleStyle.copyWith(color: AppColors.royalBlue)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Passengers', style: AppTypography.smallStyle),
                                        Text('${passengers.length}', style: AppTypography.titleStyle.copyWith(color: AppColors.darkNavy)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Animated Passengers list
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: Curves.easeIn.transform(max(0, _animController.value * 1.5 - 0.5)),
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _animController.value)),
                              child: child,
                            ),
                          );
                        },
                        child: TripGoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Traveller Details', style: AppTypography.headingStyle),
                              const SizedBox(height: AppSpacing.md),
                              for (var i = 0; i < passengers.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(color: AppColors.cyan.withOpacity(0.15), shape: BoxShape.circle),
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.person_rounded, size: 18, color: AppColors.royalBlue),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(passengers[i].fullName, style: AppTypography.titleStyle)),
                                            Text('${passengers[i].age} yrs â€¢ ${passengers[i].gender}', style: AppTypography.smallStyle),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Animated Coupon Section
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: Curves.easeIn.transform(max(0, _animController.value * 1.5 - 0.5)),
                            child: child,
                          );
                        },
                        child: TripGoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Offers & Promos', style: AppTypography.headingStyle),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: TripGoTextField(
                                      label: 'Coupon code',
                                      controller: _couponController,
                                      hint: 'e.g. SAVE50',
                                      prefixIcon: Icons.local_offer_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  TripGoButton(
                                    label: 'Apply',
                                    onPressed: _validatingCoupon ? null : _validateCoupon,
                                  ),
                                ],
                              ),
                              if (discount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.md),
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text('Coupon applied! You saved ${formatMoney(discount)}', style: AppTypography.bodyMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Animated Fare Summary
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: Curves.easeIn.transform(max(0, _animController.value * 2 - 1.0)),
                            child: child,
                          );
                        },
                        child: TripGoCard(
                          color: AppColors.deepBlue.withOpacity(0.02),
                          child: TripGoFareSummary(
                            passengerFare: passengerFare,
                            serviceFee: serviceFee,
                            tax: tax,
                            discount: discount,
                            total: total,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'By proceeding, you agree to TripGo Terms & Conditions. Free cancellation up to 24 hours before departure.',
                        style: AppTypography.captionStyle.copyWith(height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 80), // padding for bottom bar
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Loading overlay
          if (_creating)
            Positioned.fill(
              child: Container(
                color: AppColors.darkNavy.withOpacity(0.8),
                child: const TripGoLoading(message: 'Securing your reservation...'),
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total payable', style: AppTypography.captionStyle),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(formatMoney(_creating ? 0 : total), style: AppTypography.titleStyle.copyWith(color: AppColors.royalBlue)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: TripGoButton(
                  label: 'Proceed to Pay',
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