import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/providers.dart';
import '../../shared/services/services.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/fields.dart';
import '../../shared/widgets/misc.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  var _busLoading = false;
  var _trainLoading = false;

  Future<void> _search(String transport) async {
    if (_busLoading || _trainLoading) return;
    final query = ref.read(searchProvider);
    if (query.source.isEmpty || query.destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select source and destination.')));
      return;
    }
    setState(() {
      if (transport == 'bus') {
        _busLoading = true;
      } else {
        _trainLoading = true;
      }
    });
    try {
      if (transport == 'bus') {
        final buses = await BusRepository().search(query);
        ref.read(searchResultProvider.notifier).set(SearchResultHolder(buses: buses, trains: ref.read(searchResultProvider).trains, transport: 'bus'));
        if (!mounted) return;
        context.pushReplacement('/search/results/bus');
      } else {
        final trains = await TrainRepository().search(query);
        ref.read(searchResultProvider.notifier).set(SearchResultHolder(trains: trains, buses: ref.read(searchResultProvider).buses, transport: 'train'));
        if (!mounted) return;
        context.pushReplacement('/search/results/train');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) {
        setState(() {
          _busLoading = false;
          _trainLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchProvider);
    return Scaffold(
      appBar: const TripGoAppBar(title: 'Search journey'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TripGoSelectField(
              label: 'From',
              value: query.source,
              icon: Icons.trip_origin_rounded,
              onTap: () => context.push('/search/location?mode=source'),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              child: IconButton(
                onPressed: () => ref.read(searchProvider.notifier).swap(),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lightBlue,
                  foregroundColor: AppColors.royalBlue,
                  padding: const EdgeInsets.all(10),
                ),
                icon: const Icon(Icons.swap_vert_rounded),
                tooltip: 'Swap source and destination',
              ),
            ),
            TripGoSelectField(
              label: 'To',
              value: query.destination,
              icon: Icons.location_on_rounded,
              onTap: () => context.push('/search/location?mode=destination'),
            ),
            const SizedBox(height: AppSpacing.md),
            TripGoSelectField(
              label: 'Travel date',
              value: DateFormat('EEE, dd MMM yyyy').format(query.date),
              icon: Icons.calendar_month_rounded,
              onTap: () => _pickDate(),
            ),
            const SizedBox(height: AppSpacing.md),
            TripGoCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Passengers', style: AppTypography.smallStyle),
                      Text('${query.passengers} passenger${query.passengers > 1 ? 's' : ''}', style: AppTypography.bodyMedium),
                    ],
                  ),
                  TripGoPassengerCounter(
                    value: query.passengers,
                    onChanged: (v) => ref.read(searchProvider.notifier).update(query.copyWith(passengers: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: TripGoButton(
                    label: 'Search Bus',
                    icon: Icons.directions_bus_filled,
                    loading: _busLoading,
                    onPressed: _busLoading ? null : () => _search('bus'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TripGoButton(
                    label: 'Search Train',
                    icon: Icons.train_rounded,
                    loading: _trainLoading,
                    onPressed: _trainLoading ? null : () => _search('train'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(searchProvider).date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) {
      ref.read(searchProvider.notifier).update(ref.read(searchProvider).copyWith(date: picked));
    }
  }
}