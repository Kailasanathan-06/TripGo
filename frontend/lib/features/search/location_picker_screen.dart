import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/providers.dart';
import '../../shared/services/services.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/misc.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  final String mode; // 'source' | 'destination'

  const LocationPickerScreen({super.key, required this.mode});

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  String _query = '';
  Timer? _debounce;
  List<_CityItem> _results = [];
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() {
      _query = q;
      _loading = true;
    });
    try {
      final cities = await CityRepository().searchCities(q);
      final results = <_CityItem>[];
      for (final c in cities) {
        results.add(_CityItem(c.name, c.state, c.isPopular));
      }
      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
    setState(() => _query = q);
  }

  void _select(String name) {
    final query = ref.read(searchProvider);
    final updated = widget.mode == 'source'
        ? query.copyWith(source: name, sourceCode: '')
        : query.copyWith(destination: name, destinationCode: '');
    ref.read(searchProvider.notifier).update(updated);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final popular = _results.where((r) => r.popular).take(4).toList();
    return Scaffold(
      appBar: TripGoAppBar(title: widget.mode == 'source' ? 'Select source' : 'Select destination'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TripGoSearchField(hint: 'Search city or station', onChanged: _onQueryChanged),
          ),
          Expanded(
            child: _query.trim().isEmpty
                ? _defaultView(popular)
                : _loading && _results.isEmpty
                    ? const TripGoLoading()
                    : _results.isEmpty
                        ? const TripGoEmptyState(icon: Icons.location_off_outlined, title: 'No cities found', message: 'Try a different search.')
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (_, i) => _resultTile(_results[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _defaultView(List<_CityItem> popular) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Popular cities', style: AppTypography.headingStyle),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final c in popular)
              ActionChip(
                label: Text(c.name),
                avatar: const Icon(Icons.location_city_rounded, size: 16, color: AppColors.royalBlue),
                onPressed: () => _select(c.name),
                backgroundColor: AppColors.lightBlue,
                side: BorderSide.none,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('All cities', style: AppTypography.headingStyle),
        const SizedBox(height: AppSpacing.sm),
        for (final c in _results) _resultTile(c),
      ],
    );
  }

  Widget _resultTile(_CityItem item) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
        child: const Icon(Icons.location_city_rounded, size: 20, color: AppColors.royalBlue),
      ),
      title: Text(item.name, style: AppTypography.bodyMedium),
      subtitle: item.state.isEmpty ? null : Text(item.state, style: AppTypography.captionStyle),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () => _select(item.name),
    );
  }
}

class _CityItem {
  final String name;
  final String state;
  final bool popular;

  const _CityItem(this.name, this.state, this.popular);
}