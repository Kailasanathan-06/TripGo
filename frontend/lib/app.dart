import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/providers.dart';

class TripGoApp extends ConsumerWidget {
  const TripGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(settingsProvider);
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.fromMode(themeMode, brightness),
      routerConfig: router,
    );
  }
}