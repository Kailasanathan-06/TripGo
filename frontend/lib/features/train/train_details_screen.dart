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

class TrainDetailsScreen extends ConsumerStatefulWidget {
  final int scheduleId;

  const TrainDetailsScreen({super.key, required this.scheduleId});

  @override
  ConsumerState<TrainDetailsScreen> createState() => _TrainDetailsScreenState();
}

class _TrainDetailsScreenState extends ConsumerState<TrainDetailsScreen> {
  late final Future<List<TrainScheduleModel>> _future;

  @override
  void initState() {
    super.initState();
    final query = ref.read(searchProvider);
    _future = TrainRepository().search(query).then((list) => list.where((s) => s.id == widget.scheduleId).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TripGoAppBar(title: 'Train details'),
      body: FutureBuilder<List<TrainScheduleModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const TripGoLoading();
          }
          if (snapshot.hasError || snapshot.data!.isEmpty) {
            return TripGoErrorState(message: 'Unable to load train details.', onRetry: () => setState(() => _future = _future));
          }
          final schedule = snapshot.data!.first;
          final train = schedule.train;
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
                            Text('${train.number} Â· ${train.name}', style: AppTypography.headingStyle.copyWith(color: AppColors.white)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(train.trainType, style: AppTypography.captionStyle.copyWith(color: AppColors.lightBlue)),
                                const SizedBox(width: AppSpacing.sm),
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                Text(' ${train.rating.toStringAsFixed(1)}', style: AppTypography.smallStyle.copyWith(color: AppColors.white)),
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
                            _TrainTimeRow(time: schedule.sourceStationCode, label: schedule.sourceStationName, desc: 'Departure ${formatDate(schedule.travelDate)}'),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text('${schedule.durationText} Â· ${schedule.distanceKm.toStringAsFixed(0)} km', style: AppTypography.captionStyle),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const SizedBox(width: 5, child: Icon(Icons.arrow_downward, size: 12, color: AppColors.textSecondary)),
                                      Text('${schedule.coaches.length} coach types available', style: AppTypography.smallStyle),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            _TrainTimeRow(time: schedule.destinationStationCode, label: schedule.destinationStationName, desc: 'Arrival'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Available classes', style: AppTypography.headingStyle),
              const SizedBox(height: AppSpacing.md),
              for (final coach in schedule.coaches)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TripGoCard(
                    onTap: () => context.push('/train/coaches/${coach.id}/berths'),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
                          child: const Icon(Icons.event_seat_rounded, color: AppColors.royalBlue),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_className(coach.coachClass)} (${coach.coachClass})', style: AppTypography.bodyMedium),
                              Text('${coach.available} berths available', style: AppTypography.captionStyle.copyWith(color: coach.available > 0 ? AppColors.success : AppColors.error)),
                            ],
                          ),
                        ),
                        Text(formatMoney(coach.classFare), style: AppTypography.headingStyle),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              TripGoButton(
                label: 'Choose class & berth',
                icon: Icons.event_seat_rounded,
                onPressed: () => context.push('/train/${schedule.id}/coaches'),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  String _className(String cls) {
    return {'SL': 'Sleeper', '3A': 'AC 3 Tier', '2A': 'AC 2 Tier', '1A': 'AC First Class', 'CC': 'AC Chair Car', '2S': 'Second Sitting'}[cls] ?? cls;
  }
}

class _TrainTimeRow extends StatelessWidget {
  final String time;
  final String label;
  final String desc;

