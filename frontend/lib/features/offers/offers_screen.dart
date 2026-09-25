import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/feedback.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(offersProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: offers.when(
          data: (list) => list.isEmpty
              ? const TripGoEmptyState(icon: Icons.local_offer_outlined, title: 'No offers right now', message: 'New deals will appear here soon.')
              : CustomScrollView(
                  slivers: [
                    const SliverAppBar(
                      pinned: true,
                      title: Text('Offers & deals'),
                      toolbarHeight: 72,
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverList.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) => _OfferCard(offer: list[i]),
                      ),
                    ),
                  ],
                ),
          error: (e, __) => TripGoErrorState(message: '$e', onRetry: () => ref.invalidate(offersProvider)),
          loading: () => const TripGoLoading(message: 'Loading offersÃ¢â‚¬Â¦'),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final OfferModel offer;

  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TripGoCard(
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.cyan, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text(offer.badgeText, style: AppTypography.smallStyle.copyWith(color: AppColors.darkNavy, fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    Text(offer.code.toUpperCase(), style: AppTypography.smallStyle.copyWith(color: AppColors.white, letterSpacing: 1.2)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.title, style: AppTypography.headingStyle),
                    const SizedBox(height: 4),
                    Text(offer.description, style: AppTypography.captionStyle),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _infoChip(Icons.event_available_rounded, 'Min fare ${offer.minFare.toStringAsFixed(0)}'),
                        _infoChip(Icons.directions_car_filled, offer.transportTypes),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.royalBlue),
          const SizedBox(width: 4),
          Text(text, style: AppTypography.smallStyle.copyWith(color: AppColors.royalBlue)),
        ],
      ),
    );
  }
}