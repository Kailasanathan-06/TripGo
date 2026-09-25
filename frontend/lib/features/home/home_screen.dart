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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).valueOrNull;
    final user = auth?.user;
    final search = ref.watch(searchProvider);
    final offers = ref.watch(offersProvider);
    final now = DateTime.now();
    final greeting = _greeting(now.hour);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              toolbarHeight: 72,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.lightBlue,
                    child: Text(user?.initials ?? 'U', style: AppTypography.headingStyle.copyWith(color: AppColors.royalBlue)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$greeting,', style: AppTypography.captionStyle),
                      Text(user?.displayName ?? 'Traveller', style: AppTypography.headingStyle),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => context.go('/inbox'),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SearchWidget(query: search, onTap: () => context.push('/search')),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: TripGoButton(
                            label: 'Search Bus',
                            icon: Icons.directions_bus_filled,
                            onPressed: () => context.push('/search/results/bus'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TripGoButton(
                            label: 'Search Train',
                            icon: Icons.train_rounded,
                            onPressed: () => context.push('/search/results/train'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _SectionHeader(title: 'Popular routes')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  scrollDirection: Axis.horizontal,
                  itemCount: _popularRoutes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                  itemBuilder: (_, i) => _PopularRouteCard(route: _popularRoutes[i]),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _SectionHeader(title: 'Offers & deals')),
            SliverToBoxAdapter(
              child: offers.when(
                data: (offers) => SizedBox(
                  height: 170,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    scrollDirection: Axis.horizontal,
                    itemCount: offers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                    itemBuilder: (_, i) => _OfferPromoCard(offerTitle: offers[i].title, badge: offers[i].badgeText, code: offers[i].code),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                loading: () => const SizedBox(height: 170),
              ),
            ),
            const SliverToBoxAdapter(child: _SectionHeader(title: 'Quick actions')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickAction(icon: Icons.confirmation_number_rounded, label: 'Check PNR', onTap: () => context.push('/pnr')),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickAction(icon: Icons.local_offer_rounded, label: 'My Tickets', onTap: () => context.go('/bookings')),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickAction(icon: Icons.receipt_long_rounded, label: 'Offers', onTap: () => context.go('/offers')),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _SectionHeader(title: 'Notifications')),
            SliverToBoxAdapter(
              child: ref.watch(notificationsProvider).when(
                    data: (notes) => notes.isEmpty
                        ? const SizedBox.shrink()
                        : _NotificationTile(notification: notes.first, onTap: () => context.push('/inbox')),
                    error: (_, __) => const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                  ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _SearchWidget extends StatelessWidget {
  final SearchQuery query;
  final VoidCallback onTap;

  const _SearchWidget({required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TripGoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.white,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
                child: const Icon(Icons.search, color: AppColors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LocationRow(icon: Icons.trip_origin_rounded, color: AppColors.royalBlue, city: query.source, label: 'From'),
                    const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.sm),
                      child: SizedBox(height: 10, child: VerticalDivider(width: 0, color: AppColors.border)),
                    ),
                    _LocationRow(icon: Icons.location_on_rounded, color: AppColors.cyan, city: query.destination, label: 'To'),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
                child: const Icon(Icons.swap_vert_rounded, color: AppColors.royalBlue),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(color: AppColors.border),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text(formatShortDate(query.date), style: AppTypography.smallStyle),
              const SizedBox(width: AppSpacing.lg),
              const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text('${query.passengers} passenger${query.passengers > 1 ? 's' : ''}', style: AppTypography.smallStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String city;
  final String label;

  const _LocationRow({required this.icon, required this.color, required this.city, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.sm),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTypography.smallStyle),
          Text(city, style: AppTypography.bodyMedium),
        ]),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: Text(title, style: AppTypography.headingStyle),
    );
  }
}

final _popularRoutes = [
  ('Chennai', 'Bengaluru'),
  ('Chennai', 'Coimbatore'),
  ('Hyderabad', 'Mumbai'),
  ('Bengaluru', 'Pune'),
  ('Chennai', 'Madurai'),
  ('Mumbai', 'Delhi'),
  ('Coimbatore', 'Kochi'),
];

class _PopularRouteCard extends StatelessWidget {
  final (String, String) route;

  const _PopularRouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    return TripGoCard(
      onTap: () => context.push('/search/results/bus'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: AppColors.royalBlue, size: 26),
          const SizedBox(width: AppSpacing.md),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(route.$1, style: AppTypography.bodyMedium),
              const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.cyan),
              Text(route.$2, style: AppTypography.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferPromoCard extends StatelessWidget {
  final String offerTitle;
  final String badge;
  final String code;

  const _OfferPromoCard({required this.offerTitle, required this.badge, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.deepBlue, AppColors.royalBlue]),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.cyan, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text(badge, style: AppTypography.smallStyle.copyWith(color: AppColors.darkNavy, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          Text(offerTitle, style: AppTypography.headingStyle.copyWith(color: AppColors.white)),
          const SizedBox(height: 4),
          Text('Use code $code', style: AppTypography.captionStyle.copyWith(color: AppColors.lightBlue)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TripGoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(icon, color: AppColors.royalBlue, size: 26),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: AppTypography.captionStyle),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TripGoCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
              child: const Icon(Icons.notifications_rounded, color: AppColors.royalBlue, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: AppTypography.bodyMedium),
                  const SizedBox(height: 2),
                  Text(notification.message, style: AppTypography.captionStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}