  const _TrainTimeRow({required this.time, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.circle, size: 12, color: AppColors.royalBlue),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.bodyMedium),
            Text(desc, style: AppTypography.captionStyle),
          ],
        ),
        const Spacer(),
        Text(time, style: AppTypography.captionStyle.copyWith(color: AppColors.royalBlue, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class TrainCoachesScreen extends ConsumerStatefulWidget {
  final int scheduleId;

  const TrainCoachesScreen({super.key, required this.scheduleId});

  @override
  ConsumerState<TrainCoachesScreen> createState() => _TrainCoachesScreenState();
}

class _TrainCoachesScreenState extends ConsumerState<TrainCoachesScreen> {
  late final Future<List<TrainScheduleModel>> _future;

  @override
  void initState() {
    super.initState();
    final query = ref.read(searchProvider);
    _future = TrainRepository().search(query).then((list) => list.where((s) => s.id == widget.scheduleId).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TripGoAppBar(title: 'Select coach class'),
      body: FutureBuilder<List<TrainScheduleModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const TripGoLoading();
          if (snapshot.hasError || snapshot.data!.isEmpty) {
            return TripGoErrorState(message: 'Unable to load coaches.', onRetry: () => setState(() => _future = _future));
          }
          final schedule = snapshot.data!.first;
          final classes = schedule.coaches
              .map((c) => c.coachClass)
              .toSet()
              .map((c) => schedule.coaches.firstWhere((x) => x.coachClass == c))
              .toList();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('${schedule.train.name} Â· ${schedule.train.number}', style: AppTypography.captionStyle),
              const SizedBox(height: AppSpacing.md),
              for (final coach in classes)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TripGoCard(
                    onTap: () => context.push('/train/coaches/${coach.id}/berths'),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_fullClass(coach.coachClass), style: AppTypography.headingStyle),
                              const SizedBox(height: 4),
                              Text('${coach.available} berths available', style: AppTypography.captionStyle.copyWith(color: coach.available > 0 ? AppColors.success : AppColors.error)),
                            ],
                          ),
                        ),
                        Text(formatMoney(coach.classFare), style: AppTypography.headingStyle),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _fullClass(String cls) {
    return {'SL': 'Sleeper (SL)', '3A': 'AC 3 Tier (3A)', '2A': 'AC 2 Tier (2A)', '1A': 'AC First Class (1A)', 'CC': 'AC Chair Car (CC)', '2S': 'Second Sitting (2S)'}[cls] ?? cls;
  }
}

class TrainBerthsScreen extends ConsumerStatefulWidget {
  final int coachId;

  const TrainBerthsScreen({super.key, required this.coachId});

  @override
  ConsumerState<TrainBerthsScreen> createState() => _TrainBerthsScreenState();
}

class _TrainBerthsScreenState extends ConsumerState<TrainBerthsScreen> {
  late final Future<({List<TrainBerthModel> berths, TrainScheduleModel schedule, TrainCoachModel coach})> _future;

  @override
  void initState() {
    super.initState();
    final query = ref.read(searchProvider);
    _future = _load(query);
  }

  Future<({List<TrainBerthModel> berths, TrainScheduleModel schedule, TrainCoachModel coach})> _load(SearchQuery query) async {
    TrainCoachModel? matchCoach;
    TrainScheduleModel? schedule;
    final schedules = await TrainRepository().search(query);
    for (final s in schedules) {
      for (final c in s.coaches) {
        if (c.id == widget.coachId) {
          matchCoach = c;
          schedule = s;
        }
      }
    }
    final berths = await TrainRepository().berths(widget.coachId);
    final coach = matchCoach ??
        TrainCoachModel(id: widget.coachId, name: 'B', coachClass: 'SL', classFare: 300, available: berths.where((b) => b.isAvailable).length);
    final sc = schedule ??
        TrainScheduleModel(
          id: 0,
          train: const TrainModel(id: 0, number: '', name: '', trainType: '', rating: 0),
          sourceStationName: query.source,
          sourceStationCode: '',
          destinationStationName: query.destination,
          destinationStationCode: '',
          travelDate: query.date,
          durationMinutes: 60,
          distanceKm: 0,
          coaches: [coach],
          totalAvailable: coach.available,
        );
    final flow = BookingFlowState(
      transport: 'train',
      scheduleId: sc.id,
      coachId: widget.coachId,
      vehicleName: sc.train.name,
      vehicleNumber: sc.train.number,
      route: '${sc.sourceStationName} â†’ ${sc.destinationStationName}',
      travelDateLabel: formatShortDate(query.date),
      departure: sc.sourceStationCode.isEmpty ? sc.sourceStationName : sc.sourceStationCode,
      arrival: sc.destinationStationCode.isEmpty ? sc.destinationStationName : sc.destinationStationCode,
      boardingPoint: sc.sourceStationName,
      droppingPoint: sc.destinationStationName,
      unitFare: coach.classFare,
      available: coach.available,
    );
    ref.read(bookingFlowProvider.notifier).start(flow);
    return (berths: berths, schedule: sc, coach: coach);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TripGoAppBar(title: 'Select berth'),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const TripGoLoading();
          }
          if (snapshot.hasError) {
            return TripGoErrorState(message: '${snapshot.error}', onRetry: () => setState(() => _future = _future));
          }
          final data = snapshot.data!;
          final berths = data.berths;
          final coach = data.coach;
          final schedule = data.schedule;

          return Column(
            children: [
              // Top Coach Info Banner
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
                      child: const Icon(Icons.train_rounded, color: AppColors.royalBlue, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coach ${coach.name} · ${_classDisplayName(coach.coachClass)} (${coach.coachClass})',
                            style: AppTypography.headingStyle.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${schedule.train.name} (${schedule.train.number}) · ${formatMoney(coach.classFare)}/berth',
                            style: AppTypography.captionStyle,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: coach.available > 0 ? AppColors.lightBlue : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${coach.available} available',
                        style: TextStyle(
                          color: coach.available > 0 ? AppColors.royalBlue : AppColors.error,
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

              // Selected Berths Chips Bar
              const _TrainSelectedChips(),

              // Coach Berth Layout
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  children: [
                    _TrainCoachFrame(
                      coach: coach,
                      berths: berths,
                      child: _TrainCoachBerthsLayout(
                        berths: berths,
                        coachClass: coach.coachClass,
                        coachName: coach.name,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),

              _TrainSeatSummaryBar(coachLabel: coach.name, coachClass: coach.coachClass, fare: coach.classFare),
            ],
          );
        },
      ),
    );
  }

  static String _classDisplayName(String cls) {
    return {'SL': 'Sleeper', '3A': 'AC 3 Tier', '2A': 'AC 2 Tier', '1A': 'AC First Class', 'CC': 'AC Chair Car', '2S': 'Second Sitting'}[cls] ?? cls;
  }
}

/// Train Carriage Outer Frame with Vestibule / Doors
class _TrainCoachFrame extends StatelessWidget {
  final TrainCoachModel coach;
  final List<TrainBerthModel> berths;
  final Widget child;

  const _TrainCoachFrame({
    required this.coach,
    required this.berths,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Carriage Front / Vestibule Entry
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.meeting_room_rounded, size: 14, color: AppColors.royalBlue),
                    const SizedBox(width: 4),
                    Text(
                      'ENTRY / VESTIBULE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.royalBlue.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'COACH ${coach.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.wc_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'TOILET',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Main Berths Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),

          const Divider(height: 1, color: AppColors.border),

          // Carriage Rear Exit
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.meeting_room_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'EXIT / NEXT COACH',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders authentic Indian Railways coach cabins & aisles
class _TrainCoachBerthsLayout extends ConsumerWidget {
  final List<TrainBerthModel> berths;
  final String coachClass;
  final String coachName;

  const _TrainCoachBerthsLayout({
    required this.berths,
    required this.coachClass,
    required this.coachName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isChairCar = coachClass == 'CC' || coachClass == '2S';
    if (isChairCar) {
      return _buildChairCar(context, ref);
    }
    return _buildSleeperCoach(context, ref);
  }

  Widget _buildChairCar(BuildContext context, WidgetRef ref) {
    final rows = <List<TrainBerthModel>>[];
    for (var i = 0; i < berths.length; i += 5) {
      rows.add(berths.sublist(i, (i + 5 > berths.length) ? berths.length : i + 5));
    }

    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${r + 1}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                  ),
                ),
                // Left 3 seats (Window, Middle, Aisle)
                for (final berth in rows[r].take(3))
                  _berthWidget(context, ref, berth),
                // Aisle Walkway
                Container(
                  width: 36,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                  child: const Center(
                    child: Icon(Icons.transfer_within_a_station_rounded, size: 14, color: AppColors.textSecondary),
                  ),
                ),
                // Right 2 seats (Aisle, Window)
                for (final berth in rows[r].skip(3))
                  _berthWidget(context, ref, berth),
              ],
            ),
          ),
          if (r < rows.length - 1) const SizedBox(height: 2),
        ],
      ],
    );
  }

  Widget _buildSleeperCoach(BuildContext context, WidgetRef ref) {
    // 2A has 6 berths per bay (4 main + 2 side); SL/3A has 8 berths per bay (6 main + 2 side)
    final baySize = (coachClass == '2A') ? 6 : 8;
    final bays = <List<TrainBerthModel>>[];
    for (var i = 0; i < berths.length; i += baySize) {
      bays.add(berths.sublist(i, (i + baySize > berths.length) ? berths.length : i + baySize));
    }

    return Column(
      children: [
        for (var b = 0; b < bays.length; b++) ...[
          _buildCabinBay(context, ref, b + 1, bays[b], baySize),
          if (b < bays.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'BAY SEPARATOR',
                      style: TextStyle(fontSize: 8.5, color: AppColors.textSecondary.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildCabinBay(
    BuildContext context,
    WidgetRef ref,
    int cabinNumber,
    List<TrainBerthModel> bayBerths,
    int baySize,
  ) {
    final firstNum = BerthLabelInfo.parse(bayBerths.first.label).number;
    final lastNum = BerthLabelInfo.parse(bayBerths.last.label).number;

    final mainCount = (baySize == 6) ? 4 : 6;
    final mainBerths = bayBerths.take(mainCount).toList();
    final sideBerths = bayBerths.skip(mainCount).toList();

    final col1 = <TrainBerthModel>[];
    final col2 = <TrainBerthModel>[];
    final half = (mainBerths.length + 1) ~/ 2;
    for (var i = 0; i < mainBerths.length; i++) {
      if (i < half) {
        col1.add(mainBerths[i]);
      } else {
        col2.add(mainBerths[i]);
      }
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabin Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cabin $cabinNumber',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.darkNavy),
              ),
              Text(
                'Berths $firstNum – $lastNum',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10.5, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Cabin Layout: [Main Compartment] [Aisle Walkway] [Side Berths]
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Main Compartment (Facing Columns)
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'MAIN CABIN',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.royalBlue.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Left column (Lower, Middle, Upper)
                          Column(
                            children: [
                              for (final berth in col1)
                                _berthWidget(context, ref, berth),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 48.0 * col1.length,
                            color: AppColors.border.withValues(alpha: 0.6),
                          ),
                          // Right column facing (Lower, Middle, Upper)
                          Column(
                            children: [
                              for (final berth in col2)
                                _berthWidget(context, ref, berth),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Aisle Walkway
              Container(
                width: 32,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 10, color: AppColors.textSecondary),
                    const SizedBox(height: 4),
                    RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        'AISLE',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.arrow_downward_rounded, size: 10, color: AppColors.textSecondary),
                  ],
                ),
              ),

              // Side Berths
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'SIDE BERTHS',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.royalBlue.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      for (final berth in sideBerths)
                        _berthWidget(context, ref, berth),
                      if (sideBerths.length < 2)
                        Container(
                          height: 48,
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: Text(
                              'PASSAGE',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _berthWidget(BuildContext context, WidgetRef ref, TrainBerthModel berth) {
    final flow = ref.watch(bookingFlowProvider);
    final selected = flow?.selectedSeats.contains(berth.label) ?? false;
    return TripGoBerth(
      label: berth.label,
      state: seatStateFromStatus(berth.status, gender: berth.gender),
      selected: selected,
      onTap: () {
        final maxSeats = ref.read(searchProvider).passengers;
        final current = ref.read(bookingFlowProvider);
        if (current == null) return;
        if (!selected && current.selectedSeats.length >= maxSeats) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can only select $maxSeats berth${maxSeats > 1 ? 's' : ''} for $maxSeats passenger${maxSeats > 1 ? 's' : ''}.'),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        ref.read(bookingFlowProvider.notifier).toggleSeat(berth.label);
      },
    );
  }
}

/// Selected Berths summary chips
class _TrainSelectedChips extends ConsumerWidget {
  const _TrainSelectedChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(bookingFlowProvider)?.selectedSeats ?? const <String>[];
    if (selected.isEmpty) return const SizedBox.shrink();
    final sorted = [...selected]..sort();

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
                  _buildChip(ref, label),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(WidgetRef ref, String label) {
    final info = BerthLabelInfo.parse(label);
    return Chip(
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
        'Berth ${info.number}${info.typeCode.isNotEmpty ? ' (${info.typeCode})' : ''}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      deleteIcon: const Icon(Icons.close_rounded, size: 13, color: AppColors.textSecondary),
      onDeleted: () => ref.read(bookingFlowProvider.notifier).toggleSeat(label),
    );
  }
}

/// Bottom Summary Bar for Train Berth Selection
class _TrainSeatSummaryBar extends ConsumerWidget {
  final String coachLabel;
  final String coachClass;
  final double fare;

  const _TrainSeatSummaryBar({
    required this.coachLabel,
    required this.coachClass,
    required this.fare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passengers = ref.watch(searchProvider).passengers;
    final flow = ref.watch(bookingFlowProvider);
    final count = flow?.selectedSeats.length ?? 0;
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
                  Text(formatMoney(fare * count), style: AppTypography.titleStyle),
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
                            ? '$count of $passengers berths selected'
                            : 'Select ${passengers - count} more berth${passengers - count > 1 ? 's' : ''}',
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
              onPressed: enough ? () => context.push('/passengers') : null,
            ),
          ],
        ),
      ),
    );
  }
}