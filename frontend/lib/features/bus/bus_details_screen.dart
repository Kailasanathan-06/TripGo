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
import '../../shared/services/services.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/misc.dart';
import '../../shared/widgets/seats.dart';

class BusDetailsScreen extends ConsumerStatefulWidget {
  final int scheduleId;

  const BusDetailsScreen({super.key, required this.scheduleId});

  @override
  ConsumerState<BusDetailsScreen> createState() => _BusDetailsScreenState();
}

class _BusDetailsScreenState extends ConsumerState<BusDetailsScreen> {
  late final Future<List<BusScheduleModel>> _future;

  @override
  void initState() {
    super.initState();
    final query = ref.read(searchProvider);
    _future = BusRepository().search(query).then(
          (list) => list.where((s) => s.id == widget.scheduleId).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TripGoAppBar(title: 'Bus details'),
      body: FutureBuilder<List<BusScheduleModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const TripGoLoading();
          }
          if (snapshot.hasError || snapshot.data!.isEmpty) {
            return TripGoErrorState(message: 'Unable to load bus details.', onRetry: () => setState(() => _future = Future.value(_future)));
          }
          final schedule = snapshot.data!.first;
          final bus = schedule.bus;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              TripGoCard(
                padding: EdgeInsets.zero,
                radius: BorderRadius.circular(AppRadius.xl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: const BoxDecoration(gradient: AppColors.gradient),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${bus.operator} · ${bus.busType.replaceAll('_', ' ')}',
                                style: AppTypography.headingStyle.copyWith(color: AppColors.white)),
                            const SizedBox(height: 4),
                            Text(bus.name, style: AppTypography.captionStyle.copyWith(color: AppColors.lightBlue)),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                Text(' ${bus.rating.toStringAsFixed(1)} · ${schedule.reviewsCount} reviews',
                                    style: AppTypography.smallStyle.copyWith(color: AppColors.white)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TimeRow(
                              icon: Icons.trip_origin_rounded,
                              color: AppColors.royalBlue,
                              time: formatTime(schedule.boardingTime),
                              label: schedule.sourceCity,
                              detail: schedule.boardingPoint,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Row(
                                children: [
                                  const SizedBox(width: 5, child: Icon(Icons.more_vert, size: 14, color: AppColors.textSecondary)),
                                  Text(schedule.durationText, style: AppTypography.captionStyle),
                                ],
                              ),
                            ),
                            _TimeRow(
                              icon: Icons.location_on_rounded,
                              color: AppColors.cyan,
                              time: formatTime(schedule.droppingTime),
                              label: schedule.destinationCity,
                              detail: schedule.droppingPoint,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Divider(color: AppColors.border),
                            const SizedBox(height: AppSpacing.md),
                            Text('Amenities', style: AppTypography.labelStyle),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final a in bus.amenities)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(AppRadius.pill)),
                                    child: Text(a, style: AppTypography.smallStyle.copyWith(color: AppColors.royalBlue)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TripGoCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Fare', style: AppTypography.labelStyle),
                        Text(formatMoney(schedule.baseFare), style: AppTypography.titleStyle),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Available seats', style: AppTypography.bodyStyle),
                        Text('${schedule.availableSeats}', style: AppTypography.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TripGoButton(
                label: 'Select seats',
                icon: Icons.event_seat_rounded,
                onPressed: () => context.push('/bus/${schedule.id}/seats'),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String time;
  final String label;
  final String detail;

  const _TimeRow({required this.icon, required this.color, required this.time, required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: AppTypography.headingStyle),
            Text(label, style: AppTypography.bodyMedium),
            Text(detail, style: AppTypography.captionStyle),
          ],
        ),
      ],
    );
  }
}

class BusSeatsScreen extends ConsumerStatefulWidget {
  final int scheduleId;

  const BusSeatsScreen({super.key, required this.scheduleId});

  @override
  ConsumerState<BusSeatsScreen> createState() => _BusSeatsScreenState();
}

class _BusSeatsScreenState extends ConsumerState<BusSeatsScreen> {
  late Future<List<BusSeatModel>> _future;

