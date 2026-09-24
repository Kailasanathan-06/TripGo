import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/providers.dart';
import '../../shared/services/services.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/feedback.dart';

class PnrScreen extends ConsumerStatefulWidget {
  const PnrScreen({super.key});

  @override
  ConsumerState<PnrScreen> createState() => _PnrScreenState();
}

class _PnrScreenState extends ConsumerState<PnrScreen> {
  final _controller = TextEditingController();
  var _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final pnr = _controller.text.trim();
    if (pnr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a PNR number.')));
      return;
    }
    setState(() => _checking = true);
    try {
      final ticket = await TicketRepository().byPnr(pnr);
      if (!mounted) return;
      context.push('/ticket/${ticket.pnr}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(myTicketsProvider);
    return Scaffold(
      appBar: const TripGoAppBar(title: 'Check PNR status'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TripGoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PNR number', style: AppTypography.headingStyle),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'e.g. TG8F4K2M9X',
                    prefixIcon: Icon(Icons.confirmation_number_outlined, color: AppColors.textSecondary),
                  ),
                  style: AppTypography.bodyMedium.copyWith(letterSpacing: 1.5),
                ),
                const SizedBox(height: AppSpacing.md),
                TripGoButton(label: 'Check status', icon: Icons.search_rounded, loading: _checking, onPressed: _checking ? null : _check),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Your recent tickets', style: AppTypography.headingStyle),
          const SizedBox(height: AppSpacing.md),
          recent.when(
            data: (tickets) => tickets.isEmpty
                ? const TripGoEmptyState(icon: Icons.confirmation_number_outlined, title: 'No tickets yet', message: 'Book a journey to see tickets here.')
                : Column(
                    children: [
                      for (final t in tickets)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: TripGoCard(
                            onTap: () => context.push('/ticket/${t.pnr}'),
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Row(
                              children: [
                                const Icon(Icons.confirmation_number_rounded, color: AppColors.royalBlue),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.pnr, style: AppTypography.bodyMedium.copyWith(letterSpacing: 1.2)),
                                      Text('${t.payload['source'] ?? ''} → ${t.payload['destination'] ?? ''}', style: AppTypography.captionStyle),
                                    ],
                                  ),
                                ),
                                TripGoStatusChip.fromState(t.status),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
            error: (_, __) => const TripGoEmptyState(icon: Icons.cloud_off_rounded, title: 'Could not load', message: 'Check your connection and try again.'),
            loading: () => const TripGoLoading(),
          ),
        ],
      ),
    );
  }
}