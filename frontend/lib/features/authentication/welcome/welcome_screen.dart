import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/buttons.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  var _page = 0;
  late final PageController _controller;
  Timer? _timer;

  static const _benefits = [
    (icon: Icons.directions_bus_filled, title: 'Book Bus Tickets', subtitle: 'AC & Non-AC sleeper, seater and premium buses across India with live seat selection.'),
    (icon: Icons.train_rounded, title: 'Book Train Tickets', subtitle: 'Search trains, pick your coach and choose your berth — SL, 3A, 2A, 1A, CC and 2S.'),
    (icon: Icons.qr_code_2_rounded, title: 'Instant e-Tickets', subtitle: 'Pay instantly, get your PNR, e-ticket and scannable QR. Download your PDF ticket offline.'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_page + 1) % _benefits.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkNavy, AppColors.deepBlue],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.royalBlue, AppColors.cyan]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.route_rounded, size: 46, color: AppColors.white),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('TRIPGO', style: AppTypography.titleStyle.copyWith(color: AppColors.white, fontSize: 32, letterSpacing: 3, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              Text('Your Journey. One Smart Ticket.', style: AppTypography.captionStyle.copyWith(color: AppColors.lightBlue)),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: 210,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _benefits.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _BenefitCard(icon: _benefits[i].icon, title: _benefits[i].title, subtitle: _benefits[i].subtitle),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _benefits.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.cyan : AppColors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: TripGoButton(
                        label: 'Get Started',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => context.go('/register'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text('I already have an account · Login', style: AppTypography.bodyMedium.copyWith(color: AppColors.lightBlue)),
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
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.headingStyle, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: AppTypography.captionStyle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}