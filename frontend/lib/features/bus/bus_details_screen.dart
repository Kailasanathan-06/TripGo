import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
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
                            Text('${bus.operator} Â· ${bus.busType.replaceAll('_', ' ')}',
                                style: AppTypography.headingStyle.copyWith(color: AppColors.white)),
                            const SizedBox(height: 4),
                            Text(bus.name, style: AppTypography.captionStyle.copyWith(color: AppColors.lightBlue)),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                Text(' ${bus.rating.toStringAsFixed(1)} Â· ${schedule.reviewsCount} reviews',
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
  late Future<({List<BusSeatModel> seats, BusScheduleModel schedule})> _future;
  int _selectedDeck = 1;

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
      final seats = await BusRepository().seats(schedule.id);
      return (seats: seats, schedule: schedule);
    });
  }

  @override
  Widget build(BuildContext context) {
    final passengers = ref.watch(searchProvider).passengers;

    return Scaffold(
      appBar: const TripGoAppBar(title: 'Select seats'),
      body: FutureBuilder<({List<BusSeatModel> seats, BusScheduleModel schedule})>(
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
          final data = snapshot.data!;
          final seats = data.seats;
          final schedule = data.schedule;
          final bus = schedule.bus;

          final deck1 = seats.where((s) => s.floor == 1).toList();
          final deck2 = seats.where((s) => s.floor == 2).toList();
          final hasTwoDecks = deck1.isNotEmpty && deck2.isNotEmpty;

          // If deck 1 is empty, fallback to deck 2
          final activeDeck = (hasTwoDecks && _selectedDeck == 2) ? 2 : (deck1.isNotEmpty ? 1 : 2);
          final currentSeats = activeDeck == 2 ? deck2 : deck1;
          final currentRows = currentSeats.map((s) => s.row).toSet().toList()..sort();

          final deck1Available = deck1.where((s) => s.isAvailable).length;
          final deck2Available = deck2.where((s) => s.isAvailable).length;

          return Column(
            children: [
              // Top Bus Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_bus_rounded, color: AppColors.royalBlue, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${bus.operator} · ${bus.busType.replaceAll('_', ' ')}',
                            style: AppTypography.headingStyle.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${schedule.sourceCity} → ${schedule.destinationCity} · ${formatMoney(schedule.baseFare - schedule.discountAmount)}/seat',
                            style: AppTypography.captionStyle,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: schedule.availableSeats > 0 ? AppColors.lightBlue : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${schedule.availableSeats} available',
                        style: TextStyle(
                          color: schedule.availableSeats > 0 ? AppColors.royalBlue : AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Legend
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: SeatLegend(),
              ),

              // Deck Selector Tabs (if multi-deck)
              if (hasTwoDecks)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedDeck = 1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: activeDeck == 1 ? AppColors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                boxShadow: activeDeck == 1
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.airline_seat_recline_normal_rounded,
                                    size: 16,
                                    color: activeDeck == 1 ? AppColors.royalBlue : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Lower Deck ($deck1Available)',
                                    style: TextStyle(
                                      fontWeight: activeDeck == 1 ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 12,
                                      color: activeDeck == 1 ? AppColors.royalBlue : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedDeck = 2),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: activeDeck == 2 ? AppColors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                boxShadow: activeDeck == 2
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.single_bed_rounded,
                                    size: 16,
                                    color: activeDeck == 2 ? AppColors.royalBlue : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Upper Deck ($deck2Available)',
                                    style: TextStyle(
                                      fontWeight: activeDeck == 2 ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 12,
                                      color: activeDeck == 2 ? AppColors.royalBlue : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Selected Seats Chips
              const _SelectedSeatsChip(),

              // Bus Cabin Frame with Proper Seats Layout
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  children: [
                    _BusCabinFrame(
                      deckTitle: hasTwoDecks
                          ? (activeDeck == 2 ? 'Upper Deck (Sleeper)' : 'Lower Deck')
                          : (bus.isSleeper ? 'Sleeper Deck' : 'Cabin Layout'),
                      isSleeper: activeDeck == 2 || bus.isSleeper,
                      child: Column(
                        children: [
                          for (final row in currentRows)
                            _buildBusRow(context, row, currentSeats, isSleeper: activeDeck == 2 || bus.isSleeper),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
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

  Widget _buildBusRow(BuildContext context, int row, List<BusSeatModel> currentSeats, {required bool isSleeper}) {
    final rowSeats = currentSeats.where((s) => s.row == row).toList()
      ..sort((a, b) => (int.tryParse(a.label) ?? 0).compareTo(int.tryParse(b.label) ?? 0));

    if (rowSeats.isEmpty) return const SizedBox.shrink();

    // Divide seats depending on row width to ensure proper aisle positioning
    final List<BusSeatModel> leftSide;
    final List<BusSeatModel> rightSide;

    if (rowSeats.length == 2) {
      // 1 on left, aisle in middle, 1 on right
      leftSide = [rowSeats[0]];
      rightSide = [rowSeats[1]];
    } else if (rowSeats.length == 3) {
      // 1 on left (single window), aisle, 2 on right (double)
      leftSide = [rowSeats[0]];
      rightSide = [rowSeats[1], rowSeats[2]];
    } else if (rowSeats.length == 4) {
      // 2 on left, aisle, 2 on right (2x2 layout)
      leftSide = [rowSeats[0], rowSeats[1]];
      rightSide = [rowSeats[2], rowSeats[3]];
    } else {
      // 5 seats (back row) or 1 seat
      leftSide = rowSeats;
      rightSide = [];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Row Number
          SizedBox(
            width: 24,
            child: Text(
              '$row',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ),

          // Left Seats
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final seat in leftSide)
                _seatWidget(context, seat, isSleeper),
            ],
          ),

          // Central Walkway Aisle
          if (rightSide.isNotEmpty)
            Container(
              width: 38,
              height: isSleeper ? 64 : 42,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_walk_rounded, size: 13, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                ],
              ),
            ),

          // Right Seats
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final seat in rightSide)
                _seatWidget(context, seat, isSleeper),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seatWidget(BuildContext context, BusSeatModel seat, bool isSleeper) {
    final flow = ref.watch(bookingFlowProvider);
    final selected = flow?.selectedSeats.contains(seat.label) ?? false;
    return TripGoSeat(
      label: seat.label,
      state: seatStateFromStatus(seat.status, gender: seat.gender),
      selected: selected,
      isSleeper: isSleeper,
      onTap: () {
        final maxSeats = ref.read(searchProvider).passengers;
        final flowRef = ref.read(bookingFlowProvider);
        if (flowRef == null) return;
        if (!selected && flowRef.selectedSeats.length >= maxSeats) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can only select $maxSeats seat${maxSeats > 1 ? 's' : ''} for $maxSeats passenger${maxSeats > 1 ? 's' : ''}.'),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        ref.read(bookingFlowProvider.notifier).toggleSeat(seat.label);
      },
    );
  }
}

/// Realistic Bus Body Chassis Container
class _BusCabinFrame extends StatelessWidget {
  final String deckTitle;
  final bool isSleeper;
  final Widget child;

  const _BusCabinFrame({
    required this.deckTitle,
    required this.isSleeper,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Front of Bus Header (Windshield curve, Driver side, Passenger Entry)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Entry Door Indicator
                Row(
                  children: [
                    const Icon(Icons.meeting_room_rounded, size: 14, color: AppColors.royalBlue),
                    const SizedBox(width: 4),
                    Text(
                      'DOOR',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.royalBlue.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                // Center Cabin Title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(isSleeper ? Icons.single_bed_rounded : Icons.directions_bus_rounded, size: 12, color: AppColors.royalBlue),
                      const SizedBox(width: 4),
                      Text(
                        deckTitle.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.royalBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Driver Steering Wheel Area
                Row(
                  children: [
                    Text(
                      'DRIVER',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkNavy.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.radio_button_checked, size: 12, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Seats content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: child,
          ),

          const Divider(height: 1, color: AppColors.border),

          // Rear of Bus Indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withValues(alpha: 0.35),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Center(
              child: Text(
                'REAR / BACK OF BUS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selected Seats summary chip list
class _SelectedSeatsChip extends ConsumerWidget {
  const _SelectedSeatsChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(bookingFlowProvider)?.selectedSeats ?? const <String>[];
    if (selected.isEmpty) return const SizedBox.shrink();
    final sorted = [...selected]..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final label in sorted)
                  Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.success),
                    avatar: const CircleAvatar(
                      radius: 7,
                      backgroundColor: AppColors.success,
                      child: Icon(Icons.check, size: 9, color: Colors.white),
                    ),
                    label: Text(
                      'Seat $label',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    deleteIcon: const Icon(Icons.close_rounded, size: 13, color: AppColors.textSecondary),
                    onDeleted: () => ref.read(bookingFlowProvider.notifier).toggleSeat(label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom summary bar for Bus Seat Selection
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
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(formatMoney((flow?.unitFare ?? 0) * count), style: AppTypography.titleStyle),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (enough)
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14)
                      else
                        const Icon(Icons.info_outline_rounded, color: AppColors.royalBlue, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        enough
                            ? '$count of $passengers seats selected'
                            : 'Select ${passengers - count} more seat${passengers - count > 1 ? 's' : ''}',
                        style: AppTypography.captionStyle.copyWith(
                          color: enough ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TripGoButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: enough
                  ? () {
                      context.push('/passengers');
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}