  @override
  void initState() {
    super.initState();
    final query = ref.read(searchProvider);
    _future = BusRepository().search(query).then((list) async {
      final schedule = list.where((s) => s.id == widget.scheduleId).first;
      final flow = BookingFlowState(
        transport: 'bus',
        scheduleId: schedule.id,
        vehicleName: schedule.bus.name,
        vehicleNumber: schedule.sourceCity,
        route: '${schedule.sourceCity} → ${schedule.destinationCity}',
        travelDateLabel: formatShortDate(query.date),
        departure: formatTime(schedule.boardingTime),
        arrival: formatTime(schedule.droppingTime),
        boardingPoint: schedule.boardingPoint,
        droppingPoint: schedule.droppingPoint,
        unitFare: schedule.baseFare - schedule.discountAmount,
        discount: schedule.discountAmount,
        available: schedule.availableSeats,
      );
      ref.read(bookingFlowProvider.notifier).start(flow);
      return BusRepository().seats(schedule.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final passengers = ref.watch(searchProvider).passengers;

    return Scaffold(
      appBar: TripGoAppBar(title: 'Select seats'),
      body: FutureBuilder<List<BusSeatModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const TripGoLoading();
          }
          if (snapshot.hasError) {
            return TripGoErrorState(
              message: '${snapshot.error}',
              onRetry: () => setState(() => _future = _future),
            );
          }
          final seats = snapshot.data!;
          final deck1 = seats.where((s) => s.floor == 1).toList();
          final deck2 = seats.where((s) => s.floor == 2).toList();
          final rows1 = deck1.map((s) => s.row).toSet().toList()..sort();
          final rows2 = deck2.map((s) => s.row).toSet().toList()..sort();

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: SeatLegend(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    if (rows2.isNotEmpty) _DeckSection(title: 'Upper deck', rows: rows2, seats: deck2),
                    if (rows1.isNotEmpty) _DeckSection(title: 'Lower deck', rows: rows1, seats: deck1),
                    _SelectedSeatsChip(),
                  ],
                ),
              ),
              _SeatSummaryBar(passengers: passengers),
            ],
          );
        },
      ),
    );
  }
}

class _SeatSummaryBar extends ConsumerWidget {
  final int passengers;

  const _SeatSummaryBar({required this.passengers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(bookingFlowProvider);
    final selected = flow?.selectedSeats ?? const <String>[];
    final count = selected.length;
    final enough = count >= passengers;

    return SafeArea(
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
                  Text(formatMoney((flow?.unitFare ?? 0) * count), style: AppTypography.titleStyle),
                  Text('$count of $passengers selected', style: AppTypography.captionStyle),
                ],
              ),
            ),
            Expanded(
              child: TripGoButton(
                label: 'Continue',
                onPressed: enough
                    ? () {
                        context.push('/passengers');
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedSeatsChip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(bookingFlowProvider)?.selectedSeats ?? const <String>[];
    if (selected.isEmpty) return const SizedBox.shrink();
    final sorted = [...selected]..sort();
    return TripGoCard(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final label in sorted)
            Chip(
              label: Text('Seat $label', style: AppTypography.smallStyle),
              onDeleted: () => ref.read(bookingFlowProvider.notifier).toggleSeat(label),
            ),
        ],
      ),
    );
  }
}

class _DeckSection extends ConsumerWidget {
  final String title;
  final List<int> rows;
  final List<BusSeatModel> seats;

  const _DeckSection({required this.title, required this.rows, required this.seats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.labelStyle),
        const SizedBox(height: AppSpacing.sm),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(width: 30, child: Text('$row', style: AppTypography.captionStyle)),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final seat in seats.where((s) => s.row == row).take(2))
                        _seatWidget(ref, seat),
                      const SizedBox(width: AppSpacing.xl),
                      for (final seat in seats.where((s) => s.row == row).skip(2))
                        _seatWidget(ref, seat),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _seatWidget(WidgetRef ref, BusSeatModel seat) {
    final flow = ref.watch(bookingFlowProvider);
    final selected = flow?.selectedSeats.contains(seat.label) ?? false;
    return TripGoSeat(
      label: seat.label,
      state: seatStateFromStatus(seat.status, gender: seat.gender),
      selected: selected,
      onTap: () {
        final maxSeats = ref.read(searchProvider).passengers;
        final flowRef = ref.read(bookingFlowProvider)!;
        if (!selected && flowRef.selectedSeats.length >= maxSeats) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You can only select $maxSeats seat(s).')),
          );
          return;
        }
        ref.read(bookingFlowProvider.notifier).toggleSeat(seat.label);
      },
    );
  }
}