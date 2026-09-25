import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../models/models.dart';
import 'buttons.dart';

class TripGoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? radius;
  final EdgeInsetsGeometry? margin;

  const TripGoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.onTap,
    this.radius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: color ?? AppColors.white,
        borderRadius: radius ?? BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius ?? BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius ?? BorderRadius.circular(AppRadius.card),
              boxShadow: const [AppShadows.card],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RoutePill extends StatelessWidget {
  final String departure;
  final String arrival;
  final String duration;
  final String route;
  final Widget icon;

  const _RoutePill({
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.route,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(departure, style: AppTypography.headingStyle),
                  Text(duration, style: AppTypography.smallStyle),
                  Text(arrival, style: AppTypography.headingStyle),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.royalBlue.withValues(alpha: 0.35), AppColors.cyan.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.royalBlue),
                ],
              ),
              const SizedBox(height: 4),
              Text(route, style: AppTypography.captionStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class TripGoBusCard extends StatelessWidget {
  final BusScheduleModel schedule;
  final VoidCallback onTap;

  const TripGoBusCard({super.key, required this.schedule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bus = schedule.bus;
    return TripGoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
                child: Icon(bus.isSleeper ? Icons.hotel_rounded : Icons.event_seat_rounded, size: 20, color: AppColors.royalBlue),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bus.operator, style: AppTypography.headingStyle),
                    Row(
                      children: [
                        Text(bus.busType.replaceAll('_', ' '), style: AppTypography.smallStyle),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                        Text('${bus.rating.toStringAsFixed(1)} (${schedule.reviewsCount})', style: AppTypography.captionStyle),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatMoney(schedule.baseFare), style: AppTypography.headingStyle),
                  if (schedule.discountAmount > 0)
                    Text('${schedule.discountAmount.toStringAsFixed(0)} off', style: AppTypography.captionStyle.copyWith(color: AppColors.success)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _RoutePill(
            departure: formatTime(schedule.boardingTime),
            arrival: formatTime(schedule.droppingTime),
            duration: schedule.durationText,
            route: '${schedule.sourceCity} â†’ ${schedule.destinationCity}',
            icon: const Icon(Icons.directions_bus_filled, size: 22, color: AppColors.royalBlue),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Flexible(child: Text(bus.amenities.take(3).join(' Â· '), style: AppTypography.captionStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const Spacer(),
              Flexible(
                child: Text('${schedule.availableSeats} seats left',
                    style: AppTypography.smallStyle.copyWith(color: schedule.availableSeats < 10 ? AppColors.error : AppColors.success)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TripGoTrainCard extends StatelessWidget {
  final TrainScheduleModel schedule;
  final VoidCallback onTap;

  const TripGoTrainCard({super.key, required this.schedule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final train = schedule.train;
    return TripGoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
                child: const Icon(Icons.train_rounded, size: 20, color: AppColors.royalBlue),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(train.name, style: AppTypography.headingStyle),
                    Row(
                      children: [
                        Text(train.number, style: AppTypography.smallStyle),
                        Text(' Â· ${train.trainType}', style: AppTypography.smallStyle),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                        Text(train.rating.toStringAsFixed(1), style: AppTypography.captionStyle),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _RoutePill(
            departure: schedule.sourceStationName.split(' ').first,
            arrival: schedule.destinationStationName.split(' ').first,
            duration: schedule.durationText,
            route: '${schedule.sourceStationName} â†’ ${schedule.destinationStationName}',
            icon: const Icon(Icons.departure_board_rounded, size: 22, color: AppColors.royalBlue),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final c in schedule.coaches.take(4))
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(c.coachClass, style: AppTypography.smallStyle.copyWith(color: AppColors.royalBlue)),
                  ),
                ),
              const Spacer(),
              Text('${schedule.totalAvailable} berths avail', style: AppTypography.smallStyle.copyWith(color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }
}

class TripGoTicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback? onTap;

  const TripGoTicketCard({super.key, required this.ticket, this.onTap});

  @override
  Widget build(BuildContext context) {
    final payload = ticket.payload;
    final seats = (payload['seats'] as List?)?.map((e) => (e as Map)['label']).join(', ') ?? ticket.booking?.seatSummary ?? '';
    final src = payload['source'] ?? ticket.booking?.source ?? '';
    final dst = payload['destination'] ?? ticket.booking?.destination ?? '';
    final date = payload['travel_date'] != null ? DateFormat('dd MMM').format(DateTime.parse(payload['travel_date'] as String)) : '';

    return TripGoCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      radius: BorderRadius.circular(AppRadius.xl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: const BoxDecoration(gradient: AppColors.gradient),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TRIPGO E-TICKET', style: AppTypography.smallStyle.copyWith(color: AppColors.white, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  TripGoStatusChip.fromState(ticket.status),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PNR', style: AppTypography.captionStyle),
                      Text('Date', style: AppTypography.captionStyle),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ticket.pnr, style: AppTypography.headingStyle.copyWith(color: AppColors.royalBlue, letterSpacing: 1.5)),
                      Text(date, style: AppTypography.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(src.toString(), style: AppTypography.headingStyle),
                            Text('Boarding', style: AppTypography.captionStyle),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: AppColors.cyan),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(dst.toString(), style: AppTypography.headingStyle),
                            Text('Destination', style: AppTypography.captionStyle),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(payload['vehicle_name']?.toString() ?? '', style: AppTypography.smallStyle),
                      Text('Seat: $seats', style: AppTypography.smallStyle.copyWith(color: AppColors.royalBlue)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TripGoFareSummary extends StatelessWidget {
  final double passengerFare;
  final double serviceFee;
  final double tax;
  final double discount;
  final double total;

  const TripGoFareSummary({
    super.key,
    required this.passengerFare,
    required this.serviceFee,
    required this.tax,
    required this.discount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {Color? color, TextStyle? style}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: style ?? AppTypography.bodyStyle),
              Text(value, style: style ?? AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        );
    return Column(
      children: [
        row('Base fare', formatMoney(passengerFare)),
        row('Service charge', formatMoney(serviceFee)),
        row('Taxes', formatMoney(tax)),
        if (discount > 0) row('Discount', '- ${formatMoney(discount)}', style: AppTypography.bodyStyle.copyWith(color: AppColors.success)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: AppColors.border, thickness: 1),
        ),
        row('Total amount', formatMoney(total), style: AppTypography.headingStyle),
      ],
    );
  }
}