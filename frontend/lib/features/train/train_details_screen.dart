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
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.lg,
                  children: [
                    Text('Coach berth map', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SeatLegend(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 1.1),
                  itemCount: berths.length,
                  itemBuilder: (context, i) => _berthItem(ref, berths[i]),
                ),
              ),
              _SeatSummaryBar(coachLabel: data.coach.coachClass, fare: data.coach.classFare),
            ],
          );
        },
      ),
    );
  }

  Widget _berthItem(WidgetRef ref, TrainBerthModel berth) {
    final flow = ref.watch(bookingFlowProvider);
    final selected = flow?.selectedSeats.contains(berth.label) ?? false;
    return TripGoBerth(
      label: berth.label,
      state: seatStateFromStatus(berth.status, gender: berth.gender),
      selected: selected,
      onTap: () {
        final maxSeats = ref.read(searchProvider).passengers;
        final current = ref.read(bookingFlowProvider)!;
        if (!selected && current.selectedSeats.length >= maxSeats) return;
        ref.read(bookingFlowProvider.notifier).toggleSeat(berth.label);
      },
    );
  }
}

class _SeatSummaryBar extends ConsumerWidget {
  final String coachLabel;
  final double fare;

  const _SeatSummaryBar({required this.coachLabel, required this.fare});

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
        decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatMoney(fare * count), style: AppTypography.titleStyle),
                  Text('$count of $passengers selected Â· $coachLabel', style: AppTypography.captionStyle),
                ],
              ),
            ),
            Expanded(
              child: TripGoButton(
                label: 'Continue',
                onPressed: enough ? () => context.push('/passengers') : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}