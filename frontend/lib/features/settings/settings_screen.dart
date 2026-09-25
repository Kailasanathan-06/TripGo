import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/misc.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _notifications = true;
  var _promotions = true;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(settingsProvider);

    return Scaffold(
      appBar: const TripGoAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TripGoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appearance', style: AppTypography.headingStyle),
                const SizedBox(height: AppSpacing.md),
                RadioGroup<AppThemeMode>(
                  groupValue: themeMode,
                  onChanged: (m) {
                    if (m != null) ref.read(settingsProvider.notifier).set(m);
                  },
                  child: Column(
                    children: [
                      for (final (mode, label, icon) in [
                        (AppThemeMode.light, 'Light', Icons.light_mode_outlined),
                        (AppThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
                        (AppThemeMode.system, 'System default', Icons.settings_suggest_outlined),
                      ])
                        RadioListTile<AppThemeMode>(
                          contentPadding: EdgeInsets.zero,
                          value: mode,
                          activeColor: AppColors.royalBlue,
                          secondary: Icon(icon, color: AppColors.royalBlue),
                          title: Text(label, style: AppTypography.bodyStyle),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TripGoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications', style: AppTypography.headingStyle),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Booking updates'),
                  subtitle: const Text('PNR confirmations and cancellations'),
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Offers & promotions'),
                  subtitle: const Text('Coupons and deals from partners'),
                  value: _promotions,
                  onChanged: (v) => setState(() => _promotions = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TripGoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About', style: AppTypography.headingStyle),
                const SizedBox(height: AppSpacing.md),
                _aboutRow('Version', '1.0.0'),
                _aboutRow('App', 'TRIPGO'),
                _aboutRow('Support', 'support@tripgo.app'),
                _aboutRow('Terms', 'tripgo.app/terms'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(child: Text('Made with care for easier journeys.', style: AppTypography.captionStyle)),
        ],
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyStyle),
          Text(value, style: AppTypography.smallStyle),
        ],
      ),
    );
  }
}