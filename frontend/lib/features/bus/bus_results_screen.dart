import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/misc.dart';

class BusSearchResultsScreen extends ConsumerStatefulWidget {
  const BusSearchResultsScreen({super.key});

  @override
  ConsumerState<BusSearchResultsScreen> createState() => _BusSearchResultsScreenState();
}

class _BusFilters {
  double maxPrice = 99999;
  List<String> busTypes = [];
  double minRating = 0;
  bool acOnly = false;
  bool sleeperOnly = false;

  List<BusScheduleModel> apply(List<BusScheduleModel> all) {
    return all.where((s) {
      if (s.baseFare > maxPrice) return false;
      if (acOnly && !s.bus.isAc) return false;
      if (sleeperOnly && !s.bus.isSleeper) return false;
      if (s.rating < minRating) return false;
      if (busTypes.isNotEmpty && !busTypes.contains(s.bus.busType)) return false;
      return true;
    }).toList();
  }
}

class _BusSearchResultsScreenState extends ConsumerState<BusSearchResultsScreen> {
  final _filters = _BusFilters();

  @override
  Widget build(BuildContext context) {
    final holder = ref.watch(searchResultProvider);
    final query = ref.watch(searchProvider);
    final all = holder.buses;
    final filtered = _filters.apply(all);
    final sorted = List<BusScheduleModel>.from(filtered)
      ..sort((a, b) => a.boardingTime.compareTo(b.boardingTime));

    return Scaffold(
      appBar: TripGoAppBar(
        title: 'Bus results',
        trailing: IconButton(
          onPressed: () => _showFilters(sorted.length),
          icon: const Icon(Icons.tune_rounded),
        ),
      ),
      body: sorted.isEmpty
          ? TripGoEmptyState(
              icon: Icons.directions_bus_outlined,
              title: 'No buses found',
              message: 'No buses run on this route for your selected date. Try another date.',
              action: SizedBox(width: 200, child: TripGoButton(label: 'Change search', onPressed: () => context.pop())),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${sorted.length} bus${sorted.length > 1 ? 'es' : ''} Â· ${query.source} â†’ ${query.destination}',
                          style: AppTypography.captionStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(formatShortDate(query.date), style: AppTypography.smallStyle),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => TripGoBusCard(
                      schedule: sorted[i],
                      onTap: () => context.push('/bus/${sorted[i].id}'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _showFilters(int count) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: AppSpacing.lg),
                Text('Filter buses', style: AppTypography.titleStyle),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView(
                    children: [
                      Text('Price', style: AppTypography.labelStyle),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 40,
                        child: Slider(
                          value: _filters.maxPrice.clamp(200, 4000).toDouble(),
                          min: 200,
                          max: 4000,
                          divisions: 19,
                          label: formatMoney(_filters.maxPrice),
                          onChanged: (v) => setSheetState(() => _filters.maxPrice = v),
                        ),
                      ),
                      Text('Up to ${formatMoney(_filters.maxPrice)}, $count matches',
                          style: AppTypography.captionStyle),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Bus type', style: AppTypography.labelStyle),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          FilterChip(
                            label: const Text('AC'),
                            selected: _filters.acOnly,
                            onSelected: (v) => setSheetState(() => _filters.acOnly = v),
                          ),
                          FilterChip(
                            label: const Text('Sleeper'),
                            selected: _filters.sleeperOnly,
                            onSelected: (v) => setSheetState(() => _filters.sleeperOnly = v),
                          ),
                          FilterChip(
                            label: const Text('AC Sleeper'),
                            selected: _filters.busTypes.contains('AC_SLEEPER'),
                            onSelected: (v) => setSheetState(() {
                              v ? _filters.busTypes.add('AC_SLEEPER') : _filters.busTypes.remove('AC_SLEEPER');
                            }),
                          ),
                          FilterChip(
                            label: const Text('AC Seater'),
                            selected: _filters.busTypes.contains('AC_SEATER'),
                            onSelected: (v) => setSheetState(() {
                              v ? _filters.busTypes.add('AC_SEATER') : _filters.busTypes.remove('AC_SEATER');
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Minimum rating', style: AppTypography.labelStyle),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          for (final r in [0.0, 3.5, 4.0, 4.5])
                            FilterChip(
                              label: Text(r == 0 ? 'Any' : '$r+'),
                              selected: _filters.minRating == r,
                              onSelected: (_) => setSheetState(() => _filters.minRating = r),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TripGoOutlinedButton(
                        label: 'Reset',
                        onPressed: () {
                          setSheetState(() {
                            _filters.maxPrice = 99999;
                            _filters.acOnly = false;
                            _filters.sleeperOnly = false;
                            _filters.busTypes.clear();
                            _filters.minRating = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: TripGoButton(
                        label: 'Apply filters',
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TrainSearchResultsScreen extends ConsumerStatefulWidget {
  const TrainSearchResultsScreen({super.key});

  @override
  ConsumerState<TrainSearchResultsScreen> createState() => _TrainSearchResultsScreenState();
}

class _TrainSearchResultsScreenState extends ConsumerState<TrainSearchResultsScreen> {
  final List<String> _classes = [];

  List<TrainScheduleModel> _apply(List<TrainScheduleModel> all) {
    if (_classes.isEmpty) return all;
    return all.where((t) => t.coaches.any((c) => _classes.contains(c.coachClass))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final holder = ref.watch(searchResultProvider);
    final query = ref.watch(searchProvider);
    final sorted = List<TrainScheduleModel>.from(_apply(holder.trains))
      ..sort((a, b) => a.train.number.compareTo(b.train.number));

    return Scaffold(
      appBar: TripGoAppBar(
        title: 'Train results',
        trailing: IconButton(
          onPressed: () => _showClassFilter(),
          icon: const Icon(Icons.tune_rounded),
        ),
      ),
      body: sorted.isEmpty
          ? TripGoEmptyState(
              icon: Icons.train_outlined,
              title: 'No trains found',
              message: 'No trains found on this route for your selected date.',
              action: SizedBox(width: 200, child: TripGoButton(label: 'Change search', onPressed: () => context.pop())),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                  child: Text(
                    '${sorted.length} train${sorted.length > 1 ? 's' : ''} Â· ${query.source} â†’ ${query.destination}',
                    style: AppTypography.captionStyle,
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => TripGoTrainCard(
                      schedule: sorted[i],
                      onTap: () => context.push('/train/${sorted[i].id}'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _showClassFilter() async {
    final classes = ['SL', '3A', '2A', '1A', 'CC', '2S'];
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter by class', style: AppTypography.titleStyle),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final c in classes)
                    FilterChip(
                      label: Text(c),
                      selected: _classes.contains(c),
                      onSelected: (v) => setSheetState(() {
                        v ? _classes.add(c) : _classes.remove(c);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: TripGoOutlinedButton(
                      label: 'Clear',
                      onPressed: () {
                        setSheetState(() => _classes.clear());
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: TripGoButton(
                      label: 'Apply',
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}