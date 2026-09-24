import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.royalBlue, AppColors.cyan]), borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Icon(Icons.route_rounded, size: 22, color: AppColors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text('TRIPGO', style: AppTypography.headingStyle.copyWith(letterSpacing: 2)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(title, style: AppTypography.displayStyle.copyWith(fontSize: 24)),
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle, style: AppTypography.captionStyle),
              const SizedBox(height: AppSpacing.xxl),
              child,
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.xl),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}